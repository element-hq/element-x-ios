import Foundation
import Tagged

public struct ZMatrixUser: Codable, Identifiable {
    public let id: Tagged<Self, String>
    public let profileId: String
    public let lastActiveAt: Date?
    public let isOnline: Bool?
    public let isPending: Bool
    public let matrixId: String
    public let matrixAccessToken: String?
    public let profileSummary: ZMatrixUserProfile?
    public let primaryZID: String?
    public let primaryWalletAddress: String?
    public let wallets: [ZWallet]?
    
    public var profileImageURL: URL? {
        URL(string: profileSummary?.profileImage ?? "")
    }
    
    public var displayName: String {
        if let profile = profileSummary {
            if let firstName = profile.firstName {
                return firstName
            }
        }
        
        return ""
    }
}

extension ZMatrixUser: Equatable {
    public static func == (lhs: ZMatrixUser, rhs: ZMatrixUser) -> Bool {
        lhs.id == rhs.id
    }
}

extension ZMatrixUser: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ZMatrixUser {
    public var primaryZIdOrWalletAddress: String? {
        primaryZID ?? (primaryWalletAddress ?? thirdWebWalletAddress)
    }
    
    public var zIdOrPublicAddressDisplayText: String? {
        primaryZID ?? displayFormattedAddress(primaryWalletAddress ?? thirdWebWalletAddress)
    }
    
    var thirdWebWalletAddress: String? {
        wallets?.first(where: { $0.isThirdWeb })?.publicAddress
    }
}

func displayFormattedAddress(_ address: String?) -> String? {
    if let walletAddress = address {
        let firstSix = String(walletAddress.prefix(6))
        let lastFour = String(walletAddress.suffix(4))
        return "\(firstSix)...\(lastFour)"
    }
    return nil
}
