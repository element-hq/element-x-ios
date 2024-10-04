import Foundation

public struct ZSessionDataResponse: Codable {
    public let accessToken: String
    public let identityToken: String
    public let expiresIn: Int
}
