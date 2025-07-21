import Foundation

public struct ZeroRewards: Codable, Equatable {
    private var zero: Double
    private var zeroPreviousDay: Double
    private var unclaimedRewards: Double
    private var price: Double
    private var reference: String
    var decimals: Int
    
    init(rewards: ZRewards, currency: ZeroCurrency) {
        zero = Self.parseCredits(credits: rewards.meow, decimals: rewards.decimals)
        zeroPreviousDay = Self.parseCredits(credits: rewards.meowPreviousDay, decimals: rewards.decimals)
        unclaimedRewards = Self.parseCredits(credits: rewards.unclaimedRewards, decimals: rewards.decimals)
        decimals = rewards.decimals
        price = currency.price ?? 0.0
        reference = currency.reference ?? ""
    }
    
    init() {
        zero = 0.0
        zeroPreviousDay = 0.0
        unclaimedRewards = 0.0
        decimals = 0
        price = 0.0
        reference = ""
    }
    
    static func empty() -> ZeroRewards {
        ZeroRewards()
    }
    
    private static func parseCredits(credits: String, decimals: Int) -> Double {
        let delimiter = credits.count - decimals
        if delimiter < 0 { return 0 }
        let value = String(credits.prefix(delimiter)) + "." + (credits.substr(delimiter, 2) ?? "0")
        return (try? Double(value)) ?? 0.0
    }
}

extension ZeroRewards {
    var zeroCredits: Double {
        zero
    }
    
    func hasUnclaimedRewards() -> Bool {
        return unclaimedRewards > 0
    }
    
    func getZeroCreditsFormatted() -> String {
        zeroCredits.formatToThousandSeparatedString()
    }
    
    func getUnclaimedRewardsFormatted() -> String {
        unclaimedRewards.formatToThousandSeparatedString()
    }
    
    func getRefPriceFormatted() -> String {
        getRefPrice().formatToSuffix()
    }
    
    func getUnclaimedRewardsRefPriceFormatted() -> String {
        getUnclaimedRewardsRefPrice().formatToSuffix()
    }
    
    private func getRefPrice() -> Double {
        let refPrice = price
        if refPrice > 0 {
            return zeroCredits * refPrice
        } else {
            return 0.0
        }
    }
    
    private func getUnclaimedRewardsRefPrice() -> Double {
        let refPrice = price
        if refPrice > 0 {
            return unclaimedRewards * refPrice
        } else {
            return 0.0
        }
    }
}

private extension Double {
    func formatToThousandSeparatedString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        
        return numberFormatter.string(from: NSNumber(value: self)) ?? String(self)
    }
    
    func formatToSuffix() -> String {
        let suffixes = ["", "K", "M", "B", "T", "P", "E"]
        var value = self
        var index = 0

        while value >= 1000, index < suffixes.count - 1 {
            value /= 1000
            index += 1
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        
        if let formattedValue = numberFormatter.string(from: NSNumber(value: value)) {
            return "\(formattedValue)\(suffixes[index])"
        } else {
            return "\(self)"
        }
    }
}
