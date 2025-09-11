//
//  Test.swift
//  RimMacro
//
//  Created by 노우영 on 9/10/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest


extension ViewPropertyMacroTests {
    func testTableViewExpansion() {
        assertMacroExpansion(
            """
            @View
            class RootView: UIViewController {
                var bluePrint: UIView {
                    RimTableView<MyPostTableViewCell>("table") {
                        $0.items = self.$store.items
                    }
                    .constraint(leading: \\.leading, trailing: \\.trailing, top: \\.top, bottom: \\.bottom)
                    .didRowSelected { indexPath in
                        let post = self.store.posts[indexPath.row]
                        let postDetail = PostDetailFeature.State(postID: post.id)
                        self.traitCollection.push(state: AccountNavigationStack.Path.State.postDetail(postDetail))
                    }
                }
            }
            """,
            expandedSource:
            """
            class RootView: UIViewController {
                var bluePrint: UIView {
                    RimTableView<MyPostTableViewCell>("table") {
                        $0.items = self.$store.items
                    }
                    .constraint(leading: \\.leading, trailing: \\.trailing, top: \\.top, bottom: \\.bottom)
                    .didRowSelected { indexPath in
                        let post = self.store.posts[indexPath.row]
                        let postDetail = PostDetailFeature.State(postID: post.id)
                        self.traitCollection.push(state: AccountNavigationStack.Path.State.postDetail(postDetail))
                    }
                }
            
                let table = RimTableView<MyPostTableViewCell>()
            
                func addSubviews() {
                    self.addSubview(table)
                }
            
                func activateConstraints() {
                    table.snp.makeConstraints { make in
                        make.leading.equalTo(self.snp.leading)
                        make.trailing.equalTo(self.snp.trailing)
                        make.top.equalTo(self.snp.top)
                        make.bottom.equalTo(self.snp.bottom)
                    }
                }
            
                func bind() {
                    table.items = self.$store.items
                    table.updateView()
                }
            
                func addEvents() {
                    table.didRowSelected { indexPath in
                        let post = self.store.posts[indexPath.row]
                        let postDetail = PostDetailFeature.State(postID: post.id)
                        self.traitCollection.push(state: AccountNavigationStack.Path.State.postDetail(postDetail))
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
