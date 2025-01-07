//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

class StateBus {
    static let shared = StateBus()
    
    private init() { }
    
    /// UserState enum to track user auth state for zero
    enum UserState {
        case authorised
        case accessTokenExpired
        case unauthorised
        case unidentified
    }
    
    var userAuthState: UserState {
        do {
            return userAuthStateSubject.value
        } catch {
            MXLog.error("Failed to get user auth state value")
            return .unidentified
        }
    }
    
    private let userAuthStateSubject = CurrentValueSubject<UserState, Never>(.unidentified)
    var userAuthStatePublisher: CurrentValuePublisher<UserState, Never> {
        userAuthStateSubject.asCurrentValuePublisher()
    }
    
    func onUserAuthStateChanged(_ state: UserState) {
        userAuthStateSubject.send(state)
    }
}

extension StateBus.UserState {
    func isUserAuthorised() -> Bool {
        self == .authorised
    }
    
    func isUserUnAuthorised() -> Bool {
        self == .unauthorised
    }
    
    func hasZeroAccessTokenExpired() -> Bool {
        self == .accessTokenExpired
    }
}
