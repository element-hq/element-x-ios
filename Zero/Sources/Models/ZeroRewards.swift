import Foundation

public struct ZeroRewards: Codable, Equatable {
    var zero: String
    var zeroPreviousDay: String
    var decimals: Int
    var price: Double
    var reference: String
    
    init(rewards: ZRewards, currency: ZeroCurrency) {
        zero = rewards.zero
        zeroPreviousDay = rewards.zeroPreviousDay
        decimals = rewards.decimals
        price = currency.price ?? 0.0
        reference = currency.reference ?? ""
    }
    
    init() {
        zero = "0"
        zeroPreviousDay = "0"
        decimals = 0
        price = 0.0
        reference = ""
    }
    
    static func empty() -> ZeroRewards {
        ZeroRewards()
    }
}

extension ZeroRewards {
    func hasEarnedRewards() -> Bool {
        let current = parseCredits(credits: zero, decimals: decimals)
        let previous = parseCredits(credits: zeroPreviousDay, decimals: decimals)
        return Int((current - previous).rounded()) > 0
    }
    
    func getZeroCredits() -> Double {
        let credits = parseCredits(credits: zero, decimals: decimals)
        return credits
    }
    
    func getZeroCreditsFormatted() -> String {
        getZeroCredits().formatToThousandSeparatedString()
    }
    
    func getRefPrice() -> Double {
        let refPrice = price
        do {
            let credits = parseCredits(credits: zero, decimals: decimals)
            if refPrice > 0 {
                return credits * refPrice
            } else {
                return 0.0
            }
        } catch {
            return 0.0
        }
    }
    
    func getRefPriceFormatted() -> String {
        getRefPrice().formatToSuffix()
    }
}

private extension ZeroRewards {
    func parseCredits(credits: String, decimals: Int) -> Double {
        let delimiter = credits.count - decimals
        if delimiter < 0 { return 0 }
        let value = String(credits.prefix(delimiter)) + "." + (credits.substr(delimiter, 2) ?? "0")
        return Double(value) ?? 0.0
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
