//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire
import Foundation

protocol ZeroMetaDataApiProtocol {
    func getLinkPreview(url: String) async throws -> Result<ZLinkPreview, Error>
}

class ZeroMetaDataApi: ZeroMetaDataApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func getLinkPreview(url: String) async throws -> Result<ZLinkPreview, any Error> {
        let items: [String: Any] = ["url": url]
        let jsonData = try! JSONSerialization.data(withJSONObject: items)
        let json = String(data: jsonData, encoding: .utf8)!
        
        let parameters: Parameters = [
            "filter": json
        ]
        let result: Result<ZLinkPreview, Error> =
        try await APIManager
            .shared
            .authorisedRequest(MetaDataEndPoints.linkPreviewEndPoint,
                               method: .get,
                               appSettings: appSettings,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let linkPreview):
            return .success(linkPreview)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum MetaDataEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let linkPreviewEndPoint = "\(hostURL)linkPreviews"
    }
}
