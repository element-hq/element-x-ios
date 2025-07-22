public struct ZRewards: Codable {
    public let zero: String
    public let zeroPreviousDay: String
    public let decimals: Int
    
    public let legacyRewards: String
    public let meow: String
    public let meowPreviousDay: String
    public let totalDailyRewards: String
    public let totalReferralFees: String
    public let unclaimedRewards: String
}

// MARK: - ZeroCurrency

public struct ZeroCurrency: Codable {
    public let reference: String?
    public let price, diff: Double?
}
