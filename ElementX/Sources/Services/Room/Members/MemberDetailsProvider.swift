//
//  MemberDetailsProvider.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

class MemberDetailsProvider: MemberDetailsProviderProtocol {
    private let roomProxy: RoomProxyProtocol?
    private var memberAvatars = [String: String]()
    private var memberDisplayNames = [String: String]()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
    }
    
    func avatarURLForUserId(_ userId: String) -> String? {
        self.memberAvatars[userId]
    }
    
    func avatarURLForUserId(_ userId: String, completion: @escaping (Result<String?, MemberDetailsProviderError>) -> Void) {
        guard let roomProxy = roomProxy else {
            return
        }
        
        if let avatarURL = avatarURLForUserId(userId) {
            completion(.success(avatarURL))
        }
        
        roomProxy.avatarURLForUserId(userId, completion: { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let avatarURL):
                self.memberAvatars[userId] = avatarURL
                completion(.success(avatarURL))
            case .failure:
                completion(.failure(.failedRetrievingUserAvatarURL))
            }
        })
    }
    
    func displayNameForUserId(_ userId: String) -> String? {
        self.memberDisplayNames[userId]
    }
    
    func displayNameForUserId(_ userId: String, completion: @escaping (Result<String?, MemberDetailsProviderError>) -> Void) {
        guard let roomProxy = roomProxy else {
            return
        }
        
        if let avatarURL = displayNameForUserId(userId) {
            completion(.success(avatarURL))
        }
        
        roomProxy.displayNameForUserId(userId, completion: { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let displayName):
                self.memberDisplayNames[userId] = displayName
                completion(.success(displayName))
            case .failure:
                completion(.failure(.failedRetrievingUserDisplayName))
            }
        })
    }
}
