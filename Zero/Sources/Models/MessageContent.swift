import Foundation

public struct EventMessageContent: Codable {
    public var sender: String
    public var content: MessageContent
    public var roomId: String
    public var originServerTs: UInt64
    
    enum CodingKeys: String, CodingKey {
        case sender, content
        case roomId = "room_id"
        case originServerTs = "origin_server_ts"
    }
}

public struct MessageContent: Codable {
    public var optimisticID: String?
    public var info: EncryptedAttachmentInfo?
    public var localID: String?
    public var file: EncryptedAttachmentFile?
    public var messageType: String
    public var body: String?
    public var url: String?

    public var key: String? {
        file?.key?.k
    }

    public var iv: String? {
        file?.iv
    }
    
    enum CodingKeys: String, CodingKey {
        case optimisticID = "optimisticId"
        case info, file, body, url
        case localID = "localId"
        case messageType = "msgtype"
    }
}

public struct EncryptedAttachment: Codable {
    public var optimisticID: String?
    public var info: EncryptedAttachmentInfo
    public var localID: String?
    public var file: EncryptedAttachmentFile
    public var messageType: String
    public var body: String?

    public var key: String? {
        file.key?.k
    }

    public var iv: String? {
        file.iv
    }
    
    enum CodingKeys: String, CodingKey {
        case optimisticID = "optimisticId"
        case info, file, body
        case localID = "localId"
        case messageType = "msgtype"
    }
}

public struct EncryptedAttachmentInfo: Codable {
    public let mimeType: String
    public let name: String?
    public let optimisticID: String
    public let rootMessageID: String
    public let size: Int
    public let width: CGFloat?
    public let height: CGFloat?
    public let w: CGFloat?
    public let h: CGFloat?

    enum CodingKeys: String, CodingKey {
        case mimeType = "mimetype"
        case name, size, width, height, w, h
        case optimisticID = "optimisticId"
        case rootMessageID = "rootMessageId"
    }
}

public struct EncryptedAttachmentFile: Codable {
    public let hashes: [String: String]?
    public let iv: String?
    public let key: EncryptedAttachmentKey?
    public let url: String
    public let v: String?
}

public struct EncryptedAttachmentKey: Codable {
    public let alg: String
    public let ext: Bool
    public let k: String
    public let keyOps: [String]
    public let kty: String

    enum CodingKeys: String, CodingKey {
        case alg, ext, k, kty
        case keyOps = "key_ops"
    }
}

extension MessageContent {
    var isImage: Bool {
        messageType == "m.image"
    }
    
    var isVideo: Bool {
        messageType == "m.video"
    }
    
    var isRemoteImage: Bool {
        url?.isEmpty == false && file == nil
    }
}
