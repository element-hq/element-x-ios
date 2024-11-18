import Alamofire
import Foundation

protocol ZeroRewardsApiProtocol {
    func fetchMyRewards() async throws -> Result<ZRewards, Error>

    func loadZeroCurrenyRate() async throws -> Result<ZeroCurrency, Error>
}

class ZeroRewardsApi: ZeroRewardsApiProtocol {
    private let appSettings: AppSettings

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }

    // MARK: - Public
    func fetchMyRewards() async throws -> Result<ZRewards, any Error> {
        let result: Result<ZRewards, Error> =
            try await APIManager
            .shared
            .authorisedRequest(
                RewardEndPoints.myRewardsEndPoint,
                method: .get,
                appSettings: appSettings)
        switch result {
        case .success(let rewards):
            return .success(rewards)
        case .failure(let error):
            return .failure(error)
        }
    }

    func loadZeroCurrenyRate() async throws -> Result<ZeroCurrency, any Error> {
        let result: Result<ZeroCurrency, Error> =
            try await APIManager
            .shared
            .authorisedRequest(
                RewardEndPoints.zeroCurrenyEndPoint,
                method: .get,
                appSettings: appSettings)
        switch result {
        case .success(let tokens):
            return .success(tokens)
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Constants
    private enum RewardEndPoints {
        static let hostURL = ZeroContants.appServer.zeroRootUrl

        static let myRewardsEndPoint = "\(hostURL)rewards/mine"
        static let zeroCurrenyEndPoint = "\(hostURL)api/tokens/zero"
    }
}
