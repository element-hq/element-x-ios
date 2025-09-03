import Foundation

enum ZeroContants {
    /// Change app environment here and respective values will be applied everywhere .i.e. `DevServer()` or `ProdServer()`
    static let appServer: AppServer = ProdServer()
    
    static let accountProvider: String = ZeroContants.appServer.matrixHomeServerUrl.replacingOccurrences(of: "https://", with: "")
    static let ZERO_APP_STORE_APP_ID = "6476882926"
    
    /// Channel Constants
    static let ZERO_CHANNEL_PREFIX = "0://"
    
    /// Wallet Constants
    static let ZERO_WALLET_ADDRESS_PREFIX = "0x"
    static let ZERO_WALLET_ZSCAN_LIVE_URL = "https://zscan.live/"
    
    private static let ZCHAIN_ID_MAINNET: UInt64 = 9369
    private static let ZCHAIN_ID_ZEPHYR: UInt64 = 1417429182
    static let ZERO_WALLET_ZCHAIN_ID = (appServer is ProdServer) ? ZCHAIN_ID_MAINNET : ZCHAIN_ID_ZEPHYR
    
    /// Subscription Constants
    static let ZERO_PRO_SUBSCRIPTION_USD: Double = 14.99
    
    /// Staking Constants
    static let ZERO_WALLET_MEOW_POOL_ADDRESS = "0xfbDC0647F0652dB9eC56c7f09B7dD3192324AD6a"
    static let ZERO_WALLET_MEOW_IMAGE_URL = "https://zos.zero.tech/tokens/meow.png"
    static let ZERO_WALLET_MEOW_POOL_NAME = "MEOW Pool"
}

protocol AppServer {
    var matrixHomeServerUrl: String { get }
    var matrixHomeServerPostfix: String { get }
    var zeroRootUrl: String { get }
    var walletConnectProjectId: String { get }
}

struct DevServer: AppServer {
    let matrixHomeServerUrl = "https://zero-synapse-development-db365bf96189.herokuapp.com"
    let matrixHomeServerPostfix = "zero-synapse-development.zer0.io"
    let zeroRootUrl = "https://zos-api-development-fb2c513ffa60.herokuapp.com/"
    let walletConnectProjectId = ZeroSecrets.walletConnectProjectId
}

struct ProdServer: AppServer {
    let matrixHomeServerUrl = "https://zos-home-2-e24b9412096f.herokuapp.com"
    let matrixHomeServerPostfix = "zos-home-2.zero.tech"
    let zeroRootUrl = "https://zosapi.zero.tech/"
    let walletConnectProjectId = ZeroSecrets.walletConnectProjectId
}
