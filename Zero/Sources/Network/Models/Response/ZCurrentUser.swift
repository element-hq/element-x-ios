import Foundation
import Tagged

public struct ZCurrentUser: Codable, Identifiable {
    public let id: Tagged<Self, String>
    public let profileId: String
    public let matrixAccessToken: String?
    public let matrixId: String?
    public let profileSummary: ZMatrixUserProfile?
    public let primaryZID: String?
    public let totalRewards: String?
    public let wallets: [ZWallet]?
    public let primaryWalletAddress: String?
    public let followersCount: String?
    public let followingCount: String?
    
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
    
    static let placeholder: ZCurrentUser = .init(
        id: .init("placeholder_id"),
        profileId: "",
        matrixAccessToken: nil,
        matrixId: nil,
        profileSummary: nil,
        primaryZID: nil,
        totalRewards: nil,
        wallets: nil,
        primaryWalletAddress: nil,
        followersCount: "0",
        followingCount: "0"
    )
}

extension ZCurrentUser: Equatable {
    public static func == (lhs: ZCurrentUser, rhs: ZCurrentUser) -> Bool {
        lhs.id == rhs.id
    }
}

extension ZCurrentUser: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ZCurrentUser {
    public var primaryZIdOrWalletAddress: String? {
        primaryZID ?? (primaryWalletAddress ?? thirdWebWalletAddress)
    }
    
    public var zIdOrPublicAddressDisplayText: String? {
        primaryZID ?? displayFormattedAddress(primaryWalletAddress ?? thirdWebWalletAddress)
    }
    
    var publicWalletAddress: String? {
        primaryWalletAddress ?? thirdWebWalletAddress
    }
    
    var thirdWebWalletAddress: String? {
        wallets?.first(where: { $0.isThirdWeb })?.publicAddress
    }
    
    var isFollowingOtherUsers: Bool {
        (Int(followingCount ?? "0") ?? 0) > 0
    }
}

public struct ZWallet: Codable {
    let id: String
    let userId: String
    let publicAddress: String
    let isDefault: Bool
    let isMultiSig: Bool
    let balance: String?
    let balanceCheckedAt: String?
    let dailyLimit: String?
    let requiredConfirmations: Int?
    let name: String?
    let data: String?
    let isThirdWeb: Bool
    let createdAt: String?
    let updatedAt: String?
}
