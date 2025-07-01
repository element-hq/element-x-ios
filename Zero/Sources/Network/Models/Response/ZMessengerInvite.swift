import Foundation
import Tagged

public struct ZMessengerInvite: Decodable, Equatable, Identifiable {
    public let id: Tagged<Self, String>
    public let inviteCount, networkID, slug: String?
    public let invitesUsed, maxInvitesPerUser: Int?, proSubscriptions: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case networkID = "networkId"
        case slug, invitesUsed, maxInvitesPerUser, inviteCount, proSubscriptions
    }
}
