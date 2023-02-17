// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import MatrixRustSDK

class RoomProxyProtocolMock: RoomProxyProtocol {
    var id: String {
        get { underlyingId }
        set(value) { underlyingId = value }
    }

    var underlyingId: String!
    var isDirect: Bool {
        get { underlyingIsDirect }
        set(value) { underlyingIsDirect = value }
    }

    var underlyingIsDirect: Bool!
    var isPublic: Bool {
        get { underlyingIsPublic }
        set(value) { underlyingIsPublic = value }
    }

    var underlyingIsPublic: Bool!
    var isSpace: Bool {
        get { underlyingIsSpace }
        set(value) { underlyingIsSpace = value }
    }

    var underlyingIsSpace: Bool!
    var isEncrypted: Bool {
        get { underlyingIsEncrypted }
        set(value) { underlyingIsEncrypted = value }
    }

    var underlyingIsEncrypted: Bool!
    var isTombstoned: Bool {
        get { underlyingIsTombstoned }
        set(value) { underlyingIsTombstoned = value }
    }

    var underlyingIsTombstoned: Bool!
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var hasUnreadNotifications: Bool {
        get { underlyingHasUnreadNotifications }
        set(value) { underlyingHasUnreadNotifications = value }
    }

    var underlyingHasUnreadNotifications: Bool!
    var name: String?
    var displayName: String?
    var topic: String?
    var avatarURL: URL?
    var permalink: URL?

    // MARK: - loadAvatarURLForUserId

    var loadAvatarURLForUserIdCallsCount = 0
    var loadAvatarURLForUserIdCalled: Bool {
        loadAvatarURLForUserIdCallsCount > 0
    }

    var loadAvatarURLForUserIdReceivedUserId: String?
    var loadAvatarURLForUserIdReceivedInvocations: [String] = []
    var loadAvatarURLForUserIdReturnValue: Result<URL?, RoomProxyError>!
    var loadAvatarURLForUserIdClosure: ((String) async -> Result<URL?, RoomProxyError>)?

    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError> {
        loadAvatarURLForUserIdCallsCount += 1
        loadAvatarURLForUserIdReceivedUserId = userId
        loadAvatarURLForUserIdReceivedInvocations.append(userId)
        if let loadAvatarURLForUserIdClosure = loadAvatarURLForUserIdClosure {
            return await loadAvatarURLForUserIdClosure(userId)
        } else {
            return loadAvatarURLForUserIdReturnValue
        }
    }

    // MARK: - loadDisplayNameForUserId

    var loadDisplayNameForUserIdCallsCount = 0
    var loadDisplayNameForUserIdCalled: Bool {
        loadDisplayNameForUserIdCallsCount > 0
    }

