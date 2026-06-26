//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@UserPreference`. The generated property reads and writes through the enclosing
/// type's `store` (a `UserDefaultsProtocol`), and publishes changes via a generated per-preference
/// subject.
///
/// A `volatile` preference instead reads and writes through a generated in-memory store, so its
/// value is never persisted and resets on each launch.
public enum UserPreferenceMacro {
    enum DiagnosticError: Error, CustomStringConvertible {
        case notAStoredProperty
        case missingTypeAnnotation
        
        var description: String {
            switch self {
            case .notAStoredProperty:
                "@UserPreference can only be applied to a stored property."
            case .missingTypeAnnotation:
                "@UserPreference requires an explicit type annotation."
            }
        }
    }
    
    private struct Preference {
        let name: String
        let type: TypeSyntax
        let key: ExprSyntax
        let defaultValue: ExprSyntax?
        let isVolatile: Bool
        
        var subjectName: TokenSyntax {
            "_\(raw: name)Subject"
        }
        
        /// The in-memory backing for a volatile preference.
        var volatileValueName: TokenSyntax {
            "_\(raw: name)VolatileValue"
        }
        
        var resetMethodName: TokenSyntax {
            "reset\(raw: name.prefix(1).uppercased() + name.dropFirst())"
        }
    }
    
    private static func preference(for declaration: some DeclSyntaxProtocol, node: AttributeSyntax) throws -> Preference {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              let binding = variable.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw DiagnosticError.notAStoredProperty
        }
        guard let type = binding.typeAnnotation?.type.trimmed else {
            throw DiagnosticError.missingTypeAnnotation
        }
        
        var key: ExprSyntax?
        var defaultValue: ExprSyntax?
        var isVolatile = false
        
        if let list = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in list {
                switch argument.label?.text {
                case "key": key = argument.expression
                case "defaultValue": defaultValue = argument.expression
                case "volatile": isVolatile = argument.expression.as(BooleanLiteralExprSyntax.self)?.literal.text == "true"
                default: break
                }
            }
        }
        
        let name = identifier.text
        return Preference(name: name,
                          type: type,
                          key: key ?? "\(literal: name)",
                          defaultValue: defaultValue,
                          isVolatile: isVolatile)
    }
}

extension UserPreferenceMacro: AccessorMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingAccessorsOf declaration: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        let preference = try preference(for: declaration, node: node)
        
        if preference.isVolatile {
            return [
                """
                get {
                    \(preference.volatileValueName)
                }
                """,
                """
                set {
                    \(preference.volatileValueName) = newValue
                    \(preference.subjectName).send(newValue)
                }
                """
            ]
        }
        
        let key = preference.key
        
        return [
            """
            get {
                \(readExpression(for: preference))
            }
            """,
            """
            set {
                store[\(key)] = newValue
                \(preference.subjectName).send(newValue)
            }
            """
        ]
    }
    
    /// The getter expression: `store[key]`, with the default appended when there is one. A default
    /// that's a binary expression is parenthesised, as `??` binds tighter than e.g. `==`.
    private static func readExpression(for preference: Preference) -> ExprSyntax {
        guard let defaultValue = preference.defaultValue else {
            return "store[\(preference.key)]"
        }
        
        let isBinaryExpression = defaultValue.is(SequenceExprSyntax.self) || defaultValue.is(InfixOperatorExprSyntax.self)
        let wrappedDefault: ExprSyntax = isBinaryExpression ? "(\(defaultValue))" : defaultValue
        return "store[\(preference.key)] ?? \(wrappedDefault)"
    }
}

extension UserPreferenceMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingPeersOf declaration: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let preference = try preference(for: declaration, node: node)
        let type = preference.type
        let name = preference.name
        
        var peers: [DeclSyntax] = []
        
        if preference.isVolatile {
            peers.append("private var \(preference.volatileValueName): \(type) = \(preference.defaultValue ?? "nil")")
        }
        
        peers.append("private let \(preference.subjectName) = PassthroughSubject<\(type), Never>()")
        peers.append("""
        var \(raw: name)Publisher: AnyPublisher<\(type), Never> {
            \(preference.subjectName).prepend(\(raw: name)).eraseToAnyPublisher()
        }
        """)
        
        peers.append(resetMethod(for: preference))
        
        return peers
    }
    
    /// A method that clears the stored value so it reverts to the default.
    private static func resetMethod(for preference: Preference) -> DeclSyntax {
        if preference.isVolatile {
            """
            func \(preference.resetMethodName)() {
                \(preference.volatileValueName) = \(preference.defaultValue ?? "nil")
            }
            """
        } else {
            """
            func \(preference.resetMethodName)() {
                store.removeObject(forKey: \(preference.key))
            }
            """
        }
    }
}
