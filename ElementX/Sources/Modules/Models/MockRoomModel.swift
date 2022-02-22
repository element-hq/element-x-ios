//
//  MockRoomModel.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//

import Foundation
import UIKit

struct MockRoomModel: RoomModelProtocol {
    let identifier = UUID().uuidString
    let name: String? = nil
    let displayName: String
    
    let topic: String? = nil
    let lastMessage: String? = "Last message" 
    
    let avatarURL: URL? = nil
    
    let isDirect = Bool.random()
    let isSpace = Bool.random()
    let isPublic = Bool.random()
    let isEncrypted = Bool.random()
    
    func loadAvatar(_ completion: (Result<UIImage?, Error>) -> Void) {
        completion(.success(UIImage(systemName: "wand.and.stars")))
    }
}
