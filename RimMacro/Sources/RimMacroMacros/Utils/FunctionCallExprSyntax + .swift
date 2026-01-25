//
//  File.swift
//  RimMacro
//
//  Created by 노우영 on 8/21/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftBasicFormat

extension FunctionCallExprSyntax {
    
    var callee: String? {
        if let calledExpression = calledExpression.as(DeclReferenceExprSyntax.self) {
            return calledExpression.baseName.text
        } else if let calledExpression = calledExpression.as(MemberAccessExprSyntax.self) {
            return calledExpression.declName.baseName.text
        }
        
        return nil
    }
    
    /// a.function1().function2() -> function2()
    var lastCall: FunctionCallExprSyntax? {
        guard let callee else { return nil }
        guard let dedentedTrailingClosure = try? trailingClosure?.dedent() else { return nil }
        
        return FunctionCallExprSyntax(
            callee: ExprSyntax(stringLiteral: callee),
            trailingClosure: dedentedTrailingClosure,
            additionalTrailingClosures: additionalTrailingClosures) {
            arguments
        }
    }
    
    /// a().b().c() -> a().b()
    var withoutLastCall: FunctionCallExprSyntax? {
        let calledExpression = calledExpression.as(MemberAccessExprSyntax.self)
        return calledExpression?.base?.as(FunctionCallExprSyntax.self)
    }
    
    func findViewPropertyName() throws -> String {
        let expr = arguments.first?.expression.as(StringLiteralExprSyntax.self)
        let propertySyntax = expr?.segments.first?.as(StringSegmentSyntax.self)
        let propertyName = propertySyntax?.content.text
        
        if let propertyName {
            return propertyName
        } else {
            throw MacroError.missingViewPropertyName
        }
    }
    
    func findSubviews() -> [FunctionCallExprSyntax] {
        let subviews = trailingClosure?.statements.compactMap {
            $0.item.as(FunctionCallExprSyntax.self)
        } ?? []
        
        return subviews
    }
    
    /// RimTableView<Cell>("") -> RimTableView
    func findViewTypeName() throws -> String {
        let rootFunction = findRootFunctionCall()
        
        if let typeDecl = rootFunction.calledExpression.as(DeclReferenceExprSyntax.self) {
            let typeName = typeDecl.baseName.text
            return typeName
        } else if let typeDecl = rootFunction.calledExpression.as(GenericSpecializationExprSyntax.self),
                  let typeName = typeDecl.expression.as(DeclReferenceExprSyntax.self) {
            return typeName.baseName.text
        } else {
            throw MacroError.missingViewTypeName
        }
    }
    
    /// ```swift
    /// RimLabel("description") {
    ///     ▼ CodeBlockItemListSyntax ▼
    ///     ▼ CodeBlockSyntax ▼
    ///     $0.text = .constant("설명")
    ///     ▲ CodeBlockSyntax ▲
    ///     ▼ CodeBlockSyntax ▼
    ///     $0.textColor = .constant(.black)
    ///     ▲ CodeBlockSyntax ▲
    ///     ▲ CodeBlockItemListSyntax ▲
    /// }
    /// ```
    func findViewSetup() -> [CodeBlockItemSyntax] {
        guard let statements = self.trailingClosure?.statements else { return [] }
        var result: [CodeBlockItemSyntax] = []
        
        for state in statements {
            result.append(state)
        }
        
        return result
    }
    
    /// VerticalLayout("layout") {
///        RimImageView("lockImage")
    ///
    ///    RimLabel("message") {
    ///        $0.text = .constant("test")
    ///    }
    /// } configure: {
    ///    ▼ 찾으려는 부분 ▼
    ///    $0.spacing = .constant(16)
    ///    $0.alignment = .constant(.center)
    ///    ▲ 찾으려는 부분 ▲
    ///}
    func findContainerSetup() -> [CodeBlockItemSyntax] {
        guard let statements = self.additionalTrailingClosures.first?.closure.statements else { return [] }
        
        var result: [CodeBlockItemSyntax] = []
        
        for state in statements {
            result.append(state)
        }
        
        return result
    }
    
    func findRootFunctionCall() -> FunctionCallExprSyntax {
        var item = self
        
        while let newItem = item.calledExpression.as(MemberAccessExprSyntax.self)?.base?.as(FunctionCallExprSyntax.self) {
            item = newItem
        }
        
        return item
    }
    
    func findCallee(named name: String) -> FunctionCallExprSyntax? {
        var current: FunctionCallExprSyntax? = self
        
        while let call = current {
            if call.isCallee(named: name) { return call }
            
            if let next = call.calledExpression.as(MemberAccessExprSyntax.self)?.base?.as(FunctionCallExprSyntax.self) {
                current = next
            } else {
                break
            }
        }
        
        return nil
    }
    
    func isCallee(named: String) -> Bool {
        callee == named
    }
    
    func extractKeyPathNames() -> [String] {
        var labels: [String] = []
        
        for argument in arguments {
            let expression = argument.expression.as(KeyPathExprSyntax.self)
            let component = expression?.components.first?.component.as(KeyPathPropertyComponentSyntax.self)
            let baseName = component?.declName.baseName.text
            
            if let baseName { labels.append(baseName) }
        }
        
        return labels
    }
    
    ///  VerticalLayout("layout") -> VerticalLayout()
    func extractEmptyInitializer() -> FunctionCallExprSyntax {
        let calledExpression = self.calledExpression
        let trim = calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExprSyntax = ExprSyntax(stringLiteral: trim)
        return FunctionCallExprSyntax(callee: trimmedExprSyntax)
    }
}
