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

enum ViewPropertyError: CustomStringConvertible, Error, DiagnosticMessage {
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .onlyAppliableToClass:
            MessageID(domain: "type", id: "onlyAppliableToClass")
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .onlyAppliableToClass:
                .error
        }
    }
    
    case onlyAppliableToClass
    
    var message: String { description }
    
    var description: String {
        switch self {
        case .onlyAppliableToClass:
            "class 타입에만 @ViewProperty를 사용할 수 있어요"
        }
    }
}

public struct ViewPropertyMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            let diagnostic = Diagnostic(node: declaration, message: ViewPropertyError.onlyAppliableToClass)
            context.diagnose(diagnostic)
            return []
        }
        
        let inhetiyedTypes = classDecl.inheritanceClause?.inheritedTypes.compactMap {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text
        }
        
        guard inhetiyedTypes?.contains("UIViewController") ?? false else { return [] }
        
        guard let bluePrint = findBluePrint(declaration: declaration) else {
            return []
        }
        
        return expansionBluePrint(bluePrint: bluePrint, context: context)
    }
    
    static func findBluePrint(declaration: some DeclGroupSyntax) -> MemberBlockItemSyntax? {
        let members = declaration.memberBlock.members
        
        return members.first {
            let variableDecl = $0.decl.as(VariableDeclSyntax.self)
            let pattern = variableDecl?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
            return pattern?.identifier.text == "bluePrint"
        }
    }
    
    static func expansionBluePrint(bluePrint: MemberBlockItemSyntax, context: some MacroExpansionContext) -> [DeclSyntax] {
        guard let body = bluePrint.decl.as(VariableDeclSyntax.self) else { return [] }
        guard let accessors = body.bindings.first?.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self) else { return [] }
        guard let item = accessors.first?.item.as(FunctionCallExprSyntax.self) else { return [] }
        
        guard let callType = item.calledExpression.as(DeclReferenceExprSyntax.self) else { return [] }
        let typeName = callType.baseName.text
        
        guard let expr = item.arguments.first?.expression.as(StringLiteralExprSyntax.self) else { return [] }
        guard let propertySyntax = expr.segments.first?.as(StringSegmentSyntax.self) else { return [] }
        let propertyName = propertySyntax.content.text
        
        return [DeclSyntax("let \(raw: propertyName) = \(raw: typeName)()")] + expansionList(item.trailingClosure?.statements)
    }
    
    static func expansionList(_ statements: CodeBlockItemListSyntax?) -> [DeclSyntax] {
        guard let statements else { return [] }
        
        var declSyntax: [DeclSyntax] = []
        
        for statement in statements {
            guard let item = statement.item.as(FunctionCallExprSyntax.self) else { return [] }
            guard let calledExpression = item.calledExpression.as(DeclReferenceExprSyntax.self) else { return [] }
            let typeName = calledExpression.baseName.text
            
            guard let expression = item.arguments.first?.expression.as(StringLiteralExprSyntax.self) else { return [] }
            guard let segment = expression.segments.first?.as(StringSegmentSyntax.self) else { return [] }
            let propertyName = segment.content.text
            
            declSyntax.append("let \(raw: propertyName) = \(raw: typeName)()")
            
            let childDecl = expansionList(item.trailingClosure?.statements)
            declSyntax.append(contentsOf: childDecl)
        }
        
        return declSyntax
    }
}
