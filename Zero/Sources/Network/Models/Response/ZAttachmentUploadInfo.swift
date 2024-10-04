import Foundation

public struct ZAttachmentUploadInfo: Codable {
    public let signedUrl: String
    public let key: String

    public var downloadURL: URL? {
        URL(string: signedUrl)
    }
}
