import Foundation
import Tagged

public struct ZMatrixUser: Codable, Identifiable {
    public let id: Tagged<Self, String>
    public let profileId: String
    public let handle: String
    public let lastActiveAt: Date?
    public let isOnline: Bool?
    public let isPending: Bool
    public let matrixId: String
    public let matrixAccessToken: String?
    public let profileSummary: ZMatrixUserProfile?
    public let primaryZID: String?
    public let primaryWalletAddress: String?
    
    public var profileImageURL: URL? {
        URL(string: profileSummary?.profileImage ?? "")
    }
    
    public var displayName: String {
        if let profile = profileSummary {
            if let firstName = profile.firstName {
                return firstName
            }
        }
        
        return handle
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
        primaryZID ?? formatted(address: primaryWalletAddress)
    }
    
    private func formatted(address: String?) -> String? {
        if let walletAddress = address {
            let firstSix = String(walletAddress.prefix(6))
            let lastFour = String(walletAddress.suffix(4))
            return "\(firstSix)...\(lastFour)"
        }
        return nil
    }
}
