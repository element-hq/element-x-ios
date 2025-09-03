//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire

protocol ZeroWalletApiProtocol {
    func initializeThirdWebWallet() async throws -> Result<Void, Error>
    
    func getTokenBalances(walletAddress: String, chainId: Int, nextPageParams: NextPageParams?) async throws -> Result<ZWalletTokenBalances, Error>
    
    func getNFTs(walletAddress: String, chainId: Int, nextPageParams: NextPageParams?) async throws -> Result<ZWalletNFTs, Error>
    
    func getTransactions(walletAddress: String, chainId: Int, nextPageParams: TransactionNextPageParams?) async throws -> Result<ZWalletTransactions, Error>
    
    func transferToken(senderWalletAddress: String, recipientWalletAddress: String, amount: String, tokenAddress: String, chainId: Int) async throws -> Result<ZWalletTransactionResponse, Error>
    
    func transferNFT(senderWalletAddress: String, recipientWalletAddress: String, tokenId: String, nftAddress: String) async throws -> Result<ZWalletTransactionResponse, Error>
    
    func getTransactionReceipt(transactionHash: String, chainId: Int) async throws -> Result<ZWalletTransactionReceipt, Error>
    
    func searchRecipients(query: String) async throws -> Result<[WalletRecipient], Error>
    
    func claimRewards(walletAddress: String) async throws -> Result<ZWalletTransactionResponse, Error>
    
    func getTokenInfo(tokenAddress: String) async throws -> Result<ZWalletTokenInfo, Error>
    
    func getTokenBalance(walletAddress: String, tokenAddress: String) async throws -> Result<ZWalletTokenBalance, Error>
    
    func approveERC20(walletAddress: String, poolAddress: String, tokenAddress: String, amount: String) async throws -> Result<ZWalletTransactionResponse, Error>
    
    func verifyERC20Approval(walletAddress: String, poolAddress: String, tokenAddress: String) async throws -> Result<Void, Error>
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
    
