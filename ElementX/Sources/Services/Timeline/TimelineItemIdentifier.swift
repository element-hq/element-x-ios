//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A timeline item identifier
/// - uniqueID: Stable id across state changes of the timeline item, it uniquely identifies an item in a timeline.
/// Its value is consistent only per timeline instance, it should **not** be used to identify an item across timeline instances.
/// - eventOrTransactionID: Contains the 2 possible identifiers of an event, either it has a remote event id or
/// a local transaction id, never both or none.
enum TimelineItemIdentifier: Hashable, Sendable {
    case event(uniqueID: TimelineUniqueId, eventOrTransactionID: EventOrTransactionId)
    case virtual(uniqueID: TimelineUniqueId)
    
    var uniqueID: TimelineUniqueId {
        switch self {
        case .event(let uniqueID, _):
            return uniqueID
        case .virtual(let uniqueID):
            return uniqueID
        }
    }
    
    var eventID: String? {
        guard case let .event(_, eventOrTransactionID) = self else {
            return nil
        }
        
        switch eventOrTransactionID {
        case .eventId(let eventID):
            return eventID
        default:
            return nil
        }
    }
    
    var transactionID: String? {
        guard case let .event(_, eventOrTransactionID) = self else {
            return nil
        }
        
        switch eventOrTransactionID {
        case .transactionId(let transactionID):
            return transactionID
        default:
            return nil
        }
    }
}

// MARK: - Mocks

extension TimelineItemIdentifier {
    static var randomEvent: Self {
        .event(uniqueID: .init(id: UUID().uuidString), eventOrTransactionID: .eventId(eventId: UUID().uuidString))
    }
    
    static var randomVirtual: Self {
        .virtual(uniqueID: .init(id: UUID().uuidString))
    }
}
