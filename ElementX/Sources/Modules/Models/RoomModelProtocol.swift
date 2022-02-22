//
//  RoomModelProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//

import UIKit

protocol RoomModelProtocol {
    var identifier: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    
    var displayName: String { get }
    var name: String? { get }
    
    var topic: String? { get }
    var lastMessage: String? { get }
    
    var avatarURL: URL? { get }
    
    func getAvatar(_ completion: @escaping (Result<UIImage?, Error>) -> Void)
}
