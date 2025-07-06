import Foundation

public struct ZeroMessengerInvite: Codable, Equatable {
    var slug: String
    var remainingInvites: Int
    var invitesUsed: Int
    var proSubscriptions: Int
    
    init(messengerInvite: ZMessengerInvite) {
        slug = messengerInvite.slug ?? ""
        remainingInvites = if let availableInvites = messengerInvite.inviteCount {
            Int(availableInvites) ?? 0
        } else {
            0
        }
        invitesUsed = messengerInvite.invitesUsed ?? 0
        proSubscriptions = messengerInvite.proSubscriptions ?? 0
    }
    
    init() {
        slug = ""
        remainingInvites = 0
        invitesUsed = 0
        proSubscriptions = 0
    }
    
    static func empty() -> ZeroMessengerInvite {
        ZeroMessengerInvite()
    }
}
