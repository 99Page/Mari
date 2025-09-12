//
//  + ConstraintTests.swift
//  RimMacro
//
//  Created by 노우영 on 9/12/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension ViewPropertyMacroTests {
    func testDoubleConstraint() {
        assertMacroExpansion(
            """
            @View("view")
            class RootView: UIViewController {
                var bluePrint: UIView {
                    RimImage("image")
                        .constraint(leading: \\.leading, trailing: \\.trailing)
                        .constraint(height: 100)
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIViewController {
                var bluePrint: UIView {
                    RimImage("image")
                        .constraint(leading: \\.leading, trailing: \\.trailing)
                        .constraint(height: 100)
                }
            
                let image = RimImage()
            
                func addSubviews() {
                    view.addSubview(image)
                }
            
                func activateConstraints() {
                    image.snp.makeConstraints { make in
                        make.height.equalTo(100.0)
                        make.leading.equalTo(view.snp.leading)
                        make.trailing.equalTo(view.snp.trailing)
                    }
                }
            
                func bind() {
                    image.updateView()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testScrollViewWith2Depth() {
        assertMacroExpansion(
            """
            @View("view")
            class RootView: UIViewController {
                var bluePrint: UIView {
                    RimScrollView("scroll") {
                        VerticalLayout("layout") {
                            RimImageView("postImage") {
                                $0.image = $store.image
                            }
                            .constraint(leading: \\.leading, trailing: \\.trailing)
                            .constraint(height: 100)
                            
                            RimLabel("postTitle") {
                                $0.text = $store.titleText
                            }
                            
                            RimLabel("postDescription") {
                                $0.text = $store.descriptionText
                            }
                        }
                        .constraint(leading: \\.leading, trailing: \\.trailing, top: \\.top, bottom: \\.bottom)
                    }
                    .constraint(leading: \\.leading, trailing: \\.trailing, top: \\.top, bottom: \\.bottom)
                    .onScroll { offset, _ in
                        self.someFunction()
                    }
                    .onScrollEnd {
                        self.someFunction()
                    }
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIViewController {
                var bluePrint: UIView {
                    RimScrollView("scroll") {
                        VerticalLayout("layout") {
                            RimImageView("postImage") {
                                $0.image = $store.image
                            }
                            .constraint(leading: \\.leading, trailing: \\.trailing)
                            .constraint(height: 100)
                            
                            RimLabel("postTitle") {
                                $0.text = $store.titleText
                            }
                            
                            RimLabel("postDescription") {
                                $0.text = $store.descriptionText
                            }
                        }
                        .constraint(leading: \\.leading, trailing: \\.trailing, top: \\.top, bottom: \\.bottom)
                    }
                    .constraint(leading: \\.leading, trailing: \\.trailing, top: \\.top, bottom: \\.bottom)
                    .onScroll { offset, _ in
                        self.someFunction()
                    }
                    .onScrollEnd {
                        self.someFunction()
                    }
                }
            
                let scroll = RimScrollView()
            
                let layout = VerticalLayout()
            
                let postImage = RimImageView()
            
                let postTitle = RimLabel()
            
                let postDescription = RimLabel()
            
                func addSubviews() {
                    view.addSubview(scroll)
                    scroll.addSubview(layout)
                    layout.addArrangedSubview(postImage)
                    layout.addArrangedSubview(postTitle)
                    layout.addArrangedSubview(postDescription)
                }
            
                func activateConstraints() {
                    scroll.snp.makeConstraints { make in
                        make.leading.equalTo(view.snp.leading)
                        make.trailing.equalTo(view.snp.trailing)
                        make.top.equalTo(view.snp.top)
                        make.bottom.equalTo(view.snp.bottom)
                    }
            
                    layout.snp.makeConstraints { make in
                        make.leading.equalTo(scroll.snp.leading)
                        make.trailing.equalTo(scroll.snp.trailing)
                        make.top.equalTo(scroll.snp.top)
                        make.bottom.equalTo(scroll.snp.bottom)
                    }
            
                    postImage.snp.makeConstraints { make in
                        make.height.equalTo(100.0)
                        make.leading.equalTo(layout.snp.leading)
                        make.trailing.equalTo(layout.snp.trailing)
                    }
                }
            
                func bind() {
                    scroll.updateView()
                    layout.updateView()
                    postImage.image = $store.image
                    postImage.updateView()
                    postTitle.text = $store.titleText
                    postTitle.updateView()
                    postDescription.text = $store.descriptionText
                    postDescription.updateView()
                }
            
                func addEvents() {
                    scroll.onScrollEnd {
                        self.someFunction()
                    }
                    scroll.onScroll { offset, _ in
                        self.someFunction()
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
