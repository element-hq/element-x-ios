//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire

protocol ZeroStakingApiProtocol {
    
    func getTotalStaked(poolAddress: String) async throws -> Result<String, Error>
    
    func getStakingConfig(poolAddress: String) async throws -> Result<ZStackingConfig, Error>
    
    func getStakerStatusInfo(userWalletAddress: String, poolAddress: String) async throws -> Result<ZStakingStatus, Error>
    
    func getStakeRewardsInfo(userWalletAddress: String, poolAddress: String) async throws -> Result<ZStakingUserRewardsInfo, Error>
    
    func getStakingToken(poolAddress: String) async throws -> Result<ZWalletStakingToken, Error>
    
    func getRewardsToken(poolAddress: String) async throws -> Result<ZWalletStakingRewardsToken, Error>
}

class ZeroStakingApi : ZeroStakingApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    func getTotalStaked(poolAddress: String) async throws -> Result<String, any Error> {
        let url = StakingEndPoints.totalStaked.replacingOccurrences(of: StakingApiConstants.stake_pool_address, with: poolAddress)
        let result: Result<String, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                          method: .get,
                                                                                          appSettings: appSettings)
        switch result {
        case .success(let totalStaked):
            return .success(totalStaked)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getStakingConfig(poolAddress: String) async throws -> Result<ZStackingConfig, any Error> {
        let url = StakingEndPoints.config.replacingOccurrences(of: StakingApiConstants.stake_pool_address, with: poolAddress)
        let result: Result<ZStackingConfig, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                   method: .get,
                                                                                                   appSettings: appSettings)
        switch result {
        case .success(let config):
            return .success(config)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getStakerStatusInfo(userWalletAddress: String, poolAddress: String) async throws -> Result<ZStakingStatus, any Error> {
        let url = StakingEndPoints.stakers
            .replacingOccurrences(of: StakingApiConstants.stake_user_address, with: userWalletAddress)
            .replacingOccurrences(of: StakingApiConstants.stake_pool_address, with: poolAddress)
        let result: Result<ZStakingStatus, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                  method: .get,
                                                                                                  appSettings: appSettings)
        switch result {
        case .success(let status):
            return .success(status)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getStakeRewardsInfo(userWalletAddress: String, poolAddress: String) async throws -> Result<ZStakingUserRewardsInfo, any Error> {
        let url = StakingEndPoints.rewards
            .replacingOccurrences(of: StakingApiConstants.stake_user_address, with: userWalletAddress)
            .replacingOccurrences(of: StakingApiConstants.stake_pool_address, with: poolAddress)
        let result: Result<ZStakingUserRewardsInfo, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                           method: .get,
                                                                                                           appSettings: appSettings)
        switch result {
        case .success(let info):
            return .success(info)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getStakingToken(poolAddress: String) async throws -> Result<ZWalletStakingToken, any Error> {
        let url = StakingEndPoints.stakingToken
            .replacingOccurrences(of: StakingApiConstants.stake_pool_address, with: poolAddress)
        let result: Result<ZWalletStakingToken, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                           method: .get,
                                                                                                           appSettings: appSettings)
        switch result {
        case .success(let token):
            return .success(token)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getRewardsToken(poolAddress: String) async throws -> Result<ZWalletStakingRewardsToken, any Error> {
        let url = StakingEndPoints.rewardsToken
            .replacingOccurrences(of: StakingApiConstants.stake_pool_address, with: poolAddress)
        let result: Result<ZWalletStakingRewardsToken, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                           method: .get,
                                                                                                           appSettings: appSettings)
        switch result {
        case .success(let token):
            return .success(token)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum StakingEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let totalStaked = "\(hostURL)api/staking/\(StakingApiConstants.stake_pool_address)/total-staked"
        static let config = "\(hostURL)api/staking/\(StakingApiConstants.stake_pool_address)/config"
        static let stakers = "\(hostURL)api/staking/\(StakingApiConstants.stake_user_address)/stakers/\(StakingApiConstants.stake_pool_address)"
        static let rewards = "\(hostURL)api/staking/\(StakingApiConstants.stake_user_address)/rewards/\(StakingApiConstants.stake_pool_address)"
        static let stakingToken = "\(hostURL)api/staking/\(StakingApiConstants.stake_pool_address)/staking-token"
        static let rewardsToken = "\(hostURL)api/staking/\(StakingApiConstants.stake_pool_address)/rewards-token"
    }
    
    private enum StakingApiConstants {
        static let stake_user_address = "{user_address}"
        static let stake_pool_address = "{pool_address}"
    }
}
