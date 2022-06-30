//
//  MockUserSessionStore.swift
//  ElementX
//
//  Created by Doug on 30/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

struct MockUserSessionStore: UserSessionStoreProtocol {
    var hasSessions: Bool { false }
    
    func restoreUserSession() async -> Result<UserSession, UserSessionStoreError> {
        return .failure(.failedRestoringLogin)
    }
    
    func userSession(for client: Client) async -> Result<UserSession, UserSessionStoreError> {
        return .failure(.failedSettingUpSession)
    }
    
    func logout(userSession: UserSessionProtocol) { }
    
    func baseDirectoryPath(for username: String) -> String {
        FileManager.default.temporaryDirectory.path
    }
    
    
}
