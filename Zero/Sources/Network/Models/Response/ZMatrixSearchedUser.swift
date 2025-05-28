import Foundation
import Tagged

public struct ZMatrixSearchedUser: Codable, Identifiable, Hashable {
    public let id: Tagged<Self, String>
    public let name: String
    public let matrixId: String
    public let profileImage: String?
    public let primaryZID: String?
    public let primaryWalletAddress: String?
}

extension ZMatrixSearchedUser {
    public var primaryZIdOrWalletAddress: String? {
        primaryZID ?? primaryWalletAddress
    }
    
    public var zIdOrPublicAddressDisplayText: String? {
        primaryZID ?? displayFormattedAddress(primaryWalletAddress)
    }
}

extension ZMatrixSearchedUser: Equatable {
    public static func == (lhs: ZMatrixSearchedUser, rhs: ZMatrixSearchedUser) -> Bool {
        lhs.id == rhs.id
    }
}
