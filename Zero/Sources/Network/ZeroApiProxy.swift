//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

protocol ZeroApiProxyProtocol {
    var matrixUsersService: ZeroMatrixUsersService { get }
    
    var rewardsApi: ZeroRewardApiProtocol { get }
    var messengerInviteApi: ZeroMessengerInviteApiProtocol { get }
    var createAccountApi: ZeroCreateAccountApiProtocol { get }
    var userAccountApi: ZeroAccountApiProtocol { get }
    var postsApi: ZeroPostApiProtocol { get }
    var channelsApi: ZeroChannelApiProtocol { get }
    var walletsApi: ZeroWalletApiProtocol { get }
    var chatApi: ZeroChatApiProtocol { get }
    var metaDataApi: ZeroMetaDataApiProtocol { get }
    var postUserApi: ZeroPostUserApiProtocol { get }
    var stakingApi: ZeroStakingApiProtocol { get }
}

class ZeroApiProxy: ZeroApiProxyProtocol {
    
    let matrixUsersService: ZeroMatrixUsersService
    
    let rewardsApi: ZeroRewardApiProtocol
    let messengerInviteApi: ZeroMessengerInviteApiProtocol
    let createAccountApi: ZeroCreateAccountApiProtocol
    let userAccountApi: ZeroAccountApiProtocol
    let postsApi: ZeroPostApiProtocol
    let channelsApi: ZeroChannelApiProtocol
    let walletsApi: ZeroWalletApiProtocol
    let chatApi: ZeroChatApiProtocol
    let metaDataApi: ZeroMetaDataApiProtocol
    let postUserApi: ZeroPostUserApiProtocol
    let stakingApi: ZeroStakingApiProtocol
    
    init(client: ClientProtocol, appSettings: AppSettings) {
        /// Configure Zero Utlils, Services and APIs
        let zeroUsersApi = ZeroUserApi(appSettings: appSettings)
        matrixUsersService = ZeroMatrixUsersService(zeroUsersApi: zeroUsersApi,
                                                        appSettings: appSettings)
        rewardsApi = ZeroRewardApi(appSettings: appSettings)
        messengerInviteApi = ZeroMessengerInviteApi(appSettings: appSettings)
        createAccountApi = ZeroCreateAccountApi(appSettings: appSettings)
        userAccountApi = ZeroAccountApi(appSettings: appSettings)
        postsApi = ZeroPostApi(appSettings: appSettings)
        channelsApi = ZeroChannelApi(appSettings: appSettings)
        walletsApi = ZeroWalletApi(appSettings: appSettings)
        chatApi = ZeroChatApi(appSettings: appSettings)
        metaDataApi = ZeroMetaDataApi(appSettings: appSettings)
        postUserApi = ZeroPostUserApi(appSettings: appSettings)
        stakingApi = ZeroStakingApi(appSettings: appSettings)
    }
}
