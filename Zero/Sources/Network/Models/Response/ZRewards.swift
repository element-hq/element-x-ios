public struct ZRewards: Codable {
    public init(zero: String, zeroPreviousDay: String, decimals: Int) {
        self.zero = zero
        self.zeroPreviousDay = zeroPreviousDay
        self.decimals = decimals
    }

    public let zero: String
    public let zeroPreviousDay: String
    public let decimals: Int
}

// MARK: - ZeroCurrency
public struct ZeroCurrency: Codable {
    public let reference: String?
    public let price, diff: Double?
}
