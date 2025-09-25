import Foundation
import SwiftSyntax

enum DelegationMacroError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

enum MacroSupport {
    static func localizedMessage(korean: String, english: String) -> String {
        prefersKorean() ? korean : english
    }

    static func enclosingAccessModifier(for declaration: some SyntaxProtocol) -> TokenSyntax? {
        accessModifier(from: enclosingDeclModifierList(for: declaration))
    }

    static func isReferenceTypeContext(for declaration: some SyntaxProtocol) -> Bool {
        var currentParent = Syntax(declaration).parent

        while let parent = currentParent {
            if parent.is(ClassDeclSyntax.self) || parent.is(ActorDeclSyntax.self) {
                return true
            }

            if parent.is(StructDeclSyntax.self) || parent.is(EnumDeclSyntax.self) {
                return false
            }

            currentParent = parent.parent
        }

        return false
    }

    static func isAccessModifier(_ modifier: DeclModifierSyntax) -> Bool {
        switch modifier.name.tokenKind {
        case .keyword(.public),
             .keyword(.open),
             .keyword(.package),
             .keyword(.internal),
             .keyword(.fileprivate),
             .keyword(.private):
            true
        default:
            false
        }
    }

    static func shouldCopyToBuilder(_ modifier: DeclModifierSyntax) -> Bool {
        if isAccessModifier(modifier) {
            return false
        }

        switch modifier.name.tokenKind {
        case .keyword(.mutating),
             .keyword(.nonmutating),
             .keyword(.consuming),
             .keyword(.borrowing):
            return false
        default:
            return true
        }
    }

    private static func prefersKorean() -> Bool {
        if let preferred = Locale.preferredLanguages.first?.lowercased(), preferred.hasPrefix("ko") {
            return true
        }

        if let lang = ProcessInfo.processInfo.environment["LANG"]?.lowercased(), lang.contains("ko") {
            return true
        }

        return false
    }

    private static func enclosingDeclModifierList(for declaration: some SyntaxProtocol) -> DeclModifierListSyntax? {
        var currentParent = Syntax(declaration).parent

        while let parent = currentParent {
            if let structDecl = parent.as(StructDeclSyntax.self) {
                return structDecl.modifiers
            }

            if let classDecl = parent.as(ClassDeclSyntax.self) {
                return classDecl.modifiers
            }

            if let enumDecl = parent.as(EnumDeclSyntax.self) {
                return enumDecl.modifiers
            }

            if let actorDecl = parent.as(ActorDeclSyntax.self) {
                return actorDecl.modifiers
            }

            if let extensionDecl = parent.as(ExtensionDeclSyntax.self) {
                return extensionDecl.modifiers
            }

            currentParent = parent.parent
        }

        return nil
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
}
