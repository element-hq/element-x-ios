//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum BlockquoteAttribute: AttributedStringKey {
    typealias Value = Bool
    static var name = "MXBlockquoteAttribute"
}

enum UserIDAttribute: AttributedStringKey {
    typealias Value = String
    static var name = "MXUserIDAttribute"
}

/// This attribute is used to help the composer convert a mention into to a markdown link before sending
/// the message. It doesn't interact mention pills, as these fetch display names live from the room.
enum UserDisplayNameAttribute: AttributedStringKey {
    typealias Value = String
    static var name = "MXUserDisplayNameAttribute"
}

enum RoomIDAttribute: AttributedStringKey {
    typealias Value = String
    static var name = "MXRoomIDAttribute"
}

enum RoomAliasAttribute: AttributedStringKey {
    typealias Value = String
    static var name = "MXRoomAliasAttribute"
}

enum EventOnRoomIDAttribute: AttributedStringKey {
    struct Value: Hashable {
        let roomID: String
        let eventID: String
    }
    
    static var name = "MXEventOnRoomIDAttribute"
}

enum EventOnRoomAliasAttribute: AttributedStringKey {
    struct Value: Hashable {
        let alias: String
        let eventID: String
    }
    
    static var name = "MXEventOnRoomAliasAttribute"
}

enum AllUsersMentionAttribute: AttributedStringKey {
    typealias Value = Bool
    static var name = "MXAllUsersMentionAttribute"
}

// periphery: ignore - required to make NSAttributedString to AttributedString conversion even if not used directly
extension AttributeScopes {
    struct ElementXAttributes: AttributeScope {
        let blockquote: BlockquoteAttribute
        
        let userID: UserIDAttribute
        let userDisplayName: UserDisplayNameAttribute
        let roomID: RoomIDAttribute
        let roomAlias: RoomAliasAttribute
        let eventOnRoomID: EventOnRoomIDAttribute
        let eventOnRoomAlias: EventOnRoomAliasAttribute
        
        let allUsersMention: AllUsersMentionAttribute
        
        let swiftUI: SwiftUIAttributes
        let uiKit: UIKitAttributes
    }
    
    var elementX: ElementXAttributes.Type { ElementXAttributes.self }
}

// periphery: ignore - required to make NSAttributedString to AttributedString conversion even if not used directly
extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.ElementXAttributes, T>) -> T {
        self[T.self]
    }
}
