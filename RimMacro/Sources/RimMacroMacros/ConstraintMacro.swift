//
//  File.swift
//  RimMacro
//
//  Created by 노우영 on 8/20/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

enum ConstraintError: String, DiagnosticMessage {
    case unhanldedError
    
    var message: String { self.rawValue }
    
    var diagnosticID: SwiftDiagnostics.MessageID { .init(domain: "ConstraintError", id: self.rawValue) }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

public struct ConstraintMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        var result: [DeclSyntax] = []
        
        do {
            let codeBlock = try BluePrintUtility.findFirstCodeBlock(declaration: declaration)
            let hierarchy = try BluePrintUtility.extractViewHierarchy(parent: "self", current: codeBlock)
            let constraintFunction = makeConsraintFunction(hierarchy: hierarchy)
            result.append(DeclSyntax("\(raw: constraintFunction)"))
        } catch let err as BluePrintError {
            let diagnostic = Diagnostic(node: declaration, message: err)
            context.diagnose(diagnostic)
            return []
        } catch {
            let diagnostic = Diagnostic(node: declaration, message: ConstraintError.unhanldedError)
            context.diagnose(diagnostic)
            return []
        }
        
        return result
    }
    
    static func makeConsraintFunction(hierarchy: [ViewHierarchyNode]) -> String {
        
        var result: [String] = []
        
        for graph in hierarchy {
            let parent = graph.parent
            
            let functionIdentifier = graph.parent.hasSuffix("layout") ? "addArrangedSubview" : "addSubview"
            
            for child in graph.children {
                result.append("\(parent).\(functionIdentifier)(\(child))")
            }
        }
        
        // 함수 본문에 들어갈 문자열(들여쓰기 적용)
        let body = result.map { "    " + $0 }.joined(separator: "\n")
        
        return """
        private func makeConstraint() {
        \(body)
        }
        """
    }
}
