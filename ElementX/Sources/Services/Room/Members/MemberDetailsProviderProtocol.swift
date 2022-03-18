//
//  MemberDetailsProviderProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum MemberDetailsProviderError: Error {
    case invalidRoomProxy
    case failedRetrievingUserAvatarURL
}

protocol MemberDetailsProviderProtocol {
    func avatarURLForUserId(_ userId: String) -> String?
    func avatarURLForUserId(_ userId: String, completion: @escaping (Result<String?, MemberDetailsProviderError>) -> Void)
}
