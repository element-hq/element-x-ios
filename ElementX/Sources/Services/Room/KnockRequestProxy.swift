//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct KnockRequestProxy: KnockRequestProxyProtocol {
    private let knockRequest: KnockRequest
    
    init(knockRequest: KnockRequest) {
        self.knockRequest = knockRequest
    }
    
    var eventID: String {
        knockRequest.eventId
    }
    
    var userID: String {
        knockRequest.userId
    }
    
    var displayName: String? {
        knockRequest.displayName
    }
    
    var avatarURL: URL? {
        knockRequest.avatarUrl.flatMap(URL.init)
    }
    
    var reason: String? {
        knockRequest.reason
    }
    
    var formattedTimestamp: String? {
        guard let timestamp = knockRequest.timestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000)).formattedMinimal()
    }
    
    var isSeen: Bool {
        knockRequest.isSeen
    }
    
    func accept() async -> Result<Void, KnockRequestProxyError> {
        do {
            try await knockRequest.actions.accept()
            return .success(())
        } catch {
            MXLog.error("Failed accepting request with eventID: \(eventID) to join error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func decline() async -> Result<Void, KnockRequestProxyError> {
        do {
            // As of right now we don't provide reasons in the app for declining
            try await knockRequest.actions.decline(reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed declining request with eventID: \(eventID) to join error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func ban() async -> Result<Void, KnockRequestProxyError> {
        do {
            // As of right now we don't provide reasons in the app for declining and banning
            try await knockRequest.actions.declineAndBan(reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed declining and banning user for request with eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func markAsSeen() async -> Result<Void, KnockRequestProxyError> {
        do {
            try await knockRequest.actions.markAsSeen()
            return .success(())
        } catch {
            MXLog.error("Failed marking request with eventID: \(eventID) to join as seen error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
