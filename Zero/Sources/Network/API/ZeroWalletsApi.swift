//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

protocol ZeroWalletsApiProtocol {
    func initializeThirdWebWallet() async throws -> Result<Void, Error>
}

class ZeroWalletsApi: ZeroWalletsApiProtocol {
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
    
    // MARK: - Constants
    
    private enum WalletEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let initializeWalletEndPoint = "\(hostURL)thirdweb/initialize-wallet"
    }
}