    var loadDisplayNameForUserIdReceivedUserId: String?
    var loadDisplayNameForUserIdReceivedInvocations: [String] = []
    var loadDisplayNameForUserIdReturnValue: Result<String?, RoomProxyError>!
    var loadDisplayNameForUserIdClosure: ((String) async -> Result<String?, RoomProxyError>)?

    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        loadDisplayNameForUserIdCallsCount += 1
        loadDisplayNameForUserIdReceivedUserId = userId
        loadDisplayNameForUserIdReceivedInvocations.append(userId)
        if let loadDisplayNameForUserIdClosure = loadDisplayNameForUserIdClosure {
            return await loadDisplayNameForUserIdClosure(userId)
        } else {
            return loadDisplayNameForUserIdReturnValue
        }
    }

    // MARK: - addTimelineListener

    var addTimelineListenerListenerCallsCount = 0
    var addTimelineListenerListenerCalled: Bool {
        addTimelineListenerListenerCallsCount > 0
    }

    var addTimelineListenerListenerReceivedListener: TimelineListener?
    var addTimelineListenerListenerReceivedInvocations: [TimelineListener] = []
    var addTimelineListenerListenerReturnValue: Result<Void, RoomProxyError>!
    var addTimelineListenerListenerClosure: ((TimelineListener) -> Result<Void, RoomProxyError>)?

    func addTimelineListener(listener: TimelineListener) -> Result<Void, RoomProxyError> {
        addTimelineListenerListenerCallsCount += 1
        addTimelineListenerListenerReceivedListener = listener
        addTimelineListenerListenerReceivedInvocations.append(listener)
        if let addTimelineListenerListenerClosure = addTimelineListenerListenerClosure {
            return addTimelineListenerListenerClosure(listener)
        } else {
            return addTimelineListenerListenerReturnValue
        }
    }

    // MARK: - paginateBackwards

    var paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount = 0
    var paginateBackwardsRequestSizeUntilNumberOfItemsCalled: Bool {
        paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount > 0
    }

    var paginateBackwardsRequestSizeUntilNumberOfItemsReceivedArguments: (requestSize: UInt, untilNumberOfItems: UInt)?
    var paginateBackwardsRequestSizeUntilNumberOfItemsReceivedInvocations: [(requestSize: UInt, untilNumberOfItems: UInt)] = []
    var paginateBackwardsRequestSizeUntilNumberOfItemsReturnValue: Result<Void, RoomProxyError>!
    var paginateBackwardsRequestSizeUntilNumberOfItemsClosure: ((UInt, UInt) async -> Result<Void, RoomProxyError>)?

    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError> {
        paginateBackwardsRequestSizeUntilNumberOfItemsCallsCount += 1
        paginateBackwardsRequestSizeUntilNumberOfItemsReceivedArguments = (requestSize: requestSize, untilNumberOfItems: untilNumberOfItems)
        paginateBackwardsRequestSizeUntilNumberOfItemsReceivedInvocations.append((requestSize: requestSize, untilNumberOfItems: untilNumberOfItems))
        if let paginateBackwardsRequestSizeUntilNumberOfItemsClosure = paginateBackwardsRequestSizeUntilNumberOfItemsClosure {
            return await paginateBackwardsRequestSizeUntilNumberOfItemsClosure(requestSize, untilNumberOfItems)
        } else {
            return paginateBackwardsRequestSizeUntilNumberOfItemsReturnValue
        }
    }

    // MARK: - sendReadReceipt

    var sendReadReceiptForCallsCount = 0
    var sendReadReceiptForCalled: Bool {
        sendReadReceiptForCallsCount > 0
    }

    var sendReadReceiptForReceivedEventID: String?
    var sendReadReceiptForReceivedInvocations: [String] = []
    var sendReadReceiptForReturnValue: Result<Void, RoomProxyError>!
    var sendReadReceiptForClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError> {
        sendReadReceiptForCallsCount += 1
        sendReadReceiptForReceivedEventID = eventID
        sendReadReceiptForReceivedInvocations.append(eventID)
        if let sendReadReceiptForClosure = sendReadReceiptForClosure {
            return await sendReadReceiptForClosure(eventID)
        } else {
            return sendReadReceiptForReturnValue
        }
    }

    // MARK: - sendMessage

    var sendMessageInReplyToCallsCount = 0
    var sendMessageInReplyToCalled: Bool {
        sendMessageInReplyToCallsCount > 0
    }

    var sendMessageInReplyToReceivedArguments: (message: String, eventID: String?)?
    var sendMessageInReplyToReceivedInvocations: [(message: String, eventID: String?)] = []
    var sendMessageInReplyToReturnValue: Result<Void, RoomProxyError>!
    var sendMessageInReplyToClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func sendMessage(_ message: String, inReplyTo eventID: String?) async -> Result<Void, RoomProxyError> {
        sendMessageInReplyToCallsCount += 1
        sendMessageInReplyToReceivedArguments = (message: message, eventID: eventID)
        sendMessageInReplyToReceivedInvocations.append((message: message, eventID: eventID))
        if let sendMessageInReplyToClosure = sendMessageInReplyToClosure {
            return await sendMessageInReplyToClosure(message, eventID)
        } else {
            return sendMessageInReplyToReturnValue
        }
    }

    // MARK: - sendReaction

    var sendReactionToCallsCount = 0
    var sendReactionToCalled: Bool {
        sendReactionToCallsCount > 0
    }

    var sendReactionToReceivedArguments: (reaction: String, eventID: String)?
    var sendReactionToReceivedInvocations: [(reaction: String, eventID: String)] = []
    var sendReactionToReturnValue: Result<Void, RoomProxyError>!
    var sendReactionToClosure: ((String, String) async -> Result<Void, RoomProxyError>)?

    func sendReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError> {
        sendReactionToCallsCount += 1
        sendReactionToReceivedArguments = (reaction: reaction, eventID: eventID)
        sendReactionToReceivedInvocations.append((reaction: reaction, eventID: eventID))
        if let sendReactionToClosure = sendReactionToClosure {
            return await sendReactionToClosure(reaction, eventID)
        } else {
            return sendReactionToReturnValue
        }
    }

    // MARK: - editMessage

    var editMessageOriginalCallsCount = 0
    var editMessageOriginalCalled: Bool {
        editMessageOriginalCallsCount > 0
    }

    var editMessageOriginalReceivedArguments: (newMessage: String, eventID: String)?
    var editMessageOriginalReceivedInvocations: [(newMessage: String, eventID: String)] = []
    var editMessageOriginalReturnValue: Result<Void, RoomProxyError>!
    var editMessageOriginalClosure: ((String, String) async -> Result<Void, RoomProxyError>)?

    func editMessage(_ newMessage: String, original eventID: String) async -> Result<Void, RoomProxyError> {
        editMessageOriginalCallsCount += 1
        editMessageOriginalReceivedArguments = (newMessage: newMessage, eventID: eventID)
        editMessageOriginalReceivedInvocations.append((newMessage: newMessage, eventID: eventID))
        if let editMessageOriginalClosure = editMessageOriginalClosure {
            return await editMessageOriginalClosure(newMessage, eventID)
        } else {
            return editMessageOriginalReturnValue
        }
    }

    // MARK: - redact

    var redactCallsCount = 0
    var redactCalled: Bool {
        redactCallsCount > 0
    }

    var redactReceivedEventID: String?
    var redactReceivedInvocations: [String] = []
    var redactReturnValue: Result<Void, RoomProxyError>!
    var redactClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        redactCallsCount += 1
        redactReceivedEventID = eventID
        redactReceivedInvocations.append(eventID)
        if let redactClosure = redactClosure {
            return await redactClosure(eventID)
        } else {
            return redactReturnValue
        }
    }

    // MARK: - members

    var membersCallsCount = 0
    var membersCalled: Bool {
        membersCallsCount > 0
    }

    var membersReturnValue: Result<[RoomMemberProxy], RoomProxyError>!
    var membersClosure: (() async -> Result<[RoomMemberProxy], RoomProxyError>)?

    func members() async -> Result<[RoomMemberProxy], RoomProxyError> {
        membersCallsCount += 1
        if let membersClosure = membersClosure {
            return await membersClosure()
        } else {
            return membersReturnValue
        }
    }

    // MARK: - retryDecryption

    var retryDecryptionForCallsCount = 0
    var retryDecryptionForCalled: Bool {
        retryDecryptionForCallsCount > 0
    }

    var retryDecryptionForReceivedSessionID: String?
    var retryDecryptionForReceivedInvocations: [String] = []
    var retryDecryptionForClosure: ((String) async -> Void)?

    func retryDecryption(for sessionID: String) async {
        retryDecryptionForCallsCount += 1
        retryDecryptionForReceivedSessionID = sessionID
        retryDecryptionForReceivedInvocations.append(sessionID)
        await retryDecryptionForClosure?(sessionID)
    }
}
