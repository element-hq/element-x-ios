//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct JoinRequestProxy: JoinRequestProxyProtocol {
    private let joinRequest: JoinRequest
    
    init(joinRequest: JoinRequest) {
        self.joinRequest = joinRequest
    }
    
    var eventID: String {
        joinRequest.eventId
    }
    
    var userID: String {
        joinRequest.userId
    }
    
    var displayName: String? {
        joinRequest.displayName
    }
    
    var avatarURL: URL? {
        joinRequest.avatarUrl.flatMap(URL.init)
    }
    
    var reason: String? {
        joinRequest.reason
    }
    
    var formattedTimestamp: String? {
        guard let timestamp = joinRequest.timestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000)).formattedMinimal()
    }
    
    var isSeen: Bool {
        joinRequest.isSeen
    }
    
    func accept() async -> Result<Void, JoinRequestProxyError> {
        do {
            try await joinRequest.actions.accept()
            return .success(())
        } catch {
            MXLog.error("Failed accepting request with eventID: \(eventID) to join error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func decline() async -> Result<Void, JoinRequestProxyError> {
        do {
            // As of right now we don't provide reasons in the app for declining
            try await joinRequest.actions.decline(reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed declining request with eventID: \(eventID) to join error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func ban() async -> Result<Void, JoinRequestProxyError> {
        do {
            // As of right now we don't provide reasons in the app for declining and banning
            try await joinRequest.actions.declineAndBan(reason: nil)
            return .success(())
        } catch {
            MXLog.error("Failed declining and banning user for request with eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func markAsSeen() async -> Result<Void, JoinRequestProxyError> {
        do {
            try await joinRequest.actions.markAsSeen()
            return .success(())
        } catch {
            MXLog.error("Failed marking request with eventID: \(eventID) to join as seen error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
