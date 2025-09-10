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
                let diagnostic = Diagnostic(node: declaration, message: MacroError.onlyAppliableToClass)
                context.diagnose(diagnostic)
                return []
            }

            let lastChainedFunctionCall = try classDecl.findLastChainedFunctionCall()
            
            let parent = ViewDecl(propertyName: "self", typeName: "UIView")
            let viewHierarchy = try extractViewHierarchy(superview: parent, subviews: [lastChainedFunctionCall.findRootFunctionCall()])
            let constraints = try extractConstraintPair(item: lastChainedFunctionCall)
            
            
            let viewPropertyDecl = try buildViewPropertyDecl(from: lastChainedFunctionCall)
            let addViewDecl = buildAddSubviewsDecl(hierarchy: viewHierarchy)
            let constraintDecl = buildConstraintDecl(hierarchy: viewHierarchy, constraints: constraints)
            
            let setupDecl = try buildSetupFunction(from: lastChainedFunctionCall)
            
            return viewPropertyDecl + [addViewDecl, constraintDecl, setupDecl]
        } catch {
            
        }
        
        return []
    }
}

// MARK: ViewProperty
extension BuildViewMacro {
    private static func buildViewPropertyDecl(from firstCall: FunctionCallExprSyntax) throws -> [DeclSyntax] {
        let rootCall = firstCall.findRootFunctionCall()
        let typeName = try rootCall.findViewTypeName()
        let propertyName = try rootCall.findViewPropertyName()

        let decl: DeclSyntax = "let \(raw: propertyName) = \(raw: typeName)()"

        var members: [DeclSyntax] = [decl]
        for subview in rootCall.findSubviews() {
            let subMembers = try buildViewPropertyDecl(from: subview)
            members.append(contentsOf: subMembers)
        }
        return members
    }
}

