//
//  MockClientProxy.swift
//  ElementX
//
//  Created by Doug on 29/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import MatrixRustSDK

struct MockClientProxy: ClientProxyProtocol {
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    let userIdentifier: String
    
    let rooms = [RoomProxy]()
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        .failure(.failedRetrievingDisplayName)
    }
    
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError> {
        .failure(.failedRetrievingAvatarURL)
    }
    
    func mediaSourceForURLString(_ urlString: String) -> MatrixRustSDK.MediaSource {
        MatrixRustSDK.mediaSourceFromUrl(url: urlString)
    }
    
    func loadMediaContentForSource(_ source: MatrixRustSDK.MediaSource) throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        .failure(.failedRetrievingSessionVerificationController)
    }
}
