import Foundation
import CryptoSwift

class ZeroAttachmentService {
    private let zeroAttachmentApi: ZeroAttachmentApi
    private let appSettings: AppSettings
    
    private var isRoomEncrypted: Bool
    
    enum FileError: Error {
        case contentURLNotFound
        case downloadURLNotFound
        case errorDecyptingAttachment
    }
    
    init(appSettings: AppSettings, isRoomEncrypted: Bool = true) {
        zeroAttachmentApi = ZeroAttachmentApi(appSettings: appSettings)
        self.appSettings = appSettings
        self.isRoomEncrypted = isRoomEncrypted
    }
    
    func downloadMessageAttachment(_ content: MessageContent) async throws -> Data {
        if let url = content.file?.url {
            let attachmentDownloadInfoResponse = try await zeroAttachmentApi.downloadAttachmentInfo(key: url)
            switch attachmentDownloadInfoResponse {
            case .success(let downloadInfo):
                if let downloadURL = downloadInfo.downloadURL {
                    
                    let attachmentData = try Data(contentsOf: downloadURL)
                    if isRoomEncrypted {
                        //decrypt the attachment
                        let decryptedData = try decryptAttachment(attachment: content, data: attachmentData)
                        return decryptedData
                    } else {
                        return attachmentData
                    }
                } else {
                    throw FileError.downloadURLNotFound
                }
            case .failure(let error):
                throw error
            }
        } else {
            throw FileError.contentURLNotFound
        }
    }
    
    public func decryptAttachment(attachment: MessageContent, data: Data) throws -> Data {
        do {
            guard let keyData = Data(base64urlEncoded: attachment.key ?? "") else {
                throw FileError.errorDecyptingAttachment
            }
            
            guard let ivData = Data(base64urlEncoded: attachment.iv ?? "") else {
                throw FileError.errorDecyptingAttachment
            }
            
            let key = keyData.map { $0 }
            let ivParameter = ivData.map { $0 }
            let aes = try AES(key: key, blockMode: CTR(iv: ivParameter), padding: .noPadding)
            
            let imageData = try data.decrypt(cipher: aes)
            return imageData
        } catch {
            print("Unable to decrypt attachment: \(error)")
            throw error
        }
    }
    
    public func setRoomEncrypted(_ encrypted: Bool) {
        self.isRoomEncrypted = encrypted
    }
}

private extension Data {
    init?(base64urlEncoded input: String) {
        var base64 = input
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        self.init(base64Encoded: base64)
    }

    func base64urlEncodedString() -> String {
        var result = base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}
