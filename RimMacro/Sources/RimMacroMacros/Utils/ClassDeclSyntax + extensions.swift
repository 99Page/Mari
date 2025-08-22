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
    /// `bluePrint`의 반환 구문 내에서 가장 마지막 체이닝된 함수 호출을 반환합니다.
    ///
    /// # Example
    ///
    /// ```swift
    /// VerticalLayout("layout")
    ///     .spacing(16)
    ///     .alignment(.center)
    ///     .distribution(.equal)
    /// ```
    ///
    /// 위 코드에서 `.distribution(.equal)`을 반환합니다.
    func findLastChainedFunctionCall() throws -> FunctionCallExprSyntax{
        let members = self.memberBlock.members
        
        let memberBlockItem = members.first {
            let variableDecl = $0.decl.as(VariableDeclSyntax.self)
            let pattern = variableDecl?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
            return pattern?.identifier.text == "bluePrint"
        }
        
        let variableDecl = memberBlockItem?.decl.as(VariableDeclSyntax.self)
        let accessors = variableDecl?.bindings.first?.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self)
        
        guard let item = accessors?.first?.item.as(FunctionCallExprSyntax.self) else {
            throw MacroError.castToFunctionCallExpr
        }
        
        return item
    }
}
