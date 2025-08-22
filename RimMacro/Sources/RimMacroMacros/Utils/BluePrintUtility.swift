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

struct BluePrintUtility {
    static func findBluePrint(declaration: some DeclGroupSyntax) throws -> MemberBlockItemSyntax {
        let members = declaration.memberBlock.members
        
        let memberBlockItem = members.first {
            let variableDecl = $0.decl.as(VariableDeclSyntax.self)
            let pattern = variableDecl?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
            return pattern?.identifier.text == "bluePrint"
        }
        
        guard let memberBlockItem else {
            throw MacroError.missingBluePrint
        }
        
        return memberBlockItem
    }
    
    static func findFirstCodeBlock(declaration: some DeclGroupSyntax) throws -> CodeBlockItemListSyntax {
        let members = declaration.memberBlock.members
        
        let memberBlockItem = members.first {
            let variableDecl = $0.decl.as(VariableDeclSyntax.self)
            let pattern = variableDecl?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
            return pattern?.identifier.text == "bluePrint"
        }
        
        let decl = memberBlockItem?.decl.as(VariableDeclSyntax.self)
        let codeBlockItemList = decl?.bindings.first?.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self)
        
        guard let codeBlockItemList else { throw MacroError.missingCodeBlockList }
        
        return codeBlockItemList
    }
    
    /// bluePrint로부터 뷰 트리를 추출합니다.
    /// - Parameters:
    ///   - parent: 현재 탐색 중인 부모 노드 이름
    ///   - current: 현재 코드 블록의 아이템 리스트
    /// - Returns: 삽입 순서가 보장된 HierarchyNode 배열 (부모 노드가 먼저, 하위 노드가 뒤따름)
    /// - Note: 하위 클로저가 존재하는 경우 재귀적으로 내려가며, 결과는 중복 없이 병합됩니다.
    static func extractViewHierarchy(parent: ViewDecl, current: CodeBlockItemListSyntax) throws -> [ViewHierarchyNode] {
        var hierarchy: [ViewHierarchyNode] = []
        
        var currentHierarchy = ViewHierarchyNode(parent: parent)
        var childHierarchy: [ViewHierarchyNode] = []
        
        for codeBlockItem in current {
            let rootFunctionCall = try findRootFunctionCall(codeBlockItem)
            let propertyName = try extractPropertyName(rootFunctionCall)
            let typeName = try extractTypeName(rootFunctionCall)
            let child = ViewDecl(propertyName: propertyName, typeName: typeName)
            
            if !currentHierarchy.children.contains(child) {
                currentHierarchy.children.append(child)
            }
            
            if let nextStatements = rootFunctionCall.trailingClosure?.statements {
                let childTree = try extractViewHierarchy(parent: child, current: nextStatements)
                childHierarchy.append(contentsOf: childTree)
            }
        }
        
        hierarchy.append(currentHierarchy)
        hierarchy.append(contentsOf: childHierarchy)
        return hierarchy
    }
    
    
    /// VerticalLayout("layout") { << item
    ///
    /// }
    ///
    /// VerticalLayout("layout") { << item.calledExpression.base
    ///
    /// }
    /// .spacing(10)
    ///
    /// VerticalLayout("layout") { << item.calledExpression.base.calledExpression.base.calledExpression.base
    ///
    /// }
    /// .spacing(10)
    /// .alignment(.center)
    /// .distribution(.equlas)
    static func findRootFunctionCall(_ codeBlockItem: CodeBlockItemSyntax) throws -> FunctionCallExprSyntax {
        var item = codeBlockItem.item.as(FunctionCallExprSyntax.self)
        
        while let newItem = item?.calledExpression.as(MemberAccessExprSyntax.self)?.base?.as(FunctionCallExprSyntax.self) {
            item = newItem
        }
        
        guard let item else { throw MacroError.failToExtractPropertyName }
        return item
    }
    
    /// 주어진 item에서 프로퍼티 네임을 추출합니다.
    ///
    /// ```swift
    /// var bluePrint: UIVIew {
    ///     ▼ FunctionCallExprSyntax ▼
    ///     VerticalLayout("layout") {
    ///         ...
    ///         ...
    ///     }
    ///     ▲ FunctionCallExprSyntax ▲
    ///     .spacing(16)
    /// }
    /// ```
    ///
    /// layout이 반환값입니다.
    static func extractPropertyName(_ item: FunctionCallExprSyntax) throws -> String {
        let expression = item.arguments.first?.expression.as(StringLiteralExprSyntax.self)
        let segment = expression?.segments.first?.as(StringSegmentSyntax.self)
        
        guard let segment else { throw MacroError.failToFindBluePrint }
        return segment.content.text
    }
    
    static func extractTypeName(_ item: FunctionCallExprSyntax) throws -> String {
        guard let typeName = item.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text else {
            throw MacroError.missingTypeName
        }
        
        return typeName
    }
}

struct ViewHierarchyNode {
    let parent: ViewDecl
    var children: [ViewDecl] = []
}

struct ViewDecl: Equatable, Hashable {
    let propertyName: String
    let typeName: String
}
