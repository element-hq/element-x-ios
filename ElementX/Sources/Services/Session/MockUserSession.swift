//
//  MockUserSession.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine

struct MockUserSession: UserSessionProtocol {
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    let sessionVerificationController: SessionVerificationControllerProxyProtocol? = nil
    
    let userID: String = "@mock:usersession.com"
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
}
