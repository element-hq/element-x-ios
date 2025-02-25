//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire
import Foundation

protocol ZeroChannelsApiProtocol {
    func fetchZeroIds() async throws -> Result<[String], any Error>
    
    func joinChannel(roomAliasOrId: String) async throws -> Result<String, any Error>
}

class ZeroChannelsApi: ZeroChannelsApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func fetchZeroIds() async throws -> Result<[String], any Error> {
        let result: Result<[String], Error> = try await APIManager.shared.authorisedRequest(ChannelEndPoints.zidsEndPoint,
                                                                                            method: .get,
                                                                                            appSettings: appSettings)
        switch result {
        case .success(let zIds):
            return .success(zIds)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func joinChannel(roomAliasOrId: String) async throws -> Result<String, any Error> {
        let parameters: [String: String] = ["roomAliasORId": roomAliasOrId]
        let result: Result<ZChannelRoomId, Error> = try await APIManager.shared.authorisedRequest(ChannelEndPoints.joinChannelEndPoint,
                                                                                                  method: .post,
                                                                                                  appSettings: appSettings,
                                                                                                  parameters: parameters)
        switch result {
        case .success(let channelRoomId):
            return .success(channelRoomId.roomId)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum ChannelEndPoints {
        static let zidsEndPoint = "\(ZeroContants.appServer.zeroRootUrl)api/v2/users/zids"
        static let joinChannelEndPoint = "\(ZeroContants.appServer.zeroRootUrl)matrix/room/join"
    }
}
