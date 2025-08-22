//
//  RealizePropertyMacro.swift
//  RimMacro
//
//  Created by 노우영 on 8/19/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct BuildViewMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        do {
            guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
                let diagnostic = Diagnostic(node: declaration, message: ViewPropertyError.onlyAppliableToClass)
                context.diagnose(diagnostic)
                return []
            }
            
            let firstItem = try classDecl.findFirstFunctionCall()
            
            let parent = ViewDecl(propertyName: "self", typeName: "UIView")
            let viewHierarchy = try extractViewHierarchy(parent: parent, subviews: [firstItem.findRootFunctionCall()])
            let constraints = try extractConstraintPair(item: firstItem)
            
            let viewPropertyDecl = try expandViewProperties(from: firstItem)
            let addViewDecl = expandAddViewsFunction(hierarchy: viewHierarchy)
            let addSubviewsDecl = expandConstraint(hierarchy: viewHierarchy, constraints: constraints)
            
            var declSyntaxes = [DeclSyntax]()
            declSyntaxes.append(contentsOf: viewPropertyDecl)
            declSyntaxes.append(addViewDecl)
            declSyntaxes.append(addSubviewsDecl)
            return declSyntaxes
        } catch {
            
        }
        
        return []
    }
}

// MARK: ViewProperty
extension BuildViewMacro {
    private static func expandViewProperties(from firstCall: FunctionCallExprSyntax) throws -> [DeclSyntax] {
        let rootCall = firstCall.findRootFunctionCall()
        let typeName = try rootCall.findViewTypeName()
        let propertyName = try rootCall.findViewPropertyName()

        let decl: DeclSyntax = "let \(raw: propertyName) = \(raw: typeName)()"

        var members: [DeclSyntax] = [decl]
        for subview in rootCall.findSubviews() {
            let subMembers = try expandViewProperties(from: subview)
            members.append(contentsOf: subMembers)
        }
        return members
    }
}

// MARK: addSubview
extension BuildViewMacro {
    static func expandAddViewsFunction(hierarchy: [ViewHierarchyNode]) -> DeclSyntax {
        
        var result: [String] = []
        
        for graph in hierarchy {
            let parent = graph.parent
            
            let parentType = graph.parent.typeName.lowercased()
            let functionIdentifier = parentType.hasSuffix("layout") ? "addArrangedSubview" : "addSubview"
            
            for child in graph.children {
                result.append("\(parent.propertyName).\(functionIdentifier)(\(child.propertyName))")
            }
        }
        
        // 함수 본문에 들어갈 문자열(들여쓰기 적용)
        let body = result.map { "    " + $0 }.joined(separator: "\n")
        
        return DeclSyntax(
            """
            private func addSubviews() {
            \(raw: body)
            }
            """
        )
    }
}

// MARK: Constraint
extension BuildViewMacro {
    static func expandConstraint(hierarchy: [ViewHierarchyNode], constraints: [String: [ConstraintRelation]]) -> DeclSyntax {
        
        var parentByChild: [String: String] = [:]
        var bodyText: [String] = []
        
        for edge in hierarchy {
            let parentName = edge.parent.propertyName
            let childNames = edge.children.map(\.propertyName)

            for childName in childNames {
                parentByChild[childName] = parentName
            }
        }
        
        for (childName, links) in constraints {
            guard let parentName = parentByChild[childName] else { continue }
            var makeText: [String] = []
            
            for link in links {
                let makeLine = "make.\(link.fromAnchor).equalTo(\(parentName).snp.\(link.toAnchor))"
                makeText.append(makeLine)
            }
            
            let bodyLine =  """
                            \(childName).snp.addSubviewss { make in 
                                \(makeText.joined(separator: "\n"))
                            }
                            """
            
            bodyText.append(bodyLine)
        }
        
        return DeclSyntax(
            """
            private func activateConstraints() {
            \(raw: bodyText.joined(separator: "\n"))
            }
            """
        )
    }
}

extension BuildViewMacro {
    static func extractViewHierarchy(parent: ViewDecl, subviews: [FunctionCallExprSyntax]) throws -> [ViewHierarchyNode] {
        var hierarchy: [ViewHierarchyNode] = []
        
        var currentHierarchy = ViewHierarchyNode(parent: parent)
        
        var childHierarchy: [ViewHierarchyNode] = []
        
        for subview in subviews {
            let rootFunction = subview.findRootFunctionCall()
            let propertyName = try rootFunction.findViewPropertyName()
            let typeName = try rootFunction.findViewTypeName()
            let child = ViewDecl(propertyName: propertyName, typeName: typeName)
            
            if !currentHierarchy.children.contains(child) {
                currentHierarchy.children.append(child)
            }
            
            let childTree = try extractViewHierarchy(parent: child, subviews: rootFunction.findSubviews())
            childHierarchy.append(contentsOf: childTree)
        }
        
        hierarchy.append(currentHierarchy)
        hierarchy.append(contentsOf: childHierarchy)
        return hierarchy
    }
    
    static func extractConstraintRelations(from keyPathNames: [String]) -> [ConstraintRelation] {
        var relations: [ConstraintRelation] = []
        
        var index = 0
        
        while index + 1 < keyPathNames.count {
            let from = keyPathNames[index]
            let to = keyPathNames[index + 1]
            let relation = ConstraintRelation(fromAnchor: from, toAnchor: to)
            relations.append(relation)
            index += 2
        }
        
        return relations
    }
    
    static func extractConstraintPair(item: FunctionCallExprSyntax) throws -> [String: [ConstraintRelation]] {
        var constraints: [String: [ConstraintRelation]] = [:]
        
        if let call = item.findCallee(named: "constraint") {
            let root = call.findRootFunctionCall()
            let viewPropertyName = try BluePrintUtility.extractPropertyName(root)
            let keyPathNames = call.extractKeyPathNames()
            let relations = extractConstraintRelations(from: keyPathNames)
            constraints[viewPropertyName, default: []].append(contentsOf: relations)
        }
        
        if let codeBlockItemList = item.trailingClosure?.statements {
            for codeBlockItem in codeBlockItemList {
                guard let item = codeBlockItem.item.as(FunctionCallExprSyntax.self) else { continue }
                let pairs = try extractConstraintPair(item: item)
                for (key, value) in pairs {
                    constraints[key, default: []].append(contentsOf: value)
                }
                
            }
        }
        
        return constraints
    }
}

// MARK: Types
struct ConstraintRelation {
    let fromAnchor: String
    let toAnchor: String
}
