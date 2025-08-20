// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "RimMacroMacros", type: "StringifyMacro")

// arbitrary: 추가할 member의 이름에 대한 제약을 없애줍니다.
@attached(member, names: arbitrary)
public macro ViewProperty() = #externalMacro(module: "RimMacroMacros", type: "ViewPropertyMacro")
