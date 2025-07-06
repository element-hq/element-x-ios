//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire

protocol ZeroWalletApiProtocol {
    func initializeThirdWebWallet() async throws -> Result<Void, Error>
    
    func getTokenBalances(walletAddress: String, nextPageParams: NextPageParams?) async throws -> Result<ZWalletTokenBalances, Error>
    
    func getNFTs(walletAddress: String, nextPageParams: NextPageParams?) async throws -> Result<ZWalletNFTs, Error>
    
    func getTransactions(walletAddress: String, nextPageParams: TransactionNextPageParams?) async throws -> Result<ZWalletTransactions, Error>
}

class ZeroWalletApi: ZeroWalletApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func initializeThirdWebWallet() async throws -> Result<Void, any Error> {
        let initializeWalletResult = try await APIManager.shared.authorisedRequest(WalletEndPoints.initializeWalletEndPoint,
                                                                                   method: .post,
                                                                                   appSettings: appSettings)
        switch initializeWalletResult {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getTokenBalances(walletAddress: String, nextPageParams: NextPageParams?) async throws -> Result<ZWalletTokenBalances, any Error> {
        let parameters = nextPageParams?.toDictionary() ?? [:]
        let url = WalletEndPoints.tokenBalances.replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
        let tokenBalancesResult: Result<ZWalletTokenBalances, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                                     method: .get,
                                                                                                                     appSettings: appSettings,
                                                                                                                     parameters: parameters,
                                                                                                                     encoding: URLEncoding.queryString)
        switch tokenBalancesResult {
        case .success(let tokenBalances):
            return .success(tokenBalances)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getNFTs(walletAddress: String, nextPageParams: NextPageParams?) async throws -> Result<ZWalletNFTs, any Error> {
        let parameters = nextPageParams?.toDictionary() ?? [:]
        let url = WalletEndPoints.nfts.replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
        let nftsResult: Result<ZWalletNFTs, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                   method: .get,
                                                                                                   appSettings: appSettings,
                                                                                                   parameters: parameters,
                                                                                                   encoding: URLEncoding.queryString)
        switch nftsResult {
        case .success(let nfts):
            return .success(nfts)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getTransactions(walletAddress: String, nextPageParams: TransactionNextPageParams?) async throws -> Result<ZWalletTransactions, any Error> {
        let parameters = nextPageParams?.toDictionary() ?? [:]
        let url = WalletEndPoints.transactions.replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
        let transactionsResult: Result<ZWalletTransactions, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                   method: .get,
                                                                                                   appSettings: appSettings,
                                                                                                   parameters: parameters,
                                                                                                   encoding: URLEncoding.queryString)
        switch transactionsResult {
        case .success(let transactions):
            return .success(transactions)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum WalletEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let initializeWalletEndPoint = "\(hostURL)thirdweb/initialize-wallet"
        static let tokenBalances = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/tokens"
        static let nfts = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/nfts"
        static let transactions = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/transactions"
    }
    
    private enum WalletApiConstants {
        static let address_path_parameter = "{address}"
    }
}
