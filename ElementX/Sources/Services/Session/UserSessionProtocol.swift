//
//  UserSessionProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 27/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

protocol UserSessionProtocol {
    var clientProxy: ClientProxyProtocol { get }
    var mediaProvider: MediaProviderProtocol { get }
}
