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

public struct RealizePropertyMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else { return [] }
        
        let inhetiyedTypes = classDecl.inheritanceClause?.inheritedTypes.compactMap {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text
        }
        
        guard inhetiyedTypes?.contains("UIViewController") ?? false else { return [] }
        
        
        return expansionViewProperties(declaration: declaration)
    }
    
    static func expansionViewProperties(declaration: some DeclGroupSyntax) -> [DeclSyntax] {
        let members = declaration.memberBlock.members
        guard let body = members.first?.decl.as(VariableDeclSyntax.self) else { return [] }
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
