# po

po 결과에 대한 구조를 정리한 문서

## Overview

```swift
▼ ClassDeclSyntax ▼
@ViewProperty
class RootView: UIView {

    var bluePrint: UIView {
        ▼ CodeBlockItemListSyntax ▼
        ▼ CodeBlockItemSyntax ▼
        ▼ FunctionCallExprSyntax.MemberAccessExprSyntax.FunctionCallExprSyntax ▼
        VerticalLayout("layout") {
            ▼ CodeBlockItemListSyntax ▼
            ▼ CodeBlockItemSyntax ▼
            RimLabel("title")
                .constraint(width: 100, height: 100)
            ▲ CodeBlockItemSyntax ▲

            ▼ CodeBlockItemSyntax ▼
            RimLabel("description")
            ▲ CodeBlockItemSyntax ▲
            ▲ CodeBlockItemListSyntax ▲
        }
        ▲ FunctionCallExprSyntax.MemberAccessExprSyntax.FunctionCallExprSyntax ▲
        ▼ FunctionCallExprSyntax ▼
        .spacing(10)
        ▲ FunctionCallExprSyntax ▲
        ▲ CodeBlockItemSyntax ▲
        ▲ CodeBlockItemListSyntax ▲
    }
}
▲ ClassDeclSyntax ▲
```