    func getTokenBalances(walletAddress: String, chainId: Int, nextPageParams: NextPageParams?) async throws -> Result<ZWalletTokenBalances, any Error> {
        var parameters = nextPageParams?.toDictionary() ?? [:]
        parameters["chainId"] = chainId.description
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
    
    func getNFTs(walletAddress: String, chainId: Int, nextPageParams: NextPageParams?) async throws -> Result<ZWalletNFTs, any Error> {
        var parameters = nextPageParams?.toDictionary() ?? [:]
        parameters["chainId"] = chainId.description
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
    
    func getTransactions(walletAddress: String, chainId: Int, nextPageParams: TransactionNextPageParams?) async throws -> Result<ZWalletTransactions, any Error> {
        var parameters = nextPageParams?.toDictionary() ?? [:]
        parameters["chainId"] = chainId.description
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
    
    func transferToken(senderWalletAddress: String, recipientWalletAddress: String, amount: String, tokenAddress: String, chainId: Int) async throws -> Result<ZWalletTransactionResponse, any Error> {
        let parameters = ZWalletTransferToken(recipientWalletAddress: recipientWalletAddress,
                                              amount: amount,
                                              tokenAddress: tokenAddress,
                                              chainId: chainId)
            .toDictionary()
        let url = WalletEndPoints.transferToken.replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: senderWalletAddress)
        let transactionResult: Result<ZWalletTransactionResponse, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                                         method: .post,
                                                                                                                         appSettings: appSettings,
                                                                                                                         parameters: parameters)
        switch transactionResult {
        case .success(let transaction):
            return .success(transaction)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func transferNFT(senderWalletAddress: String, recipientWalletAddress: String, tokenId: String, nftAddress: String) async throws -> Result<ZWalletTransactionResponse, any Error> {
        let parameters = ZWalletTransferNFT(recipientWalletAddress: recipientWalletAddress, tokenId: tokenId, nftAddress: nftAddress)
            .toDictionary()
        let url = WalletEndPoints.transferNft.replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: senderWalletAddress)
        let transactionResult: Result<ZWalletTransactionResponse, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                                         method: .post,
                                                                                                                         appSettings: appSettings,
                                                                                                                         parameters: parameters)
        switch transactionResult {
        case .success(let transaction):
            return .success(transaction)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getTransactionReceipt(transactionHash: String, chainId: Int) async throws -> Result<ZWalletTransactionReceipt, any Error> {
        let url = WalletEndPoints.transactionReceipt.replacingOccurrences(of: WalletApiConstants.trasaction_hash_path_parameter, with: transactionHash)
        let parameters = ["chainId": chainId.description]
        let receiptResult: Result<ZWalletTransactionReceipt, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                                    method: .get,
                                                                                                                    appSettings: appSettings,
                                                                                                                    parameters: parameters,
                                                                                                                    encoding: URLEncoding.queryString)
        switch receiptResult {
        case .success(let receipt):
            return .success(receipt)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func searchRecipients(query: String) async throws -> Result<[WalletRecipient], any Error> {
        let parameters = ["query": query]
        let result: Result<ZWalletRecipients, Error> = try await APIManager.shared.authorisedRequest(WalletEndPoints.searchRecipients,
                                                                                                     method: .get,
                                                                                                     appSettings: appSettings,
                                                                                                     parameters: parameters,
                                                                                                     encoding: URLEncoding.queryString)
        switch result {
        case .success(let response):
            return .success(response.recipients)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func claimRewards(walletAddress: String) async throws -> Result<ZWalletTransactionResponse, any Error> {
        let url = WalletEndPoints.claimRewards.replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
        let result: Result<ZWalletTransactionResponse, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                              method: .post,
                                                                                                              appSettings: appSettings)
        switch result {
        case .success(let transaction):
            ZeroCustomEventService.shared.walletApiEvent(parameters: [
                "request": "claim_rewards",
                "url": url,
                "address": walletAddress,
                "status": "success"
            ])
            return .success(transaction)
        case .failure(let failure):
            ZeroCustomEventService.shared.walletApiEvent(parameters: [
                "request": "claim_rewards",
                "url": url,
                "address": walletAddress,
                "status": "failure",
                "error": failure.localizedDescription
            ])
            return .failure(failure)
        }
    }
    
    func getTokenInfo(tokenAddress: String) async throws -> Result<ZWalletTokenInfo, any Error> {
        let url = WalletEndPoints.tokenInfo
            .replacingOccurrences(of: WalletApiConstants.token_address_path_parameter, with: tokenAddress)
        let result: Result<ZWalletTokenInfo, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                    method: .get,
                                                                                                    appSettings: appSettings)
        switch result {
        case .success(let info):
            return .success(info)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getTokenBalance(walletAddress: String, tokenAddress: String) async throws -> Result<ZWalletTokenBalance, any Error> {
        let url = WalletEndPoints.tokenBalance
            .replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
            .replacingOccurrences(of: WalletApiConstants.token_address_path_parameter, with: tokenAddress)
        let result: Result<ZWalletTokenBalance, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                    method: .get,
                                                                                                    appSettings: appSettings)
        switch result {
        case .success(let balance):
            return .success(balance)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func approveERC20(walletAddress: String, poolAddress: String, tokenAddress: String, amount: String) async throws -> Result<ZWalletTransactionResponse, any Error> {
        let url = WalletEndPoints.approveERC20
            .replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
        let parameters = [
            "amount": amount,
            "spenderAddress": poolAddress,
            "tokenAddress": tokenAddress
        ]
        let transactionResult: Result<ZWalletTransactionResponse, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                                         method: .post,
                                                                                                                         appSettings: appSettings,
                                                                                                                         parameters: parameters)
        switch transactionResult {
        case .success(let transaction):
            return .success(transaction)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func verifyERC20Approval(walletAddress: String, poolAddress: String, tokenAddress: String) async throws -> Result<Void, any Error> {
        let url = WalletEndPoints.verifyERC20Approval
            .replacingOccurrences(of: WalletApiConstants.address_path_parameter, with: walletAddress)
            .replacingOccurrences(of: WalletApiConstants.token_address_path_parameter, with: tokenAddress)
            .replacingOccurrences(of: WalletApiConstants.pool_address_path_parameter, with: poolAddress)
        let result: Result<ZWalletStakingApprovalResponse, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                                                         method: .get,
                                                                                                                         appSettings: appSettings)
        switch result {
        case .success(let allowance):
            return .success(())
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
        
        static let transferToken = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/transactions/transfer-token"
        static let transferNft = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/transactions/transfer-nft"
        static let transactionReceipt = "\(hostURL)api/wallet/transaction/\(WalletApiConstants.trasaction_hash_path_parameter)/receipt"
        static let searchRecipients = "\(hostURL)api/wallet/search-recipients"
        
        static let claimRewards = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/claim-rewards"
        
        static let tokenInfo = "\(hostURL)api/tokens/\(WalletApiConstants.token_address_path_parameter)/info"
        static let tokenBalance = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/token/\(WalletApiConstants.token_address_path_parameter)/balance"
        
        static let approveERC20 = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/transactions/approve-erc20"
        static let verifyERC20Approval = "\(hostURL)api/wallet/\(WalletApiConstants.address_path_parameter)/token/\(WalletApiConstants.token_address_path_parameter)/approval/\(WalletApiConstants.pool_address_path_parameter)"
    }
    
    private enum WalletApiConstants {
        static let address_path_parameter = "{address}"
        static let trasaction_hash_path_parameter = "{transaction_hash}"
        static let token_address_path_parameter = "{token_address}"
        static let pool_address_path_parameter = "{pool_address}"
    }
}
