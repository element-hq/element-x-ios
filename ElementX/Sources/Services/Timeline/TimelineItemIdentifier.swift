//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
@preconcurrency import MatrixRustSDK

/// A timeline item identifier
/// - uniqueID: Stable id across state changes of the timeline item, it uniquely identifies an item in a timeline.
/// Its value is consistent only per timeline instance, it should **not** be used to identify an item across timeline instances.
/// - eventOrTransactionID: Contains the 2 possible identifiers of an event, either it has a remote event id or
/// a local transaction id, never both or none.
enum TimelineItemIdentifier: Hashable, Sendable {
    struct UniqueID: Hashable {
        let value: String
        
        init(_ value: String) {
            self.value = value
        }
        
        init(rustValue: TimelineUniqueId) {
            self.init(rustValue.id)
        }
        
        var rustValue: TimelineUniqueId {
            .init(id: value)
        }
    }
    
    enum EventOrTransactionID: Hashable {
        case eventID(String), transactionID(String)
        
        init(rustValue: EventOrTransactionId) {
            switch rustValue {
            case .eventId(let eventID): self = .eventID(eventID)
            case .transactionId(let transactionID): self = .transactionID(transactionID)
            }
        }
        
        var rustValue: EventOrTransactionId {
            switch self {
            case .eventID(let eventID): .eventId(eventId: eventID)
            case .transactionID(let transactionID): .transactionId(transactionId: transactionID)
            }
        }
    }
    
    case event(uniqueID: UniqueID, eventOrTransactionID: EventOrTransactionID)
    case virtual(uniqueID: UniqueID)
    
    var uniqueID: UniqueID {
        switch self {
        case .event(let uniqueID, _): uniqueID
        case .virtual(let uniqueID): uniqueID
        }
    }
    
    var eventOrTransactionID: EventOrTransactionID? {
        guard case let .event(_, eventOrTransactionID) = self else { return nil }
        return eventOrTransactionID
    }
    
    var eventID: String? {
        guard case let .event(_, .eventID(eventID)) = self else { return nil }
        return eventID
    }
    
    var transactionID: String? {
        guard case let .event(_, .transactionID(transactionID)) = self else { return nil }
        return transactionID
    }
}

// MARK: - Mocks

extension TimelineItemIdentifier {
    static var randomEvent: Self {
        .event(uniqueID: .init(UUID().uuidString), eventOrTransactionID: .eventID(UUID().uuidString))
    }
    
    static var randomVirtual: Self {
        .virtual(uniqueID: .init(UUID().uuidString))
    }
}
