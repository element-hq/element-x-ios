import Foundation

public struct ZFinaliseCreateAccount: Encodable {
    let inviteCode: String
    let name: String
    let userId: String
    let profileImage: String?
    
    public init(inviteCode: String, name: String, userId: String, profileImageUrl: String?) {
        self.inviteCode = inviteCode
        self.name = name
        self.userId = userId
        profileImage = profileImageUrl
    }
}
