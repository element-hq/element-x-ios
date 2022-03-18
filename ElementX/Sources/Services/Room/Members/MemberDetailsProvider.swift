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
    private let processingQueue = DispatchQueue(label: "MemberDetailsProviderProcessingQueue")
    private var memberAvatars = [String: String]()
    
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
        
        processingQueue.async {
            roomProxy.avatarURLForUserId(userId, completion: { [weak self] result in
                guard let self = self else {
                    return
                }
                
                switch result {
                case .success(let avatarURL):
                    DispatchQueue.main.async {
                        self.memberAvatars[userId] = avatarURL
                        completion(.success(avatarURL))
                    }
                case .failure:
                    DispatchQueue.main.async {
                        completion(.failure(.failedRetrievingUserAvatarURL))
                    }
                }
            })
        }
    }
}
