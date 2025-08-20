//
//  ConstraintMacroTests.swift
//  RimMacro
//
//  Created by 노우영 on 8/20/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest


final class ConstraintMacroTests: XCTestCase {
    
    struct VerticalLayout {
        
    }
    
    func test() {
        assertMacroExpansion(
            """
            @Constraint
            struct RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
