//
//  MockRoomProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import Foundation
import UIKit

struct MockRoomProxy: RoomProxyProtocol {
    let id = UUID().uuidString
    let name: String? = nil
    let displayName: String?
    
    let topic: String? = nil
    let messages: [RoomMessageProtocol] = []
    
    let avatarURL: String? = nil
    
    let isDirect = Bool.random()
    let isSpace = Bool.random()
    let isPublic = Bool.random()
    let isEncrypted = Bool.random()
    let isTombstoned = Bool.random()
    
    var callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        .failure(.failedRetrievingMemberDisplayName)
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        .failure(.failedRetrievingMemberAvatarURL)
    }
    
    func loadDisplayName() async -> Result<String, RoomProxyError> {
        .failure(.failedRetrievingDisplayName)
    }
    
    func startLiveEventListener() { }
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError> {
        .failure(.backwardStreamNotAvailable)
    }
        
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedSendingMessage)
    }
}
