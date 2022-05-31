//
//  RoomProxyProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import Combine

enum RoomProxyError: Error {
    case failedRetrievingDisplayName
    case failedRetrievingAvatar
    case backwardStreamNotAvailable
    case failedRetrievingMemberAvatarURL
    case failedRetrievingMemberDisplayName
    case failedSendingMessage
}

enum RoomProxyCallback {
    case updatedMessages
}

protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var isTombstoned: Bool { get }
    
    var name: String? { get }
    var displayName: String? { get }
    
    var topic: String? { get }
    var messages: [RoomMessageProtocol] { get }
    
    var avatarURL: String? { get }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func loadDisplayName() async -> Result<String, RoomProxyError>
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError>
    
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError>
    
    var callbacks: PassthroughSubject<RoomProxyCallback, Never> { get }
}
