import Alamofire
import Foundation

protocol ZeroMessengerInviteApiProtocol {
    func fetchMessengerInvite() async throws -> Result<ZMessengerInvite, Error>
}

class ZeroMessengerInviteApi: ZeroMessengerInviteApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    func fetchMessengerInvite() async throws -> Result<ZMessengerInvite, any Error> {
        let result: Result<ZMessengerInvite, Error> =
            try await APIManager
                .shared
                .authorisedRequest(MessengerInviteEndPoints.invite,
                                   method: .post,
                                   appSettings: appSettings)
        switch result {
        case .success(let invite):
            return .success(invite)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private enum MessengerInviteEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl

        static let invite = "\(hostURL)invite"
    }
}
