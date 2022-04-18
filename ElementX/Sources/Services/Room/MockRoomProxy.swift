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
    let displayName: String
    
    let topic: String? = nil
    let messages: [RoomMessageProtocol] = []
    
    let avatarURL: String? = nil
    
    let isDirect = Bool.random()
    let isSpace = Bool.random()
    let isPublic = Bool.random()
    let isEncrypted = Bool.random()
    let isTombstoned = Bool.random()
    
    var callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    func displayName(_ completion: @escaping (Result<String, RoomProxyError>) -> Void) {
        completion(.success(displayName))
    }
    
    func startLiveEventListener() {
        
    }
    
    func paginateBackwards(count: UInt, callback: ((Result<Void, RoomProxyError>) -> Void)?) {
        
    }
    
    func avatarURLForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void) {
        
    }
    
    func displayNameForUserId(_ userId: String, completion: @escaping (Result<String?, RoomProxyError>) -> Void) {
        
    }
    
    func sendMessage(_ message: String, callback: ((Result<Void, RoomProxyError>) -> Void)?) {
        
    }
}
