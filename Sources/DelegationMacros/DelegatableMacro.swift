import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DelegatableMacro: PeerMacro {
    private static func closureParameterTypeDescription(from type: TypeSyntax?) throws -> String {
        guard let type else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Delegatable 프로퍼티에는 클로저 타입을 명시해야 합니다.",
                    english: "@Delegatable properties must declare a closure type."
                )
            )
        }

        var description = type.trimmed.description.trimmingCharacters(in: .whitespacesAndNewlines)

        while let last = description.last, last == "?" || last == "!" {
            description.removeLast()
            description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard description.contains("->") else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Delegatable는 클로저 타입에만 사용할 수 있습니다.",
                    english: "Use @Delegatable only with closure types."
                )
            )
        }

        return description
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Delegatable는 변수에만 사용할 수 있습니다.",
                    english: "Apply @Delegatable to stored variables only."
                )
            )
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Delegatable는 var로 선언된 저장 프로퍼티에서만 사용할 수 있습니다.",
                    english: "@Delegatable works only on stored properties declared with var."
                )
            )
        }

        guard varDecl.bindings.count == 1,
              let binding = varDecl.bindings.first,
              let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Delegatable는 단일 식별자 패턴에만 사용할 수 있습니다.",
                    english: "@Delegatable requires a single identifier pattern."
                )
            )
        }

        let propertyName = identifierPattern.identifier.text

        guard !propertyName.isEmpty else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Delegatable가 적용된 프로퍼티 이름을 확인할 수 없습니다.",
                    english: "Cannot determine the property name annotated with @Delegatable."
                )
            )
        }

        let parameterTypeDescription = try closureParameterTypeDescription(from: binding.typeAnnotation?.type)
        let accessModifier = MacroSupport.enclosingAccessModifier(for: varDecl)
        let accessModifierText = accessModifier.map { "\($0.text) " } ?? ""

        let isReferenceType = MacroSupport.isReferenceTypeContext(for: varDecl)
        let functionDecl: DeclSyntax

        if isReferenceType {
            functionDecl = """
                @discardableResult
                \(raw: accessModifierText)func \(raw: propertyName)(_ perform: @escaping \(raw: parameterTypeDescription)) -> Self {
                    self.\(raw: propertyName) = perform
                    return self
                }
                """
        } else {
            functionDecl = """
                @discardableResult
                \(raw: accessModifierText)func \(raw: propertyName)(_ perform: @escaping \(raw: parameterTypeDescription)) -> Self {
                    var delegator = self
                    delegator.\(raw: propertyName) = perform
                    return delegator
                }
                """
        }

        return [functionDecl]
    }
}

@main
struct DelegationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DelegatableMacro.self,
        CallableMacro.self,
    ]
}
