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

enum MacroError: String, Error, DiagnosticMessage {
    case onlyAppliableToClass
    case missingBluePrint
    case missingCodeBlockList
    case missingTypeName
    case missingFunctionCallExpr
    case failToFindBluePrint
    case failToExtractPropertyName
    case failToFindRootFunctionCall
    
    var message: String { self.rawValue }
    
    var diagnosticID: SwiftDiagnostics.MessageID { .init(domain: "BluePrintUtility", id: self.rawValue) }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}
