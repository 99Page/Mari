//
//  RimMacroPlugin.swift
//  RimMacro
//
//  Created by 노우영 on 8/19/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct RimMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        ViewPropertyMacro.self
    ]
}
