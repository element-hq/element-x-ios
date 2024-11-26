import Foundation

public struct ZeroMessengerInvite: Codable, Equatable {
    var slug: String
    var remainingInvites: Int
    
    init(messengerInvite: ZMessengerInvite) {
        slug = messengerInvite.slug ?? ""
        remainingInvites = if let availableInvites = messengerInvite.inviteCount {
            Int(availableInvites) ?? 0
        } else {
            0
        }
    }
    
    init() {
        slug = ""
        remainingInvites = 0
    }
    
    static func empty() -> ZeroMessengerInvite {
        return ZeroMessengerInvite()
    }
}
