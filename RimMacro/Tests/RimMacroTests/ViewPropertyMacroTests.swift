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
            @View
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
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testOnlyVerticalLayoutWithOneModifier() {
        assertMacroExpansion(
            """
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    
    func testOnlyVerticalLayoutWithThreeModifier() {
        assertMacroExpansion(
            """
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testVerticalLayoutExpansionWithOneProperty() {
        assertMacroExpansion(
            """
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testVerticalLayoutHasChild() {
        assertMacroExpansion(
            """
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    
    func testFirstChildHasModifier() {
        assertMacroExpansion(
            """
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    
    func testTwoChildHasModifier() {
        assertMacroExpansion(
            """
            @View
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
            
                private func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                private func activateConstraints() {

                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testAddConstraint() {
        assertMacroExpansion(
            """
            @View
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImage("image")
                            .some(0)
            
                        RimLabel("description")
                    }
                    .constraint(\\.centerX, equalTo: \\.centerX, \\.centerY, equalTo: \\.centerY)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImage("image")
                            .some(0)
            
                        RimLabel("description")
                    }
                    .constraint(\\.centerX, equalTo: \\.centerX, \\.centerY, equalTo: \\.centerY)
                }
            
                let layout = VerticalLayout()

                let image = RimImage()
            
                let description = RimLabel()
            
                private func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(image)
                    layout.addArrangedSubview(description)
                }
            
                private func activateConstraints() {
                    layout.snp.addSubviewss { make in
                        make.centerX.equalTo(self.snp.centerX)
                        make.centerY.equalTo(self.snp.centerY)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
