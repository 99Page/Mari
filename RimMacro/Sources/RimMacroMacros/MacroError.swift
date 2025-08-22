import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


enum MacroError: String, CustomStringConvertible, Error, DiagnosticMessage {
    case onlyAppliableToClass
    
    case missingBluePrintProperty
    case missingViewTypeName
    case missingViewPropertyName
    
    case castToFunctionCallExpr
    case castToVariableDeclSyntax
    case castToCodeBlockItemListSyntax
    case castToFunctionCallExprSyntax
    case castToDeclReferenceExprSyntax
    case castToStringLiteralExprSyntax
    case castToStringSegmentSyntax
    
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .onlyAppliableToClass:
            MessageID(domain: "type", id: self.rawValue)
        case .missingBluePrintProperty:
            MessageID(domain: "property", id: self.rawValue)
        case .castToVariableDeclSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .castToCodeBlockItemListSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .castToFunctionCallExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .castToDeclReferenceExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .castToStringLiteralExprSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .castToStringSegmentSyntax:
            MessageID(domain: "cast", id: self.rawValue)
        case .missingViewTypeName:
            MessageID(domain: "macro", id: self.rawValue)
        case .missingViewPropertyName:
            MessageID(domain: "macro", id: self.rawValue)
        case .castToFunctionCallExpr:
            MessageID(domain: "macro", id: self.rawValue)
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    
    var message: String { description }
    
    var description: String {
        switch self {
        case .onlyAppliableToClass:
            "class 타입에만 @ViewProperty를 사용할 수 있어요"
        case .castToFunctionCallExpr:
            "FunctionCallExpr 캐스팅이 실패했어요"
        case .missingBluePrintProperty:
            "@ViewProperty는 bluePrint 프로퍼티가 필요해요"
        case .castToVariableDeclSyntax:
            "VariableDecl 캐스팅이 실패했어요"
        case .castToCodeBlockItemListSyntax:
            "CodeBlockItemList 캐스팅이 실패했어요"
        case .castToFunctionCallExprSyntax:
            "FunctionCallExpr 캐스팅이 실패했어요"
        case .castToDeclReferenceExprSyntax:
            "DeclReferenceExpr 캐스팅이 실패했어요"
        case .castToStringLiteralExprSyntax:
            "StringLiteralExpr 캐스팅이 실패했어요"
        case .castToStringSegmentSyntax:
            "StringSegment 캐스팅이 실패했어요"
        case .missingViewTypeName:
            "View의 타입을 찾을 수 없어요"
        case .missingViewPropertyName:
            "View의 지정된 프로퍼티 이름을 찾을 수 없어요"
        }
    }
}

