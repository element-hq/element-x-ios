import Foundation

public struct ZCreateAccount: Encodable {
    let user: ZCreateAccountProfile
    let inviteSlug: String

    public init(user: ZCreateAccountProfile, inviteSlug: String) {
        self.user = user
        self.inviteSlug = inviteSlug
    }
    
    static func newRequest(email: String, password: String, invite: String) -> ZCreateAccount {
        ZCreateAccount(user: ZCreateAccountProfile(email: email, password: password, handle: email),
                       inviteSlug: invite)
    }
}

public struct ZCreateAccountProfile: Encodable {
    let email, password, handle: String

    public init(email: String, password: String, handle: String) {
        self.email = email
        self.password = password
        self.handle = handle
    }
}
