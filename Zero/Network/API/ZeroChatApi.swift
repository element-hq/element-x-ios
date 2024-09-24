import Alamofire
import Foundation

protocol ZeroChatApiProtocol {
    func notifyAboutMessage(roomId: String) async throws -> Result<Void, Error>
}

class ZeroChatApi: ZeroChatApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func notifyAboutMessage(roomId: String) async throws -> Result<Void, any Error> {
        let time = Int64(Date().timeIntervalSince1970 * 1000)
        let parameters: Parameters = [
            "roomId": roomId,
            "sentAt": time
        ]
        
        let result: Result<Void, Error> = try await APIManager
            .shared
            .authorisedRequest(
                ChatEndPoints.matrixMessageEndPoint,
                method: .post,
                appSettings: appSettings,
                parameters: parameters
            )
        
        switch result {
        case .success:
            MXLog.debug("New message notified successfully")
            return .success(())
        case .failure(let error):
            MXLog.debug("Notify new message failed")
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private struct ChatEndPoints {
        static let matrixMessageEndPoint = "\(APIConfigs.zeroURLRoot)matrix/message"
    }
}
