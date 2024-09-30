//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum WebRegistrationScreenViewModelAction: CustomStringConvertible {
    case cancel
    case signedIn(WebRegistrationCredentials)
    
    var description: String {
        switch self {
        case .cancel: "cancel"
        case .signedIn: "signedIn"
        }
    }
}

struct WebRegistrationScreenViewState: BindableState {
    var url: URL
    var bindings = WebRegistrationScreenViewStateBindings()
}

struct WebRegistrationScreenViewStateBindings { }

enum WebRegistrationScreenViewAction: CustomStringConvertible {
    case cancel
    case signedIn(WebRegistrationCredentials)
    
    var description: String {
        switch self {
        case .cancel: "cancel"
        case .signedIn: "signedIn"
        }
    }
}

struct WebRegistrationCredentials: Decodable {
    let userID: String
    let accessToken: String
    let deviceID: String
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case accessToken = "access_token"
        case deviceID = "device_id"
    }
}
