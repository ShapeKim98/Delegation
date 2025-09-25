import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum ControllableMacroSupport {
    static func attributeBaseName(from attribute: AttributeSyntax) -> String {
        let description = attribute.attributeName.trimmedDescription
        if let lastComponent = description.split(separator: ".").last {
            return String(lastComponent)
        }
        return description
    }

    static func modifierDescription(_ modifier: DeclModifierSyntax) -> String {
        var text = modifier.name.text
        if let detail = modifier.detail {
            let detailText = detail.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if !detailText.isEmpty {
                text += " " + detailText
            }
        }
        return text
    }

    static func callPrefix(for signature: FunctionSignatureSyntax) -> String {
        guard let specifiers = signature.effectSpecifiers else { return "" }
        var components: [String] = []
        if specifiers.throwsSpecifier != nil {
            components.append("try")
        }
        if specifiers.asyncSpecifier != nil {
            components.append("await")
        }
        return components.isEmpty ? "" : components.joined(separator: " ") + " "
    }

    static func argumentList(from parameterClause: FunctionParameterClauseSyntax) -> String {
        parameterClause.parameters.map { parameter in
            let externalName = parameter.firstName.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let internalName = parameter.secondName?.text.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? parameter.firstName.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasInOutModifier = parameter.modifiers.contains { modifier in
                modifier.name.tokenKind == .keyword(.inout)
            }
            let argumentValuePrefix = hasInOutModifier ? "&" : ""
            let value = argumentValuePrefix + internalName

            if externalName == "_" {
                return value
            }

            return "\(externalName): \(value)"
        }.joined(separator: ", ")
    }

    static func requiresMutableCopy(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { modifier in
            switch modifier.name.tokenKind {
            case .keyword(.mutating),
                 .keyword(.consuming),
                 .keyword(.borrowing):
                true
            default:
                false
            }
        }
    }
}

public struct ControllableMacro: PeerMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Controllable는 함수 선언에만 사용할 수 있습니다.",
                    english: "Apply @Controllable to functions only."
                )
            )
        }

        guard functionDecl.body != nil else {
            throw DelegationMacroError.message(
                MacroSupport.localizedMessage(
                    korean: "@Controllable 메서드는 본문을 포함해야 합니다.",
                    english: "@Controllable functions must provide a body."
                )
            )
        }

        if let returnClause = functionDecl.signature.returnClause {
            let returnType = returnClause.type.trimmedDescription
            if returnType != "Void" && returnType != "()" {
                throw DelegationMacroError.message(
                    MacroSupport.localizedMessage(
                        korean: "@Controllable는 반환 타입이 없는 함수에서만 사용할 수 있습니다.",
                        english: "Use @Controllable only on functions without a return type."
                    )
                )
            }
        }

        let attributes = functionDecl.attributes
        var attributeLines: [String] = []
        var hasDiscardableResult = false

        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self) else {
                let text = element.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    attributeLines.append(text)
                }
                continue
            }

            let name = ControllableMacroSupport.attributeBaseName(from: attribute)
            if name.caseInsensitiveCompare("Controllable") == .orderedSame {
                continue
            }

            if name.caseInsensitiveCompare("discardableResult") == .orderedSame {
                hasDiscardableResult = true
            }

            let text = attribute.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                attributeLines.append(text)
            }
        }

        if !hasDiscardableResult {
            attributeLines.insert("@discardableResult", at: 0)
        }

        let attributesText = attributeLines.joined(separator: "\n")
        let accessText = MacroSupport.enclosingAccessModifier(for: functionDecl)?.text ?? ""

        var modifierComponents: [String] = []
        if !accessText.isEmpty {
            modifierComponents.append(accessText)
        }

        let modifiers = functionDecl.modifiers
        for modifier in modifiers where MacroSupport.shouldCopyToBuilder(modifier) {
            let text = ControllableMacroSupport.modifierDescription(modifier)
            if !text.isEmpty {
                modifierComponents.append(text)
            }
        }

        let modifiersText = modifierComponents.isEmpty ? "" : modifierComponents.joined(separator: " ") + " "
        let identifier = functionDecl.name.text
        let genericParameterClause = functionDecl.genericParameterClause?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parameterClause = functionDecl.signature.parameterClause.description.trimmingCharacters(in: .whitespacesAndNewlines)

        var effectSpecifiers = ""
        if let specifiers = functionDecl.signature.effectSpecifiers {
            let text = specifiers.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                effectSpecifiers = " " + text
            }
        }

        var whereClause = ""
        if let clause = functionDecl.genericWhereClause {
            let text = clause.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                whereClause = " " + text
            }
        }

        let callPrefix = ControllableMacroSupport.callPrefix(for: functionDecl.signature)
        let copyKeyword = ControllableMacroSupport.requiresMutableCopy(functionDecl.modifiers) ? "var" : "let"
        let arguments = ControllableMacroSupport.argumentList(from: functionDecl.signature.parameterClause)
        let invocation = arguments.isEmpty ? "controllable.\(identifier)()" : "controllable.\(identifier)(\(arguments))"
        let bodyLines = [
            "    \(copyKeyword) controllable = self",
            "    let _: Void = \(callPrefix)\(invocation)",
            "    return controllable"
        ]

        var lines: [String] = []
        if !attributesText.isEmpty {
            lines.append(attributesText)
        }

        lines.append("\(modifiersText)func \(identifier)\(genericParameterClause)\(parameterClause)\(effectSpecifiers) -> Self\(whereClause) {")
        lines.append(contentsOf: bodyLines)
        lines.append("}")

        let functionString = lines.joined(separator: "\n")

        return [DeclSyntax(stringLiteral: functionString)]
    }
}
