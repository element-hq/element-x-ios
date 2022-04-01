//
//  MemberDetailProviderManager.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

class MemberDetailProviderManager {
    
    private var memberDetailProviders: [String: MemberDetailProviderProtocol] = [:]
    
    func memberDetailProviderForRoomProxy(_ roomProxy: RoomProxyProtocol) -> MemberDetailProviderProtocol {
        if let memberDetailProvider = memberDetailProviders[roomProxy.id] {
            return memberDetailProvider
        }
        
        let memberDetailProvider = MemberDetailProvider(roomProxy: roomProxy)
        memberDetailProviders[roomProxy.id] = memberDetailProvider
        return memberDetailProvider
    }
}
