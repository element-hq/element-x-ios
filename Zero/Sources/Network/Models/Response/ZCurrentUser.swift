import Foundation
import Tagged

public struct ZCurrentUser: Codable, Identifiable {
    public let id: Tagged<Self, String>
    public let profileId: String
    public let matrixAccessToken: String?
    public let matrixId: String?
    public let profileSummary: ZMatrixUserProfile?
    
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
