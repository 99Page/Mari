//
//  File.swift
//  RimMacro
//
//  Created by 노우영 on 9/11/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftBasicFormat

extension ClosureExprSyntax {
    var dedented: ClosureExprSyntax {
        let spacingCount = self.formatted().description.prefixCount(of: " ")
        var codeBlockItemList = CodeBlockItemListSyntax()
        
        for item in statements {
            var trimmed = item.description.replacingOccurrences(of: "\n", with: "")
            let dropCount = min(spacingCount, trimmed.prefix(while: { $0 == " " }).count)
            trimmed = String(trimmed.dropFirst(dropCount))
            
            let newItem = CodeBlockItemSyntax(stringLiteral: "\n\(trimmed)")
            
            codeBlockItemList.append(newItem)
        }
        
        return ClosureExprSyntax(signature: signature, statements: codeBlockItemList)
    }
}
