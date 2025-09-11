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
            
                func addSubviews() {
                    self.addSubview(layout)
                }
            
                func activateConstraints() {

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
            
                func addSubviews() {
                    self.addSubview(layout)
                }
            
                func activateConstraints() {

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
            
                func addSubviews() {
                    self.addSubview(layout)
                }
            
                func activateConstraints() {

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
                }

                let layout = VerticalLayout()

                let title = RimLabel()

                let description = RimLabel()
            
                func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                func activateConstraints() {

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
                }

                let layout = VerticalLayout()

                let title = RimLabel()

                let description = RimLabel()
            
                func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                func activateConstraints() {
                    title.snp.makeConstraints { make in
                        make.width.equalTo(100.0)
                        make.height.equalTo(100.0)
                    }
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
                }

                let layout = VerticalLayout()

                let title = RimLabel()

                let description = RimLabel()
            
                func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                func activateConstraints() {
                    title.snp.makeConstraints { make in
                        make.width.equalTo(100.0)
                        make.height.equalTo(100.0)
                    }

                    description.snp.makeConstraints { make in
                        make.width.equalTo(200.0)
                        make.height.equalTo(400.0)
                    }
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
                            .constraint(width: 100, height: 100)
            
                        RimLabel("description")
                    }
                    .constraint(centerX: \\.centerX, centerY: \\.centerY)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImage("image")
                            .constraint(width: 100, height: 100)
            
                        RimLabel("description")
                    }
                    .constraint(centerX: \\.centerX, centerY: \\.centerY)
                }
            
                let layout = VerticalLayout()

                let image = RimImage()
            
                let description = RimLabel()
            
                func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(image)
                    layout.addArrangedSubview(description)
                }
            
                func activateConstraints() {
                    layout.snp.makeConstraints { make in
                        make.centerX.equalTo(self.snp.centerX)
                        make.centerY.equalTo(self.snp.centerY)
                    }
            
                    image.snp.makeConstraints { make in
                        make.width.equalTo(100.0)
                        make.height.equalTo(100.0)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testSetupProperties() {
        assertMacroExpansion(
            """
            @View
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title") {
                            $0.text = .constant("제목")
                        }   
            
                        RimLabel("description") {
                            $0.text = .constant("설명")
                            $0.textColor = .constant(.black)
                        }
                    }
                    .constraint(centerX: \\.centerX, centerY: \\.centerY)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimLabel("title") {
                            $0.text = .constant("제목")
                        }   
            
                        RimLabel("description") {
                            $0.text = .constant("설명")
                            $0.textColor = .constant(.black)
                        }
                    }
                    .constraint(centerX: \\.centerX, centerY: \\.centerY)
                }
            
                let layout = VerticalLayout()

                let title = RimLabel()
            
                let description = RimLabel()
            
                func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(title)
                    layout.addArrangedSubview(description)
                }
            
                func activateConstraints() {
                    layout.snp.makeConstraints { make in
                        make.centerX.equalTo(self.snp.centerX)
                        make.centerY.equalTo(self.snp.centerY)
                    }
                }
            
                func bind() {
                    title.text = .constant("제목")
                    title.updateView()
                    description.text = .constant("설명")
                    description.textColor = .constant(.black)
                    description.updateView()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testLayoutConfigure() {
        assertMacroExpansion(
            """
            @View
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImageView("lockImage")
                        
                        RimLabel("message") {
                            $0.text = .constant("test")
                        }
                    } configure: {
                        $0.spacing = .constant(16)
                        $0.alignment = .constant(.center)
                    }
                    .constraint(centerX: \\.centerX, centerY: \\.centerY)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIView {
                var bluePrint: UIView {
                    VerticalLayout("layout") {
                        RimImageView("lockImage")
                        
                        RimLabel("message") {
                            $0.text = .constant("test")
                        }
                    } configure: {
                        $0.spacing = .constant(16)
                        $0.alignment = .constant(.center)
                    }
                    .constraint(centerX: \\.centerX, centerY: \\.centerY)
                }
            
                let layout = VerticalLayout()

                let lockImage = RimImageView()

                let message = RimLabel()
            
                func addSubviews() {
                    self.addSubview(layout)
                    layout.addArrangedSubview(lockImage)
                    layout.addArrangedSubview(message)
                }
            
                func activateConstraints() {
                    layout.snp.makeConstraints { make in
                        make.centerX.equalTo(self.snp.centerX)
                        make.centerY.equalTo(self.snp.centerY)
                    }
                }
            
                func bind() {
                    layout.spacing = .constant(16)
                    layout.alignment = .constant(.center)
                    layout.updateView()
                    message.text = .constant("test")
                    message.updateView()
                }
            }
            """,
            macros: testMacros
        )
    }
}
