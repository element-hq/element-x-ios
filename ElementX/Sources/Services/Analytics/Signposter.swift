//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CryptoKit
import Sentry

/// A simple wrapper around Sentry for easy instrumentation
class Signposter {
    private var transactions = [TransactionName: any Sentry.Span]()
    
    private var globalTags = [TagName: String]()
    
    enum TransactionName: Hashable {
        case cachedRoomList
        case upToDateRoomList
        case notificationToMessage
        case openRoom
        case sendMessage(uuid: String)
        
        var id: String {
            switch self {
            case .cachedRoomList:
                "Cached room list"
            case .upToDateRoomList:
                "Up-to-date room list"
            case .notificationToMessage:
                "Notification to message"
            case .openRoom:
                "Open a room"
            case .sendMessage:
                "Send a message"
            }
        }
    }
    
    enum SpanName: String {
        case timelineLoad = "Timeline load"
    }
    
    struct Span {
        fileprivate let innerSpan: Sentry.Span
        
        func finish() {
            innerSpan.finish()
        }
    }
    
    enum TagName: String {
        case homeserver = "Homeserver"
    }
    
    // MARK: - Transactions
    
    func startTransaction(_ transactionName: TransactionName, operation: String = "ux", tags: [TagName: String] = [:]) {
        let span = SentrySDK.startTransaction(name: transactionName.id, operation: operation)
        
        tags
            .merging(globalTags) { tagValue, _ in
                tagValue
            }
            .forEach { (key: TagName, value: String) in
                span.setTag(value: value, key: key.rawValue)
            }
        
        transactions[transactionName] = span
    }
    
    func finishTransaction(_ transactionName: TransactionName) {
        transactions[transactionName]?.finish()
        transactions[transactionName] = nil
    }
    
    // MARK: - Spans
    
    func addSpan(_ spanName: SpanName, toTransaction transactionName: TransactionName) -> Span? {
        guard let transaction = transactions[transactionName] else {
            MXLog.error("Transaction not started or already finished")
            return nil
        }
        
        return Span(innerSpan: transaction.startChild(operation: spanName.rawValue))
    }
    
    // MARK: - Tags
    
    func addGlobalTag(_ tagName: TagName, value: String) {
        let value = switch tagName {
        case .homeserver:
            sha512(value)
        }
        
        globalTags[tagName] = value
    }
    
    func removeGlobalTag(_ tagName: TagName) {
        globalTags[tagName] = nil
    }
    
    // MARK: - Private
    
    func sha512(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA512.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
