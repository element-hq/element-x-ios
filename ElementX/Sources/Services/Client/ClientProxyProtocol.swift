//
//  ClientProxyProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 26/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK
import Combine

enum ClientProxyCallback {
    case updatedRoomsList
    case receivedSyncUpdate
}

enum ClientProxyError: Error {
    case failedRetrievingAvatarURL
    case failedRetrievingDisplayName
    case failedRetrievingSessionVerificationController
    case failedLoadingMedia
}

protocol ClientProxyProtocol {
    var callbacks: PassthroughSubject<ClientProxyCallback, Never> { get }
    
    var userIdentifier: String { get }
    
    var rooms: [RoomProxy] { get }
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError>
        
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError>
    
    func mediaSourceForURLString(_ urlString: String) -> MatrixRustSDK.MediaSource
    
    func loadMediaContentForSource(_ source: MatrixRustSDK.MediaSource) throws -> Data
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>
}
