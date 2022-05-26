//
//  MemberDetailProvider.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

class MemberDetailProvider: MemberDetailProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var memberAvatars = [String: String]()
    private var memberDisplayNames = [String: String]()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
    }
    
    func avatarURLStringForUserId(_ userId: String) -> String? {
        memberAvatars[userId]
    }
    
    func loadAvatarURLStringForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError> {
        if let avatarURL = avatarURLStringForUserId(userId) {
            return .success(avatarURL)
        }
        
        switch await roomProxy.loadAvatarURLForUserId(userId) {
        case .success(let avatarURL):
            memberAvatars[userId] = avatarURL
            return .success(avatarURL)
        case .failure:
            return .failure(.failedRetrievingUserAvatarURL)
        }
    }
        
    func displayNameForUserId(_ userId: String) -> String? {
        memberDisplayNames[userId]
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError> {
        if let displayName = displayNameForUserId(userId) {
            return .success(displayName)
        }
        
        switch await roomProxy.loadDisplayNameForUserId(userId) {
        case .success(let displayName):
            memberDisplayNames[userId] = displayName
            return .success(displayName)
        case .failure:
            return .failure(.failedRetrievingUserDisplayName)
        }
    }
}
