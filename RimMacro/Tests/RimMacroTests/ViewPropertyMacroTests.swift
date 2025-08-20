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

final class ViewPropertyMacroTests: XCTestCase {
    func testStructNotSupported() {
        assertMacroExpansion(
            """
            @ViewProperty
            struct RootViewController: UIViewController {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            }
            """,
            expandedSource:
            """
            struct RootViewController: UIViewController {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            }
            """,
            diagnostics: [DiagnosticSpec(message: "class 타입에만 @ViewProperty를 사용할 수 있어요", line: 1, column: 1)],
            macros: testMacros
        )
    }
    
    func testOnlyVerticalLayout() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootViewController: UIViewController {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            }
            """,
            expandedSource:
            """
            class RootViewController: UIViewController {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            
                let layout = VerticalLayout()
            }
            """,
            macros: testMacros
        )
    }
    
    func testVerticalLayoutExpansionWithOneProperty() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootViewController: UIViewController {
                let value = 1
            
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            }
            """,
            expandedSource:
            """
            class RootViewController: UIViewController {
                let value = 1
            
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                }
            
                let layout = VerticalLayout()
            }
            """,
            macros: testMacros
        )
    }
}
