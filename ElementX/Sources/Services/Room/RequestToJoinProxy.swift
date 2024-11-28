//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RequestToJoinProxyError: Error {
    case sdkError(Error)
}

// sourcery: AutoMockable
protocol RequestToJoinProxyProtocol {
    var eventID: String { get }
    var userID: String { get }
    var displayName: String? { get }
    var avatarURL: URL? { get }
    var reason: String? { get }
    var formattedTimestamp: String? { get }
    var isSeen: Bool { get }
    
    func accept() async -> Result<Void, RequestToJoinProxyError>
    func decline(reason: String?) async -> Result<Void, RequestToJoinProxyError>
    func ban(reason: String?) async -> Result<Void, RequestToJoinProxyError>
    func markAsSeen() async -> Result<Void, RequestToJoinProxyError>
}

struct RequestToJoinProxy: RequestToJoinProxyProtocol {
    private let requestToJoin: RequestToJoin
    
    var eventID: String {
        requestToJoin.eventId
    }
    
    var userID: String {
        requestToJoin.userId
    }
    
    var displayName: String? {
        requestToJoin.displayName
    }
    
    var avatarURL: URL? {
        requestToJoin.avatarUrl.flatMap(URL.init)
    }
    
    var reason: String? {
        requestToJoin.reason
    }
    
    var formattedTimestamp: String? {
        guard let timestamp = requestToJoin.timestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000)).formattedMinimal()
    }
    
    var isSeen: Bool {
        requestToJoin.isSeen
    }
    
    func accept() async -> Result<Void, RequestToJoinProxyError> {
        do {
            try await requestToJoin.actions.accept()
            return .success(())
        } catch {
            MXLog.error("Failed accepting request with eventID: \(eventID) to join error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func decline(reason: String?) async -> Result<Void, RequestToJoinProxyError> {
        do {
            try await requestToJoin.actions.decline(reason: reason)
            return .success(())
        } catch {
            MXLog.error("Failed declining request with eventID: \(eventID) to join error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func ban(reason: String?) async -> Result<Void, RequestToJoinProxyError> {
        do {
            try await requestToJoin.actions.declineAndBan(reason: reason)
            return .success(())
        } catch {
            MXLog.error("Failed declining and banning user for request with eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func markAsSeen() async -> Result<Void, RequestToJoinProxyError> {
        do {
            try await requestToJoin.actions.markAsSeen()
            return .success(())
        } catch {
            MXLog.error("Failed marking request with eventID: \(eventID) to join as seen error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
