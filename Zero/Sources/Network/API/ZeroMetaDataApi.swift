//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire
import Foundation

enum MediaLoadingError: Error {
    case invalidSignedURL
}

actor FeedMediaCacheActor {
    private var mediaUrlCache: [String: ZPostMedia] = [:]
    private var linkPreviewCache: [String: ZLinkPreview] = [:]

    func valueMedia(for id: String) -> ZPostMedia? {
        mediaUrlCache[id]
    }
    
    func valueLinkPreview(for id: String) -> ZLinkPreview? {
        linkPreviewCache[id]
    }

    func storeMedia(_ value: ZPostMedia, for id: String) {
        mediaUrlCache[id] = value
    }
    
    func storeLinkPreview(_ value: ZLinkPreview, for id: String) {
        linkPreviewCache[id] = value
    }
}

protocol ZeroMetaDataApiProtocol {
    func getLinkPreview(url: String) async throws -> Result<ZLinkPreview, Error>
    
    func getPostMediaInfo(mediaId: String, isPreview: Bool) async throws -> Result<ZPostMedia, Error>
    
    func uploadMedia(media: URL) async throws -> Result<String, Error>
    
    func fetchYoutubeLinkMetaData(youtubeUrl: String) async throws -> Result<ZLinkPreview, Error>
    
    func loadFileFromUrl(_ remoteUrl: URL) async throws -> Result<URL, Error>
    
    func loadFileFromMediaId(_ mediaId: String) async throws -> Result<URL, Error>
}

class ZeroMetaDataApi: ZeroMetaDataApiProtocol {
    private let appSettings: AppSettings
    private let feedMediaCacheActor = FeedMediaCacheActor()
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func getLinkPreview(url: String) async throws -> Result<ZLinkPreview, any Error> {
        if let cachedLinkPreview = await feedMediaCacheActor.valueLinkPreview(for: url) {
            return .success(cachedLinkPreview)
        }
        
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
            await feedMediaCacheActor.storeLinkPreview(linkPreview, for: url)
            return .success(linkPreview)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getPostMediaInfo(mediaId: String, isPreview: Bool) async throws -> Result<ZPostMedia, any Error> {
        if isPreview, let cachedMediaInfo = await feedMediaCacheActor.valueMedia(for: mediaId) {
            return .success(cachedMediaInfo)
        }
        
        let parameters: Parameters = ["is_preview": isPreview.description]
        let url = MetaDataEndPoints.feedMediaEndPoint.appending("/\(mediaId)")
        let result: Result<ZPostMedia, Error> = try await APIManager.shared.authorisedRequest(url,
                                                                                              method: .get,
                                                                                              appSettings: appSettings,
                                                                                              parameters: parameters,
                                                                                              encoding: URLEncoding.queryString)
        switch result {
        case .success(let mediaInfo):
            await feedMediaCacheActor.storeMedia(mediaInfo, for: mediaId)
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
            _ = try await getPostMediaInfo(mediaId: mediaInfo.id, isPreview: true)
            return .success(mediaInfo.id)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func fetchYoutubeLinkMetaData(youtubeUrl: String) async throws -> Result<ZLinkPreview, any Error> {
        if let cachedLinkPreview = await feedMediaCacheActor.valueLinkPreview(for: youtubeUrl) {
            return .success(cachedLinkPreview)
        }
        
        let parameters: Parameters = [
            "url": youtubeUrl,
            "format": "json"
        ]
        let result: Result<YoutubeLinkMetaData, Error> =
        try await APIManager
            .shared
            .request(MetaDataEndPoints.youtubeLinkMetaDataEndPoint,
                               method: .get,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let metaData):
            let linkPreview = metaData.toLinkPreview(youtubeUrl)
            await feedMediaCacheActor.storeLinkPreview(linkPreview, for: youtubeUrl)
            return .success(linkPreview)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func loadFileFromUrl(_ remoteUrl: URL) async throws -> Result<URL, any Error> {
        let fileName = remoteUrl.lastPathComponent
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return .success(destinationURL)
        }
        
        let data = try await AF.download(remoteUrl).serializingData().value
        
        try data.write(to: destinationURL)
        return .success(destinationURL)
    }
    
    func loadFileFromMediaId(_ mediaId: String) async throws -> Result<URL, any Error> {
        let mediaInfoResult = try await getPostMediaInfo(mediaId: mediaId, isPreview: false)
        switch mediaInfoResult {
        case .success(let mediaInfo):
            if let url = URL(string: mediaInfo.signedUrl) {
                return try await loadFileFromUrl(url)
            } else {
                return .failure(MediaLoadingError.invalidSignedURL)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum MetaDataEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let linkPreviewEndPoint = "\(hostURL)linkPreviews"
        static let feedMediaEndPoint = "\(hostURL)api/media"
        
        static let youtubeLinkMetaDataEndPoint = "https://www.youtube.com/oembed"
    }
}
