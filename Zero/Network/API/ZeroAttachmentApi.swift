import Alamofire
import Foundation

protocol ZeroAttacmentApiProtocol {
    func downloadAttachmentInfo(key: String) async throws -> Result<ZAttachmentUploadInfo, any Error>
}

class ZeroAttachmentApi: ZeroAttacmentApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    func downloadAttachmentInfo(key: String) async throws -> Result<ZAttachmentUploadInfo, any Error> {
        let parameters: Parameters = [
            "key": key
        ]
        
        let result: Result<ZAttachmentUploadInfo, Error> = try await APIManager
            .shared
            .authorisedRequest(
                AttachmentEndPoints.attachmentInfoEndPoint,
                method: .get,
                appSettings: appSettings,
                parameters: parameters,
                encoding: URLEncoding.queryString
            )
        
        switch result {
        case .success(let attachmentInfo):
            return .success(attachmentInfo)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private struct AttachmentEndPoints {
        static let attachmentInfoEndPoint = "\(APIConfigs.zeroURLRoot)api/feedItems/getAttachmentDownloadInfo"
    }
}
