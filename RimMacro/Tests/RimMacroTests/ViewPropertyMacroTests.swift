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
            class RootView: UIView {
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
            
                let layout = VerticalLayout()
            }
            """,
            macros: testMacros
        )
    }
    
    func testOnlyVerticalLayoutWithOneModifier() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                    .spacing(16)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                    .spacing(16)
                }
            
                let layout = VerticalLayout()
            }
            """,
            macros: testMacros
        )
    }
    
    
    func testOnlyVerticalLayoutWithThreeModifier() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                    .spacing(16)
                    .alignment(.center)
                    .distribution(.equals)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        
                    }
                    .spacing(16)
                    .alignment(.center)
                    .distribution(.equals)
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
    
    func testMissingBluePrintProperty() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootViewController: UIViewController {
            }
            """,
            expandedSource:
            """
            class RootViewController: UIViewController {
            }
            """,
            diagnostics: [DiagnosticSpec(message: "@ViewProperty는 bluePrint 프로퍼티가 필요해요", line: 1, column: 1)],
            macros: testMacros
        )
    }
    
    func testVerticalLayoutHasChild() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title")
                        RimLabel("description")
                    }
                    .spacing(10)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title")
                        RimLabel("description")
                    }
                    .spacing(10)
                }

                let layout = VerticalLayout()

                let title = RimLabel()

                let description = RimLabel()
            }
            """,
            macros: testMacros
        )
    }
    
    
    func testFirstChildHasModifier() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title")
                            .constraint(width: 100, height: 100)
            
                        RimLabel("description")
                    }
                    .spacing(10)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title")
                            .constraint(width: 100, height: 100)
            
                        RimLabel("description")
                    }
                    .spacing(10)
                }

                let layout = VerticalLayout()

                let title = RimLabel()

                let description = RimLabel()
            }
            """,
            macros: testMacros
        )
    }
    
    
    func testTwoChildHasModifier() {
        assertMacroExpansion(
            """
            @ViewProperty
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title")
                            .constraint(width: 100, height: 100)
            
                        RimLabel("description")
                            .constraint(width: 200, height: 400)
                    }
                    .spacing(10)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title")
                            .constraint(width: 100, height: 100)
            
                        RimLabel("description")
                            .constraint(width: 200, height: 400)
                    }
                    .spacing(10)
                }

                let layout = VerticalLayout()

                let title = RimLabel()

                let description = RimLabel()
            }
            """,
            macros: testMacros
        )
    }
}
