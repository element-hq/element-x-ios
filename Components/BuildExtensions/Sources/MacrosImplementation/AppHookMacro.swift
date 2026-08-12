//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@AppHook`. The generated property reads through a `Mutex`-backed store, and a
/// generated `register<Name>` method swaps in a replacement hook.
enum AppHookMacro {
    enum DiagnosticError: Error, CustomStringConvertible {
        case notAStoredProperty
        case missingTypeAnnotation
        case missingDefault
        
        var description: String {
            switch self {
            case .notAStoredProperty:
                "@AppHook can only be applied to a stored property."
            case .missingTypeAnnotation:
                "@AppHook requires an explicit type annotation."
            case .missingDefault:
                "@AppHook requires a default value."
            }
        }
    }
    
    private struct AppHook {
        let name: String
        let type: TypeSyntax
        let defaultValue: ExprSyntax
        
        var storageName: TokenSyntax {
            "_\(raw: name)"
        }
        
        var registerMethodName: TokenSyntax {
            "register\(raw: name.prefix(1).uppercased() + name.dropFirst())"
        }
    }
    
    private static func appHook(for declaration: some DeclSyntaxProtocol, node: AttributeSyntax) throws -> AppHook {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              let binding = variable.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw DiagnosticError.notAStoredProperty
        }
        guard let type = binding.typeAnnotation?.type.trimmed else {
            throw DiagnosticError.missingTypeAnnotation
        }
        
        var defaultValue: ExprSyntax?
        if let list = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in list where argument.label?.text == "default" {
                defaultValue = argument.expression
            }
        }
        guard let defaultValue else {
            throw DiagnosticError.missingDefault
        }
        
        return AppHook(name: identifier.text, type: type, defaultValue: defaultValue)
    }
}

extension AppHookMacro: AccessorMacro {
    static func expansion(of node: AttributeSyntax,
                          providingAccessorsOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        let appHook = try appHook(for: declaration, node: node)
        return [
            """
            get {
                \(appHook.storageName).withLock { $0 }
            }
            """
        ]
    }
}

extension AppHookMacro: PeerMacro {
    static func expansion(of node: AttributeSyntax,
                          providingPeersOf declaration: some DeclSyntaxProtocol,
                          in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let appHook = try appHook(for: declaration, node: node)
        return [
            "private let \(appHook.storageName) = Mutex<\(appHook.type)>(\(appHook.defaultValue))",
            """
            func \(appHook.registerMethodName)(_ hook: \(appHook.type)) {
                \(appHook.storageName).withLock { $0 = hook }
            }
            """
        ]
    }
}
