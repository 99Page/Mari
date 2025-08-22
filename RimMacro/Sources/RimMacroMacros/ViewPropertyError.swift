import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


enum ViewPropertyError: String, CustomStringConvertible, Error, DiagnosticMessage {
    case onlyAppliableToClass
    case missingBluePrintProperty
    case missingViewTypeName
    case missingViewPropertyName
    
    case failedToCastToVariableDeclSyntax
    case failedToCastToCodeBlockItemListSyntax
    case failedToCastToFunctionCallExprSyntax
    case failedToCastToDeclReferenceExprSyntax
    case failedToCastToStringLiteralExprSyntax
    case failedToCastToStringSegmentSyntax
    
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .onlyAppliableToClass:
            MessageID(domain: "type", id: self.rawValue)
        case .missingBluePrintProperty:
            MessageID(domain: "property", id: self.rawValue)
        case .failedToCastToVariableDeclSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToCodeBlockItemListSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToFunctionCallExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToDeclReferenceExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToStringLiteralExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .failedToCastToStringSegmentSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .missingViewTypeName:
            MessageID(domain: "macro", id: self.rawValue)
        case .missingViewPropertyName:
            MessageID(domain: "macro", id: self.rawValue)
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    
    var message: String { description }
    
    var description: String {
        switch self {
        case .onlyAppliableToClass:
            "class 타입에만 @ViewProperty를 사용할 수 있어요"
        case .missingBluePrintProperty:
            "@ViewProperty는 bluePrint 프로퍼티가 필요해요"
        case .failedToCastToVariableDeclSyntax:
            "VariableDecl 캐스팅이 실패했어요"
        case .failedToCastToCodeBlockItemListSyntax:
            "CodeBlockItemList 캐스팅이 실패했어요"
        case .failedToCastToFunctionCallExprSyntax:
            "FunctionCallExpr 캐스팅이 실패했어요"
        case .failedToCastToDeclReferenceExprSyntax:
            "DeclReferenceExpr 캐스팅이 실패했어요"
        case .failedToCastToStringLiteralExprSyntax:
            "StringLiteralExpr 캐스팅이 실패했어요"
        case .failedToCastToStringSegmentSyntax:
            "StringSegment 캐스팅이 실패했어요"
        case .missingViewTypeName:
            "View의 타입을 찾을 수 없어요"
        case .missingViewPropertyName:
            "View의 지정된 프로퍼티 이름을 찾을 수 없어요"
        }
    }
}

