//
//  UserSessionProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 27/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

enum UserSessionCallback {
    case sessionVerificationNeeded
    case didVerifySession
}

protocol UserSessionProtocol {
    var clientProxy: ClientProxyProtocol { get }
    var mediaProvider: MediaProviderProtocol { get }
    
    var sessionVerificationController: SessionVerificationControllerProxyProtocol? { get }
    
    var callbacks: PassthroughSubject<UserSessionCallback, Never> { get }
}
