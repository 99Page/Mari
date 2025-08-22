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

extension ClassDeclSyntax {
    func findFirstFunctionCall() throws -> FunctionCallExprSyntax{
        let members = self.memberBlock.members
        
        let memberBlockItem = members.first {
            let variableDecl = $0.decl.as(VariableDeclSyntax.self)
            let pattern = variableDecl?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
            return pattern?.identifier.text == "bluePrint"
        }
        
        let variableDecl = memberBlockItem?.decl.as(VariableDeclSyntax.self)
        let accessors = variableDecl?.bindings.first?.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self)
        
        guard let item = accessors?.first?.item.as(FunctionCallExprSyntax.self) else {
            throw MacroError.missingFunctionCallExpr
        }
        
        return item
    }
}
