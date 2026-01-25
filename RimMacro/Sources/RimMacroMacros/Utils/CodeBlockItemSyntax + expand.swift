//
//  File.swift
//  RimMacro
//
//  Created by 노우영 on 9/1/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension CodeBlockItemSyntax {
    func expand() -> String {
        guard let item = self.item.as(SequenceExprSyntax.self) else { return "" }
        
        var current = ""
        
        for element in item.elements {
            if let memberAccessExpr = element.as(MemberAccessExprSyntax.self) {
                if let nameDecl = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self) {
                    current.append(nameDecl.baseName.text)
                }
                
                current.append(".") // MemberAccessExprSyntax.period
                
                let declName = memberAccessExpr.declName.baseName.text
                current.append("\(declName)")
            }
            
            if element.is(AssignmentExprSyntax.self) {
                current.append(" = ")
            }
            
            if let function = element.as(FunctionCallExprSyntax.self) {
                current.append(function.description)
            }
        }
        
        return current
    }
}
