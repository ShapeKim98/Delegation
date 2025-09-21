import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DelegatableMacroError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

public struct DelegatableMacro: PeerMacro {
    private static func prefersKorean() -> Bool {
        if let preferred = Locale.preferredLanguages.first?.lowercased(), preferred.hasPrefix("ko") {
            return true
        }

        if let lang = ProcessInfo.processInfo.environment["LANG"]?.lowercased(), lang.contains("ko") {
            return true
        }

        return false
    }

    private static func localizedMessage(korean: String, english: String) -> String {
        prefersKorean() ? korean : english
    }

    private static func accessModifier(from modifiers: DeclModifierListSyntax?) -> TokenSyntax? {
        guard let modifiers else { return nil }
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public),
                 .keyword(.open),
                 .keyword(.package),
                 .keyword(.internal),
                 .keyword(.fileprivate),
                 .keyword(.private):
                return modifier.name
            default:
                continue
            }
        }
        return nil
    }

    private static func enclosingAccessModifier(for declaration: some SyntaxProtocol) -> TokenSyntax? {
        var currentParent = Syntax(declaration).parent

        while let parent = currentParent {
            if let structDecl = parent.as(StructDeclSyntax.self),
               let modifier = accessModifier(from: structDecl.modifiers) {
                return modifier
            }

            if let classDecl = parent.as(ClassDeclSyntax.self),
               let modifier = accessModifier(from: classDecl.modifiers) {
                return modifier
            }

            if let enumDecl = parent.as(EnumDeclSyntax.self),
               let modifier = accessModifier(from: enumDecl.modifiers) {
                return modifier
            }

            if let actorDecl = parent.as(ActorDeclSyntax.self),
               let modifier = accessModifier(from: actorDecl.modifiers) {
                return modifier
            }

            if let extensionDecl = parent.as(ExtensionDeclSyntax.self),
               let modifier = accessModifier(from: extensionDecl.modifiers) {
                return modifier
            }

            currentParent = parent.parent
        }

        return nil
    }

    private static func closureParameterTypeDescription(from type: TypeSyntax?) throws -> String {
        guard let type else {
            throw DelegatableMacroError.message(
                localizedMessage(
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
            throw DelegatableMacroError.message(
                localizedMessage(
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
            throw DelegatableMacroError.message(
                localizedMessage(
                    korean: "@Delegatable는 변수에만 사용할 수 있습니다.",
                    english: "Apply @Delegatable to stored variables only."
                )
            )
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            throw DelegatableMacroError.message(
                localizedMessage(
                    korean: "@Delegatable는 var로 선언된 저장 프로퍼티에서만 사용할 수 있습니다.",
                    english: "@Delegatable works only on stored properties declared with var."
                )
            )
        }

        guard varDecl.bindings.count == 1,
              let binding = varDecl.bindings.first,
              let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw DelegatableMacroError.message(
                localizedMessage(
                    korean: "@Delegatable는 단일 식별자 패턴에만 사용할 수 있습니다.",
                    english: "@Delegatable requires a single identifier pattern."
                )
            )
        }

        let propertyName = identifierPattern.identifier.text

        guard !propertyName.isEmpty else {
            throw DelegatableMacroError.message(
                localizedMessage(
                    korean: "@Delegatable가 적용된 프로퍼티 이름을 확인할 수 없습니다.",
                    english: "Cannot determine the property name annotated with @Delegatable."
                )
            )
        }

        let parameterTypeDescription = try closureParameterTypeDescription(from: binding.typeAnnotation?.type)
        let accessModifier = enclosingAccessModifier(for: varDecl)
        let accessModifierText = accessModifier.map { "\($0.text) " } ?? ""

        let functionDecl: DeclSyntax = """
            \(raw: accessModifierText)func \(raw: propertyName)(_ perform: @escaping \(raw: parameterTypeDescription)) -> Self {
                var delegator = self
                delegator.\(raw: propertyName) = perform
                return delegator
            }
            """

        return [functionDecl]
    }
}

@main
struct DelegationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DelegatableMacro.self,
    ]
}
