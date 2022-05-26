//
//  UserSession.swift
//  ElementX
//
//  Created by Stefan Ceriu on 27/05/2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation

class UserSession: UserSessionProtocol {
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
    }
}
