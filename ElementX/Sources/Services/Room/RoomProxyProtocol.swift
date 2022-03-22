//
//  RoomProxyProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//

import UIKit
import Combine

enum RoomProxyError: Error {
    case failedRetrievingDisplayName
    case failedRetrievingAvatar
    case backwardStreamNotAvailable
    case failedRetrievingMemberAvatarURL
    case failedRetrievingMemberDisplayName
}

enum RoomProxyCallback {
    case addedMessage(RoomMessageProtocol)
    case updatedLastMessage
}

protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var isTombstoned: Bool { get }
    
    var name: String? { get }
    
    var topic: String? { get }
    var lastMessage: String? { get }
    
    var avatarURL: String? { get }
    
    func displayName(_ completion: @escaping (Result<String, RoomProxyError>) -> Void)
    
    func avatarURLForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void)
    
    func displayNameForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void)
    
    func paginateBackwards(count: UInt, callback: ((Result<[RoomMessageProtocol], RoomProxyError>) -> Void)?)
    
    var callbacks: PassthroughSubject<RoomProxyCallback, Never> { get }
}
