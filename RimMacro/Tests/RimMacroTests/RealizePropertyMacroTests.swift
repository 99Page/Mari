//
//  RealizePropertyMacroTests.swift
//  RimMacro
//
//  Created by 노우영 on 8/19/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class RealizePropertyMacroTests: XCTestCase {
    func testOnlyVerticalLayout() {
        assertMacroExpansion(
            """
            """,
            expandedSource:
            """
            """,
            macros: testMacros
        )
    }
}
