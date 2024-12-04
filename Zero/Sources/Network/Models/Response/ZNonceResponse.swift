public struct ZNonceResponse: Decodable {
    public let nonceToken: String
    public let expiresIn: Int?
}

extension ZNonceResponse {
    var nonceHeaderToken: String {
        "Nonce \(nonceToken)"
    }
}
