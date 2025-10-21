//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct MentionBuilder: MentionBuilderProtocol {
    struct AttributesToRestore {
        let font: UIFont
        let blockquote: Bool?
        let foregroundColor: UIColor
    }
    
    func handleUserMention(for attributedString: NSMutableAttributedString,
                           in range: NSRange,
                           url: URL,
                           userID: String,
                           userDisplayName: String?) {
        let attributesToRestore = getAttributesToRestore(for: attributedString, in: range)
        
        let attachmentData = PillTextAttachmentData(type: .user(userID: userID), font: attributesToRestore.font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            attributedString.addAttribute(.MatrixUserID, value: userID, range: range)
            
            if let userDisplayName {
                attributedString.addAttribute(.MatrixUserDisplayName, value: userDisplayName, range: range)
            }
            
            return
        }
        
        var attachmentAttributes: [NSAttributedString.Key: Any] = [.link: url,
                                                                   .MatrixUserID: userID,
                                                                   .font: attributesToRestore.font,
                                                                   .foregroundColor: attributesToRestore.foregroundColor]
        attachmentAttributes.addBlockquoteIfNeeded(attributesToRestore.blockquote)
        attachmentAttributes.addMatrixUsernameIfNeeded(userDisplayName)
        
        setPillAttachment(attachment: attachment,
                          attributedString: attributedString,
                          in: range,
                          with: attachmentAttributes)
    }
    
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange) {
        let attributesToRestore = getAttributesToRestore(for: attributedString, in: range)

        let attachmentData = PillTextAttachmentData(type: .allUsers, font: attributesToRestore.font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            return
        }
        
        var attachmentAttributes: [NSAttributedString.Key: Any] = [.font: attributesToRestore.font,
                                                                   .MatrixAllUsersMention: true,
                                                                   .foregroundColor: attributesToRestore.foregroundColor]
        attachmentAttributes.addBlockquoteIfNeeded(attributesToRestore.blockquote)
        
        setPillAttachment(attachment: attachment,
                          attributedString: attributedString,
                          in: range,
                          with: attachmentAttributes)
    }
    
    func handleRoomIDMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, roomID: String) {
        let attributesToRestore = getAttributesToRestore(for: attributedString, in: range)
        
        let attachmentData = PillTextAttachmentData(type: .roomID(roomID), font: attributesToRestore.font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            attributedString.addAttribute(.MatrixRoomID, value: roomID, range: range)
            return
        }
        
        var attachmentAttributes: [NSAttributedString.Key: Any] = [.link: url,
                                                                   .MatrixRoomID: roomID,
                                                                   .font: attributesToRestore.font,
                                                                   .foregroundColor: attributesToRestore.foregroundColor]
        attachmentAttributes.addBlockquoteIfNeeded(attributesToRestore.blockquote)

        setPillAttachment(attachment: attachment,
                          attributedString: attributedString,
                          in: range,
                          with: attachmentAttributes)
    }
    
    func handleRoomAliasMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, roomAlias: String, roomDisplayName: String?) {
        let attributesToRestore = getAttributesToRestore(for: attributedString, in: range)
        
        let attachmentData = PillTextAttachmentData(type: .roomAlias(roomAlias), font: attributesToRestore.font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            attributedString.addAttribute(.MatrixRoomAlias, value: roomAlias, range: range)
            if let roomDisplayName {
                attributedString.addAttribute(.MatrixRoomDisplayName, value: roomDisplayName, range: range)
            }
            return
        }
        
        var attachmentAttributes: [NSAttributedString.Key: Any] = [.link: url,
                                                                   .MatrixRoomAlias: roomAlias,
                                                                   .font: attributesToRestore.font,
                                                                   .foregroundColor: attributesToRestore.foregroundColor]
        attachmentAttributes.addBlockquoteIfNeeded(attributesToRestore.blockquote)
        attachmentAttributes.addMatrixRoomNameIfNeeded(roomDisplayName)
        
        setPillAttachment(attachment: attachment,
                          attributedString: attributedString,
                          in: range,
                          with: attachmentAttributes)
    }
    
    func handleEventOnRoomAliasMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, eventID: String, roomAlias: String) {
        let attributesToRestore = getAttributesToRestore(for: attributedString, in: range)
        
        let attachmentData = PillTextAttachmentData(type: .event(room: .roomAlias(roomAlias)), font: attributesToRestore.font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            attributedString.addAttribute(.MatrixEventOnRoomAlias, value: EventOnRoomAliasAttribute.Value(alias: roomAlias, eventID: eventID), range: range)
            return
        }
        
        var attachmentAttributes: [NSAttributedString.Key: Any] = [.link: url,
                                                                   .MatrixEventOnRoomAlias: EventOnRoomAliasAttribute.Value(alias: roomAlias, eventID: eventID),
                                                                   .font: attributesToRestore.font,
                                                                   .foregroundColor: attributesToRestore.foregroundColor]
        attachmentAttributes.addBlockquoteIfNeeded(attributesToRestore.blockquote)
        
        setPillAttachment(attachment: attachment,
                          attributedString: attributedString,
                          in: range,
                          with: attachmentAttributes)
    }
    
    func handleEventOnRoomIDMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, eventID: String, roomID: String) {
        let attributesToRestore = getAttributesToRestore(for: attributedString, in: range)
        
        let attachmentData = PillTextAttachmentData(type: .event(room: .roomID(roomID)), font: attributesToRestore.font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            attributedString.addAttribute(.MatrixEventOnRoomID, value: EventOnRoomIDAttribute.Value(roomID: roomID, eventID: eventID), range: range)
            return
        }
        
        var attachmentAttributes: [NSAttributedString.Key: Any] = [.link: url,
                                                                   .MatrixEventOnRoomID: EventOnRoomIDAttribute.Value(roomID: roomID, eventID: eventID),
                                                                   .font: attributesToRestore.font,
                                                                   .foregroundColor: attributesToRestore.foregroundColor]
        attachmentAttributes.addBlockquoteIfNeeded(attributesToRestore.blockquote)
        
        setPillAttachment(attachment: attachment,
                          attributedString: attributedString,
                          in: range,
                          with: attachmentAttributes)
    }
    
    private func getAttributesToRestore(for attributedString: NSMutableAttributedString, in range: NSRange) -> AttributesToRestore {
        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
        let blockquote = attributes[.MatrixBlockquote] as? Bool
        let foregroundColor = attributes[.foregroundColor] as? UIColor ?? .compound.textPrimary
        
        return AttributesToRestore(font: font, blockquote: blockquote, foregroundColor: foregroundColor)
    }
    
    private func setPillAttachment(attachment: PillTextAttachment,
                                   attributedString: NSMutableAttributedString,
                                   in range: NSRange,
                                   with attributes: [NSAttributedString.Key: Any]) {
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: attachmentString.length))
        attributedString.replaceCharacters(in: range, with: attachmentString)
    }
}

private extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    mutating func addBlockquoteIfNeeded(_ value: Bool?) {
        if let value {
            self[.MatrixBlockquote] = value
        }
    }
    
    mutating func addMatrixUsernameIfNeeded(_ value: String?) {
        if let value {
            self[.MatrixUserDisplayName] = value
        }
    }
    
    mutating func addMatrixRoomNameIfNeeded(_ value: String?) {
        if let value {
            self[.MatrixRoomDisplayName] = value
        }
    }
}
