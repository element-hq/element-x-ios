//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct TimelineItemIdentifier: Hashable {
    /// Stable id across state changes of the timeline item, it uniquely identifies an item in a timeline.
    /// It's value is consistent only per timeline instance, it should **not** be used to identify an item across timeline instances.
    let uniqueID: String
    
    /// Contains the 2 possible identifiers of an event, either it has a remote event id or a local transaction id, never both or none.
    var eventOrTransactionID: EventOrTransactionId?
    
    var eventID: String? {
        switch eventOrTransactionID {
        case .eventId(let eventId):
            return eventId
        default:
            return nil
        }
    }
    
    var transactionID: String? {
        switch eventOrTransactionID {
        case .transactionId(let transactionId):
            return transactionId
        default:
            return nil
        }
    }
}

extension TimelineItemIdentifier {
    /// Use only for mocks/tests
    static var random: Self {
        .init(uniqueID: UUID().uuidString, eventOrTransactionID: .eventId(eventId: UUID().uuidString))
    }
}

/// A light wrapper around timeline items returned from Rust.
enum TimelineItemProxy {
    case event(EventTimelineItemProxy)
    case virtual(MatrixRustSDK.VirtualTimelineItem, uniqueID: String)
    case unknown(MatrixRustSDK.TimelineItem)
    
    init(item: MatrixRustSDK.TimelineItem, allRoomUsers: [ZMatrixUser]) {
        if let eventItem = item.asEvent() {
            let eventSenderId = eventItem.sender
            let eventSender = allRoomUsers.first(where: { $0.matrixId == eventSenderId })
            self = .event(EventTimelineItemProxy(item: eventItem, id: String(item.uniqueId()), eventSender: eventSender))
        } else if let virtualItem = item.asVirtual() {
            self = .virtual(virtualItem, uniqueID: String(item.uniqueId()))
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
    let eventSender: ZMatrixUser?
    
    init(item: MatrixRustSDK.EventTimelineItem, id: String, eventSender: ZMatrixUser? = nil) {
        self.item = item
        self.id = TimelineItemIdentifier(uniqueID: id, eventOrTransactionID: item.eventOrTransactionId)
        self.eventSender = eventSender
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
                         displayName: eventSender?.displayName ?? displayName,
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
        
        return String(decoding: jsonData, as: UTF8.self)
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
