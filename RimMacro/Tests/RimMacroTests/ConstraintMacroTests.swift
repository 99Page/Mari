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
    func test() {
        assertMacroExpansion(
            """
            @Constraint
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImage("image")
            
                        RimLabel("description")
                    }
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImage("image")
            
                        RimLabel("description")
                    }
                }
            
                private func makeConstraint() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(image)
                    layout.addArrangedSubview(description)
                }
            }
            """,
            macros: testMacros
        )
    }
}
