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

enum ViewPropertyError: String, CustomStringConvertible, Error, DiagnosticMessage {
    case onlyAppliableToClass
    case missingBluePrintProperty
    
    case failedToCastToVariableDeclSyntax
    case failedToCastToCodeBlockItemListSyntax
    case failedToCastToFunctionCallExprSyntax
    case failedToCastToDeclReferenceExprSyntax
    case failedToCastToStringLiteralExprSyntax
    case failedToCastToStringSegmentSyntax
    
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .onlyAppliableToClass:
            MessageID(domain: "type", id: self.rawValue)
        case .missingBluePrintProperty:
            MessageID(domain: "property", id: self.rawValue)
        case .failedToCastToVariableDeclSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToCodeBlockItemListSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToFunctionCallExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToDeclReferenceExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToStringLiteralExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToStringSegmentSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .onlyAppliableToClass: .error
        case .missingBluePrintProperty: .error
        case .failedToCastToVariableDeclSyntax: .error
        case .failedToCastToCodeBlockItemListSyntax: .error
        case .failedToCastToFunctionCallExprSyntax: .error
        case .failedToCastToDeclReferenceExprSyntax: .error
        case .failedToCastToStringLiteralExprSyntax: .error
        case .failedToCastToStringSegmentSyntax: .error
        }
    }
    
    var message: String { description }
    
    var description: String {
        switch self {
        case .onlyAppliableToClass:
            "class 타입에만 @ViewProperty를 사용할 수 있어요"
        case .missingBluePrintProperty:
            "@ViewProperty는 bluePrint 프로퍼티가 필요해요"
        case .failedToCastToVariableDeclSyntax:
            "VariableDecl 캐스팅이 실패했어요"
        case .failedToCastToCodeBlockItemListSyntax:
            "CodeBlockItemList 캐스팅이 실패했어요"
        case .failedToCastToFunctionCallExprSyntax:
            "FunctionCallExpr 캐스팅이 실패했어요"
        case .failedToCastToDeclReferenceExprSyntax:
            "DeclReferenceExpr 캐스팅이 실패했어요"
        case .failedToCastToStringLiteralExprSyntax:
            "StringLiteralExpr 캐스팅이 실패했어요"
        case .failedToCastToStringSegmentSyntax:
            "StringSegment 캐스팅이 실패했어요"
        }
    }
}

public struct ViewPropertyMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let _ = declaration.as(ClassDeclSyntax.self) else {
            let diagnostic = Diagnostic(node: declaration, message: ViewPropertyError.onlyAppliableToClass)
            context.diagnose(diagnostic)
            return []
        }
        
        guard let bluePrint = findBluePrint(declaration: declaration) else {
            let diagnostic = Diagnostic(node: declaration, message: ViewPropertyError.missingBluePrintProperty)
            context.diagnose(diagnostic)
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
        guard let body = bluePrint.decl.as(VariableDeclSyntax.self) else {
            let diagnostic = Diagnostic(node: bluePrint, message: ViewPropertyError.failedToCastToVariableDeclSyntax)
            context.diagnose(diagnostic)
            return []
        }
        
        guard let accessors = body.bindings.first?.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self) else {
            let diagnostic = Diagnostic(node: body, message: ViewPropertyError.failedToCastToCodeBlockItemListSyntax)
            context.diagnose(diagnostic)
            return []
        }
        
        guard let item = findItem(accessors: accessors.first) else {
            let diagnostic = Diagnostic(node: accessors, message: ViewPropertyError.failedToCastToFunctionCallExprSyntax)
            context.diagnose(diagnostic)
            return []
        }
        
        guard let callType = item.calledExpression.as(DeclReferenceExprSyntax.self) else {
            let diagnostic = Diagnostic(node: item, message: ViewPropertyError.failedToCastToDeclReferenceExprSyntax)
            context.diagnose(diagnostic)
            return []
        }
        
        let typeName = callType.baseName.text
        
        guard let expr = item.arguments.first?.expression.as(StringLiteralExprSyntax.self) else {
            let diagnostic = Diagnostic(node: item, message: ViewPropertyError.failedToCastToStringLiteralExprSyntax)
            context.diagnose(diagnostic)
            return []
        }
        
        guard let propertySyntax = expr.segments.first?.as(StringSegmentSyntax.self) else {
            let diagnostic = Diagnostic(node: expr, message: ViewPropertyError.failedToCastToStringSegmentSyntax)
            context.diagnose(diagnostic)
            return []
        }
        
        let propertyName = propertySyntax.content.text
        
        return [DeclSyntax("let \(raw: propertyName) = \(raw: typeName)()")] + expansionList(item.trailingClosure?.statements)
    }
    
    static func findItem(accessors: CodeBlockItemSyntax?) -> FunctionCallExprSyntax? {
        guard let accessors else { return nil }

        guard let item = accessors.item.as(FunctionCallExprSyntax.self) else {
            return nil
        }
        
        
        return findRootFunctionCall(item)
    }
    
    static func findRootFunctionCall(_ item: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        
        /// VerticalLayout("layout") { << item
        ///
        /// }
        ///
        /// VerticalLayout("layout") { << item.calledExpression.base
        ///
        /// }
        /// .spacing(10)
        ///
        /// VerticalLayout("layout") { << item.calledExpression.base.calledExpression.base.calledExpression.base
        ///
        /// }
        /// .spacing(10)
        /// .alignment(.center)
        /// .distribution(.equlas)
        
        
        var item = item
        
        while let newItem = item.calledExpression.as(MemberAccessExprSyntax.self)?.base?.as(FunctionCallExprSyntax.self) {
            item = newItem
        }
        
        return item
    }
    
    static func expansionList(_ statements: CodeBlockItemListSyntax?) -> [DeclSyntax] {
        guard let statements else { return [] }
        
        var declSyntax: [DeclSyntax] = []
        
        for statement in statements {
            guard var item = statement.item.as(FunctionCallExprSyntax.self) else { return [] }
            item = findRootFunctionCall(item)
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
