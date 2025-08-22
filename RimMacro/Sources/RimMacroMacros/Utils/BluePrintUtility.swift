//
//  File.swift
//  RimMacro
//
//  Created by 노우영 on 8/21/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct ViewHierarchyNode {
    let parent: ViewDecl
    var children: [ViewDecl] = []
}

struct ViewDecl: Equatable, Hashable {
    let propertyName: String
    let typeName: String
}
