//
//  MockRoomProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17.02.2022.
//

import Foundation
import UIKit
import Combine

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
        return .failure(.failedRetrievingMemberDisplayName)
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        return .failure(.failedRetrievingMemberAvatarURL)
    }
    
    func loadDisplayName() async -> Result<String, RoomProxyError> {
        return .failure(.failedRetrievingDisplayName)
    }
    
    func startLiveEventListener() {
        
    }
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError> {
        return .failure(.backwardStreamNotAvailable)
    }
        
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        return .failure(.failedSendingMessage)
    }
}
