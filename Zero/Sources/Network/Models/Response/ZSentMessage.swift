import Foundation

public struct ZSentMessage: Encodable {
    public let roomId: String
    public let sentAt: Int64
    public let type: String
    
    public init(roomId: String, sentAt: Int64, isRoomChannel: Bool) {
        self.roomId = roomId
        self.sentAt = sentAt
        self.type = isRoomChannel ? "channel" : "group"
    }
}
