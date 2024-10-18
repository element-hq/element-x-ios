import Foundation

enum ZeroContants {
    /// Change app environment here and respective values will be applied everywhere .i.e. `DevServer()` or `ProdServer()`
    static let appServer: AppServer = ProdServer()
}

protocol AppServer {
    var matrixHomeServerUrl: String { get }
    var matrixHomeServerPostfix: String { get }
    var zeroRootUrl: String { get }
}

struct DevServer: AppServer {
    let matrixHomeServerUrl = "https://zero-synapse-development-db365bf96189.herokuapp.com"
    let matrixHomeServerPostfix = "zero-synapse-development.zer0.io"
    let zeroRootUrl = "https://zos-api-development-fb2c513ffa60.herokuapp.com/"
}

struct ProdServer: AppServer {
    let matrixHomeServerUrl = "https://zos-home-2-e24b9412096f.herokuapp.com"
    let matrixHomeServerPostfix = "zos-home-2.zero.tech"
    let zeroRootUrl = "https://zosapi.zero.tech/"
}
