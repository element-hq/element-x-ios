//
//  MockUserSession.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct MockUserSession: UserSessionProtocol {
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
}
