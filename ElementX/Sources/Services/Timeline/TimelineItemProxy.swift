//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A light wrapper around timeline items returned from Rust.
enum TimelineItemProxy {
    case event(EventTimelineItemProxy)
    case virtual(MatrixRustSDK.VirtualTimelineItem, uniqueID: TimelineUniqueId)
    case unknown(MatrixRustSDK.TimelineItem)
    
    init(item: MatrixRustSDK.TimelineItem) {
        if let eventItem = item.asEvent() {
            let eventSenderId = eventItem.sender
            self = .event(EventTimelineItemProxy(item: eventItem, uniqueID: item.uniqueId()))
        } else if let virtualItem = item.asVirtual() {
            self = .virtual(virtualItem, uniqueID: item.uniqueId())
        } else {
            self = .unknown(item)
        }
    }
    
    var isEvent: Bool {
        switch self {
        case .event:
            return true
        default:
            return false
        }
    }
}

/// The delivery status for the item.
enum TimelineItemDeliveryStatus: Hashable {
    case sending
    case sent
    case sendingFailed(TimelineItemSendFailure)
    
    var isSendingFailed: Bool {
        switch self {
        case .sending, .sent: false
        case .sendingFailed: true
        }
    }
}

/// The reason a timeline item failed to send.
enum TimelineItemSendFailure: Hashable {
    enum VerifiedUser: Hashable {
        case hasUnsignedDevice(devices: [String: [String]])
        case changedIdentity(users: [String])
        
        var affectedUserIDs: [String] {
            switch self {
            case .hasUnsignedDevice(let devices): Array(devices.keys)
            case .changedIdentity(let users): users
            }
        }
    }
    
    case verifiedUser(VerifiedUser)
    case unknown
}

/// A light wrapper around event timeline items returned from Rust.
class EventTimelineItemProxy {
    let item: MatrixRustSDK.EventTimelineItem
    let id: TimelineItemIdentifier
    
    init(item: MatrixRustSDK.EventTimelineItem, uniqueID: TimelineUniqueId) {
        self.item = item
        id = .event(uniqueID: uniqueID, eventOrTransactionID: item.eventOrTransactionId)
    }
    
    lazy var deliveryStatus: TimelineItemDeliveryStatus? = {
        guard let localSendState = item.localSendState else {
            return nil
        }
        
        switch localSendState {
        case .sendingFailed(_, let isRecoverable):
            return isRecoverable ? .sending : .sendingFailed(.unknown)
        case .notSentYet:
            return .sending
        case .sent:
            return .sent
        case .verifiedUserHasUnsignedDevice(devices: let devices):
            return .sendingFailed(.verifiedUser(.hasUnsignedDevice(devices: devices)))
        case .verifiedUserChangedIdentity(users: let users):
            return .sendingFailed(.verifiedUser(.changedIdentity(users: users)))
        case .crossSigningNotSetup, .sendingFromUnverifiedDevice:
            return .sendingFailed(.unknown)
        }
    }()
    
    lazy var canBeRepliedTo = item.canBeRepliedTo
            
    lazy var content = item.content

    lazy var isOwn = item.isOwn

    lazy var isEditable = item.isEditable
    
    lazy var sender: TimelineItemSender = {
        let profile = item.senderProfile
        
        switch profile {
        case let .ready(displayName, isDisplayNameAmbiguous, avatarUrl):
            return .init(id: item.sender,
                         displayName: displayName,
                         isDisplayNameAmbiguous: isDisplayNameAmbiguous,
                         avatarURL: avatarUrl.flatMap(URL.init(string:)))
        default:
            return .init(id: item.sender,
                         displayName: nil,
                         isDisplayNameAmbiguous: false,
                         avatarURL: nil)
        }
    }()

    lazy var reactions = item.reactions
    
    lazy var timestamp = Date(timeIntervalSince1970: TimeInterval(item.timestamp / 1000))
    
    lazy var debugInfo: TimelineItemDebugInfo = {
        let debugInfo = item.lazyProvider.debugInfo()
        return TimelineItemDebugInfo(model: debugInfo.model, originalJSON: debugInfo.originalJson, latestEditJSON: debugInfo.latestEditJson)
    }()
    
    lazy var shieldState = item.lazyProvider.getShields(strict: false)
    
    lazy var readReceipts = item.readReceipts
}

struct TimelineItemDebugInfo: Identifiable, CustomStringConvertible {
    let id = UUID()
    let model: String
    let originalJSON: String?
    let latestEditJSON: String?
    
    init(model: String, originalJSON: String?, latestEditJSON: String?) {
        self.model = model
        
        self.originalJSON = Self.prettyJsonFormattedString(from: originalJSON)
        self.latestEditJSON = Self.prettyJsonFormattedString(from: latestEditJSON)
    }
    
    var description: String {
        var description = model
        
        if let originalJSON {
            description += "\n\n\(originalJSON)"
        }
        
        if let latestEditJSON {
            description += "\n\n\(latestEditJSON)"
        }
        
        return description
    }
    
    // MARK: - Private
    
    private static func prettyJsonFormattedString(from string: String?) -> String? {
        guard let string,
              let data = string.data(using: .utf8),
              let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: [.prettyPrinted]) else {
            return nil
        }
        
        return String(data: jsonData, encoding: .utf8)
    }
}

extension Receipt {
    var dateTimestamp: Date? {
        guard let timestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
}
