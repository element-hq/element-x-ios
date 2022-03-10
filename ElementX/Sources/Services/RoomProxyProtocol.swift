//
//  RoomProxyProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//

import UIKit
import Combine
import MatrixRustSDK

enum RoomProxyCallback {
    case addedMessage(Message)
    case updatedLastMessage
}

protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    
    var name: String? { get }
    
    var topic: String? { get }
    var lastMessage: String? { get }
    
    var avatarURL: URL? { get }
    
    func loadDisplayName(_ completion: @escaping (Result<String, Error>) -> Void)
    func loadAvatar(_ completion: @escaping (Result<UIImage?, Error>) -> Void)
    
    func paginateBackwards(count: UInt, callback: ((Result<[Message], Error>) -> Void)?)
    
    var callbacks: PassthroughSubject<RoomProxyCallback, Never> { get }
}
