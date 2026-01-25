//
//  testMacros.swift
//  RimMacro
//
//  Created by 노우영 on 8/19/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
import RimMacroMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "View": BuildViewMacro.self
]

