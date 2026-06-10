//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Foundation

enum ProfileSetupScreenViewModelAction {
    case complete(username: String, displayName: String)
    case cancel
}

enum ProfileSetupUsernameStatus: Equatable {
    case idle
    case checking
    case available
    case taken
    case invalid(reason: String?)
}

struct ProfileSetupScreenViewState: BindableState {
    static let usernameMinLength = 3
    static let usernameMaxLength = 30
    static let displayNameMaxLength = 80

    var phoneNumber: String
    var isSubmitting = false
    var errorMessage: String?
    var usernameStatus: ProfileSetupUsernameStatus = .idle

    var bindings: ProfileSetupScreenViewStateBindings

    var canSubmit: Bool {
        guard !isSubmitting,
              Self.isValid(username: bindings.username),
              Self.isValidDisplayName(bindings.displayName) else { return false }
        switch usernameStatus {
        // Allow `.idle` so a transient/failed availability check doesn't strand the user; the
        // backend still rejects a taken username on `completeSignup` and bounces back here.
        case .available, .idle: return true
        case .checking, .taken, .invalid: return false
        }
    }

    static func isValid(username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= usernameMinLength, trimmed.count <= usernameMaxLength else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    static func isValidDisplayName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= displayNameMaxLength
    }
}

struct ProfileSetupScreenViewStateBindings {
    var username = ""
    var displayName = ""
}

enum ProfileSetupScreenViewAction {
    case usernameChanged
    case submitTapped
    case cancelTapped
}
