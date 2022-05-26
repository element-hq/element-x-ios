//
//  MemberDetailProviderProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum MemberDetailProviderError: Error {
    case invalidRoomProxy
    case failedRetrievingUserAvatarURL
    case failedRetrievingUserDisplayName
}

@MainActor
protocol MemberDetailProviderProtocol {
    func avatarURLStringForUserId(_ userId: String) -> String?
    func loadAvatarURLStringForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError>
    
    func displayNameForUserId(_ userId: String) -> String?
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError>
}
