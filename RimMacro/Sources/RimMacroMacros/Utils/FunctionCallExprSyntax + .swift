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



extension FunctionCallExprSyntax {
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
    
    func findViewTypeName() throws -> String {
        let rootFunction = findRootFunctionCall()
        let typeDecl = rootFunction.calledExpression.as(DeclReferenceExprSyntax.self)
        let typeName = typeDecl?.baseName.text
        
        if let typeName {
            return typeName
        } else {
            throw MacroError.missingViewTypeName
        }
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
        calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text == named
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
}
