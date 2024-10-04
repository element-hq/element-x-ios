import Foundation

public struct ZMatrixSession: Codable {
    public let userID: String
    public let accessToken: String
    public let homeServer: String
    public let deviceID: String

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case accessToken = "access_token"
        case homeServer = "home_server"
        case deviceID = "device_id"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userID = try values.decode(String.self, forKey: .userID)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        homeServer = try values.decode(String.self, forKey: .homeServer)
        deviceID = try values.decode(String.self, forKey: .deviceID)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(homeServer, forKey: .homeServer)
        try container.encode(deviceID, forKey: .deviceID)
    }
}
