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
    
    func getPostMediaInfo(mediaId: String) async throws -> Result<ZPostMedia, Error>
    
    func uploadMedia(media: URL) async throws -> Result<String, Error>
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
    
    func getPostMediaInfo(mediaId: String) async throws -> Result<ZPostMedia, any Error> {
        let url = MetaDataEndPoints.feedMediaEndPoint.appending("/\(mediaId)")
        let result: Result<ZPostMedia, Error> = try await APIManager.shared.authorisedRequest(url, method: .get, appSettings: appSettings)
        switch result {
        case .success(let mediaInfo):
            return .success(mediaInfo)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func uploadMedia(media: URL) async throws -> Result<String, any Error> {
        let result: Result<ZPostMediaUploadedInfo, Error> = try await APIManager.shared
            .authorisedMultipartRequest(MetaDataEndPoints.feedMediaEndPoint,
                                        mediaFile: media,
                                        appSettings: appSettings)
        switch result {
        case .success(let mediaInfo):
            return .success(mediaInfo.id)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum MetaDataEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let linkPreviewEndPoint = "\(hostURL)linkPreviews"
        static let feedMediaEndPoint = "\(hostURL)api/media"
    }
}
