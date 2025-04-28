//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

protocol ZeroApiProxyProtocol {
    var matrixUsersService: ZeroMatrixUsersService { get }
    
    var rewardsApi: ZeroRewardsApiProtocol { get }
    var messengerInviteApi: ZeroMessengerInviteApiProtocol { get }
    var createAccountApi: ZeroCreateAccountApiProtocol { get }
    var userAccountApi: ZeroAccountApiProtocol { get }
    var postsApi: ZeroPostsApiProtocol { get }
    var channelsApi: ZeroChannelsApiProtocol { get }
    var walletsApi: ZeroWalletsApiProtocol { get }
    var chatApi: ZeroChatApiProtocol { get }
    var metaDataApi: ZeroMetaDataApiProtocol { get }
}

class ZeroApiProxy: ZeroApiProxyProtocol {
    
    let matrixUsersService: ZeroMatrixUsersService
    
    let rewardsApi: ZeroRewardsApiProtocol
    let messengerInviteApi: ZeroMessengerInviteApiProtocol
    let createAccountApi: ZeroCreateAccountApiProtocol
    let userAccountApi: ZeroAccountApiProtocol
    let postsApi: ZeroPostsApiProtocol
    let channelsApi: ZeroChannelsApiProtocol
    let walletsApi: ZeroWalletsApiProtocol
    let chatApi: ZeroChatApiProtocol
    let metaDataApi: ZeroMetaDataApiProtocol
    
    init(client: ClientProtocol, appSettings: AppSettings) {
        /// Configure Zero Utlils, Services and APIs
        let zeroUsersApi = ZeroUsersApi(appSettings: appSettings)
        matrixUsersService = ZeroMatrixUsersService(zeroUsersApi: zeroUsersApi,
                                                        appSettings: appSettings,
                                                        client: client)
        rewardsApi = ZeroRewardsApi(appSettings: appSettings)
        messengerInviteApi = ZeroMessengerInviteApi(appSettings: appSettings)
        createAccountApi = ZeroCreateAccountApi(appSettings: appSettings)
        userAccountApi = ZeroAccountApi(appSettings: appSettings)
        postsApi = ZeroPostsApi(appSettings: appSettings)
        channelsApi = ZeroChannelsApi(appSettings: appSettings)
        walletsApi = ZeroWalletsApi(appSettings: appSettings)
        chatApi = ZeroChatApi(appSettings: appSettings)
        metaDataApi = ZeroMetaDataApi(appSettings: appSettings)
    }
}
