import Foundation

public struct ZMatrixUserProfile: Codable {
    public let id: String?
    public let firstName: String?
    public let lastName: String?
    public let gender: String?
    public let summary: String?
    public let backgroundImage: String?
    public let profileImage: String?
    public let ssbPublicKey: String?
    
    public func fullName() -> String {
        let formatter = PersonNameComponentsFormatter()
        
        var components = PersonNameComponents()
        components.givenName = firstName
        components.familyName = lastName
        
        return formatter.string(from: components)
    }
}