// MARK: addSubviews
extension BuildViewMacro {
    static func buildAddSubviewsDecl(hierarchy: [ViewHierarchyNode]) -> DeclSyntax {
        
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
            func addSubviews() {
            \(raw: body)
            }
            """
        )
    }
}

// MARK: activateConstraints
extension BuildViewMacro {
    static func buildConstraintDecl(hierarchy: [ViewHierarchyNode], constraints: [String: [ConstraintRelation]]) -> DeclSyntax {
        
        var parentByChild: [String: String] = [:]
        var bodyText: [String] = []
        
        for edge in hierarchy {
            let parentName = edge.parent.propertyName
            let childNames = edge.children.map(\.propertyName)

            for childName in childNames {
                parentByChild[childName] = parentName
            }
        }
        
        for hierarchyNode in hierarchy {
            for child in hierarchyNode.children {
                let childName = child.propertyName
                guard let parentName = parentByChild[childName] else { continue }
                guard let links = constraints[childName] else { continue }
                var makeText: [String] = []
                
                for link in links {
                    if let toConstraintItem = link.toConstraintItem {
                        let makeLine = "make.\(link.fromConstraint).equalTo(\(parentName).snp.\(toConstraintItem))"
                        makeText.append(makeLine)
                    }
                    
                    if let value = link.toValue {
                        let makeLine = "make.\(link.fromConstraint).equalTo(\(value))"
                        makeText.append(makeLine)
                    }
                }
                
                let bodyLine =  """
                                \(childName).snp.makeConstraints { make in 
                                    \(makeText.joined(separator: "\n"))
                                }
                                """
                
                bodyText.append("\(bodyLine)\n")
            }
        }
        
        if bodyText.last?.hasSuffix("\n") ?? false { // 마지막 \n 제거 
            let index = bodyText.count - 1
            bodyText[index].removeLast()
        }
        
        return DeclSyntax(
            """
            func activateConstraints() {
            \(raw: bodyText.joined(separator: "\n"))
            }
            """
        )
    }
}

extension BuildViewMacro {
    /// 외부에는 함수 하나(DeclSyntax)만 반환
       static func buildSetupFunction(from firstCall: FunctionCallExprSyntax) throws -> DeclSyntax {
           // 재귀적으로 '대입문 라인'만 모음
           let bodyLines = try collectSetupLines(from: firstCall)

           // 들여쓰기 적용 후 함수 선언로 감싸 반환
           let body = bodyLines.map { "    " + $0 }.joined(separator: "\n")
           
           if body.isEmpty {
               return DeclSyntax("")
           }

           return DeclSyntax(
               """
               func bind() {
               \(raw: body)
               }
               """
           )
       }

       /// 재귀 수집: 선언(Decl) 아님, '문장 라인(String)'만 모은다
       private static func collectSetupLines(from call: FunctionCallExprSyntax) throws -> [String] {
           let root = call.findRootFunctionCall()
           var lines: [String] = []
           
           let propertyName = try root.findViewPropertyName()

           // 컨테이너가 아니면 현재 노드의 설정 라인 수집
           if try isContainer(root) {
               for setup in root.findContainerSetup() {
                   let text = setup.description
                       .trimmingCharacters(in: .whitespacesAndNewlines)
                       .replacingOccurrences(of: "$0", with: propertyName)
                   lines.append(text)
               }
           } else {
               for setup in root.findViewSetup() {
                   let text = setup.description
                       .trimmingCharacters(in: .whitespacesAndNewlines)
                       .replacingOccurrences(of: "$0", with: propertyName)
                   lines.append(text)
               }
           }
           
           if !lines.isEmpty {
               lines.append("\(propertyName).updateView()")
           }

           // 자식 노드들도 재귀적으로 수집
           for sub in root.findSubviews() {
               let nested = try collectSetupLines(from: sub)
               lines.append(contentsOf: nested)
           }

           return lines
       }
}

extension BuildViewMacro {
    static func extractViewHierarchy(superview: ViewDecl, subviews: [FunctionCallExprSyntax]) throws -> [ViewHierarchyNode] {
        var hierarchy: [ViewHierarchyNode] = []
        
        var currentHierarchy = ViewHierarchyNode(parent: superview)
        
        var childHierarchy: [ViewHierarchyNode] = []
        
        for subview in subviews {
            let rootFunction = subview.findRootFunctionCall()
            let propertyName = try rootFunction.findViewPropertyName()
            let typeName = try rootFunction.findViewTypeName()
            let child = ViewDecl(propertyName: propertyName, typeName: typeName)
            
            if !currentHierarchy.children.contains(child) {
                currentHierarchy.children.append(child)
            }
            
            let childTree = try extractViewHierarchy(superview: child, subviews: rootFunction.findSubviews())
            childHierarchy.append(contentsOf: childTree)
        }
        
        hierarchy.append(currentHierarchy)
        hierarchy.append(contentsOf: childHierarchy)
        return hierarchy
    }
    
    static func extractConstaints(from arguments: [LabeledExprSyntax]) -> [ConstraintRelation] {
        var relations: [ConstraintRelation] = []
        
        for argument in arguments {
            guard let from = argument.label?.text else { continue }
            
            if let expression = argument.expression.as(IntegerLiteralExprSyntax.self) {
                let value = expression.literal.text
                let relation = ConstraintRelation(fromConstraint: from, toConstraintItem: nil, toValue: Double(value))
                relations.append(relation)
            }
            
            if let expression = argument.expression.as(KeyPathExprSyntax.self),
               let component = expression.components.first?.component.as(KeyPathPropertyComponentSyntax.self) {
                let constraintItem = component.declName.baseName.text
                let relation = ConstraintRelation(fromConstraint: from, toConstraintItem: constraintItem, toValue: nil)
                relations.append(relation)
            }
        }
        
        return relations
    }
    
    static func extractConstraintPair(item: FunctionCallExprSyntax) throws -> [String: [ConstraintRelation]] {
        var constraints: [String: [ConstraintRelation]] = [:]
        
        if let call = item.findCallee(named: "constraint") {
            let root = call.findRootFunctionCall()
            let viewPropertyName = try root.findViewPropertyName()
            let relations = extractConstaints(from: [LabeledExprSyntax](call.arguments))
            constraints[viewPropertyName, default: []].append(contentsOf: relations)
        }
        
        if let codeBlockItemList = item.findRootFunctionCall().trailingClosure?.statements {
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
    
    static func isContainer(_ item: FunctionCallExprSyntax) throws -> Bool {
        let typeName = try item.findViewTypeName().lowercased()
        return typeName.hasSuffix("layout") || typeName.hasSuffix("container")
    }
}

// MARK: Types
struct ConstraintRelation {
    let fromConstraint: String
    
    let toConstraintItem: String?
    let toValue: Double?
}
