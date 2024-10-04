import Foundation

public struct ZSentMessage: Encodable {
    public let roomId: String
    public let sentAt: Int64
    
    public init(roomId: String, sentAt: Int64) {
        self.roomId = roomId
        self.sentAt = sentAt
    }
}
