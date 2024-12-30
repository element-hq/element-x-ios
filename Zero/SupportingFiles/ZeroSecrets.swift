import Foundation

enum ZeroSecrets {
    private static func secrets() -> [String: Any] {
        let fileName = "zero_secrets"
        let path = Bundle.main.path(forResource: fileName, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    static var walletConnectProjectId: String {
        secrets()["WALLET_CONNECT_PROJECT_ID"] as! String
    }
}
