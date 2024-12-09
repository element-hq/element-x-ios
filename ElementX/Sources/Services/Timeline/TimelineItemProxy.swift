//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A light wrapper around timeline items returned from Rust.
enum TimelineItemProxy {
    case event(EventTimelineItemProxy)
    case virtual(MatrixRustSDK.VirtualTimelineItem, uniqueID: TimelineUniqueId)
    case unknown(MatrixRustSDK.TimelineItem)
    
    init(item: MatrixRustSDK.TimelineItem) {
        if let eventItem = item.asEvent() {
            self = .event(EventTimelineItemProxy(item: eventItem, uniqueID: item.uniqueId()))
        } else if let virtualItem = item.asVirtual() {
            self = .virtual(virtualItem, uniqueID: item.uniqueId())
        } else {
            self = .unknown(item)
        }
    }
    
    var isEvent: Bool {
        switch self {
        case .event:
            return true
        default:
            return false
        }
    }
}

/// The delivery status for the item.
enum TimelineItemDeliveryStatus: Hashable {
    case sending
    case sent
    case sendingFailed(TimelineItemSendFailure)
    
    var isSendingFailed: Bool {
        switch self {
        case .sending, .sent: false
        case .sendingFailed: true
        }
    }
}

/// The reason a timeline item failed to send.
enum TimelineItemSendFailure: Hashable {
    enum VerifiedUser: Hashable {
        case hasUnsignedDevice(devices: [String: [String]])
        case changedIdentity(users: [String])
        
        var affectedUserIDs: [String] {
            switch self {
            case .hasUnsignedDevice(let devices): Array(devices.keys)
            case .changedIdentity(let users): users
            }
        }
    }
    
    case verifiedUser(VerifiedUser)
    case unknown
}

/// A light wrapper around event timeline items returned from Rust.
class EventTimelineItemProxy {
    let item: MatrixRustSDK.EventTimelineItem
    let id: TimelineItemIdentifier
    
    init(item: MatrixRustSDK.EventTimelineItem, uniqueID: TimelineUniqueId) {
        self.item = item
        
        id = .event(uniqueID: uniqueID, eventOrTransactionID: item.eventOrTransactionId)
    }
    
    lazy var deliveryStatus: TimelineItemDeliveryStatus? = {
        guard let localSendState = item.localSendState else {
            return nil
        }
        
        switch localSendState {
        case .sendingFailed(let error, let isRecoverable):
            switch error {
            case .identityViolations(let users):
                return .sendingFailed(.verifiedUser(.changedIdentity(users: users)))
            case .insecureDevices(let userDeviceMap):
                return .sendingFailed(.verifiedUser(.hasUnsignedDevice(devices: userDeviceMap)))
            default:
                return .sendingFailed(.unknown)
            }
        case .notSentYet:
            return .sending
        case .sent:
            return .sent
        }
    }()
    
    lazy var canBeRepliedTo = item.canBeRepliedTo
            
    lazy var content = item.content

    lazy var isOwn = item.isOwn

    lazy var isEditable = item.isEditable
    
    lazy var sender: TimelineItemSender = {
        let profile = item.senderProfile
        
        switch profile {
        case let .ready(displayName, isDisplayNameAmbiguous, avatarUrl):
            return .init(id: item.sender,
                         displayName: displayName,
                         isDisplayNameAmbiguous: isDisplayNameAmbiguous,
                         avatarURL: avatarUrl.flatMap(URL.init(string:)))
        default:
            return .init(id: item.sender,
                         displayName: nil,
                         isDisplayNameAmbiguous: false,
                         avatarURL: nil)
        }
    }()

    lazy var reactions = item.reactions
    
    lazy var timestamp = Date(timeIntervalSince1970: TimeInterval(item.timestamp / 1000))
    
    lazy var debugInfo: TimelineItemDebugInfo = {
        let debugInfo = item.lazyProvider.debugInfo()
        return TimelineItemDebugInfo(model: debugInfo.model, originalJSON: debugInfo.originalJson, latestEditJSON: debugInfo.latestEditJson)
    }()
    
    lazy var shieldState = item.lazyProvider.getShields(strict: false)
    
    lazy var sendHandle = item.lazyProvider.getSendHandle()
    
    lazy var readReceipts = item.readReceipts
}

struct TimelineItemDebugInfo: Identifiable, CustomStringConvertible {
    let id = UUID()
    let model: String
    let originalJSON: String?
    let latestEditJSON: String?
    
    init(model: String, originalJSON: String?, latestEditJSON: String?) {
        self.model = model
        
        self.originalJSON = Self.prettyJsonFormattedString(from: originalJSON)
        self.latestEditJSON = Self.prettyJsonFormattedString(from: latestEditJSON)
    }
    
    var description: String {
        var description = model
        
        if let originalJSON {
            description += "\n\n\(originalJSON)"
        }
        
        if let latestEditJSON {
            description += "\n\n\(latestEditJSON)"
        }
        
        return description
    }
    
    // MARK: - Private
    
    private static func prettyJsonFormattedString(from string: String?) -> String? {
        guard let string,
              let data = string.data(using: .utf8),
              let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let jsonData = try? JSONSerialization.data(withJSONObject: jsonDictionary, options: [.prettyPrinted]) else {
            return nil
        }
        
        return String(data: jsonData, encoding: .utf8)
    }
}

struct SendHandleProxy: Hashable {
    enum Error: Swift.Error {
        case sdkError(Swift.Error)
    }
    
    let itemID: TimelineItemIdentifier
    let underlyingHandle: SendHandle
    
    func resend() async -> Result<Void, Error> {
        do {
            try await underlyingHandle.tryResend()
            return .success(())
        } catch {
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Hashable

    static func == (lhs: SendHandleProxy, rhs: SendHandleProxy) -> Bool {
        lhs.itemID == rhs.itemID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(itemID)
    }
    
    static var mock: SendHandleProxy {
        .init(itemID: .event(uniqueID: .init(id: UUID().uuidString),
                             eventOrTransactionID: .eventId(eventId: UUID().uuidString)),
              underlyingHandle: .init(noPointer: .init()))
    }
}

struct VideoInfoProxy: Hashable {
    let source: MediaSourceProxy
    private(set) var duration: TimeInterval
    private(set) var size: CGSize?
    private(set) var aspectRatio: CGFloat?
    private(set) var mimeType: String?
    private(set) var fileSize: UInt?
    
    init(source: MediaSource, duration: TimeInterval, width: UInt64?, height: UInt64?, mimeType: String?, fileSize: UInt?) {
        self.source = MediaSourceProxy(source: source, mimeType: mimeType)
        self.duration = duration
        
        let mediaInfo = MediaInfoProxy(width: width, height: height, mimeType: mimeType)
        size = mediaInfo.size
        aspectRatio = mediaInfo.aspectRatio
        self.mimeType = mediaInfo.mimeType
        self.fileSize = fileSize
    }
    
    // MARK: - Mocks
    
    private init(source: MediaSourceProxy, duration: TimeInterval, size: CGSize?, aspectRatio: CGFloat?, mimeType: String?, fileSize: UInt?) {
        self.source = source
        self.duration = duration
        self.size = size
        self.aspectRatio = aspectRatio
        self.mimeType = mimeType
        self.fileSize = fileSize
    }
    
    static var mockVideo: VideoInfoProxy {
        guard let mediaSource = try? MediaSourceProxy(url: .mockMXCVideo, mimeType: nil) else {
            fatalError("Invalid mock media source URL")
        }
        
        return .init(source: mediaSource,
                     duration: 100,
                     size: .init(width: 1920, height: 1080),
                     aspectRatio: 1.78,
                     mimeType: nil,
                     fileSize: 45_167_000)
    }
}

struct ImageInfoProxy: Hashable {
    let source: MediaSourceProxy
    private(set) var size: CGSize?
    private(set) var aspectRatio: CGFloat?
    private(set) var mimeType: String?
    private(set) var fileSize: UInt?
    
    init?(source: MediaSource?, width: UInt64?, height: UInt64?, mimeType: String?, fileSize: UInt?) {
        guard let source else {
            return nil
        }
        
        self.init(source: .init(source: source, mimeType: mimeType), width: width, height: height, mimeType: mimeType, fileSize: fileSize)
    }
    
    init(source: MediaSource, width: UInt64?, height: UInt64?, mimeType: String?, fileSize: UInt?) {
        self.init(source: .init(source: source, mimeType: mimeType), width: width, height: height, mimeType: mimeType, fileSize: fileSize)
    }
    
    init(source: MediaSourceProxy, width: UInt64?, height: UInt64?, mimeType: String?, fileSize: UInt?) {
        self.source = source
        
        let mediaInfo = MediaInfoProxy(width: width, height: height, mimeType: mimeType)
        size = mediaInfo.size
        aspectRatio = mediaInfo.aspectRatio
        self.mimeType = mediaInfo.mimeType
        self.fileSize = fileSize
    }
    
    // MARK: - Mocks
    
    private init(source: MediaSourceProxy, size: CGSize?, aspectRatio: CGFloat?, fileSize: UInt?) {
        self.source = source
        self.size = size
        self.aspectRatio = aspectRatio
        mimeType = source.mimeType
        self.fileSize = fileSize
    }
    
    static var mockImage: ImageInfoProxy {
        guard let mediaSource = try? MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpg") else {
            fatalError("Invalid mock media source URL")
        }
        
        return .init(source: mediaSource, size: .init(width: 2730, height: 2048), aspectRatio: 4 / 3, fileSize: 717_000)
    }
    
    static var mockThumbnail: ImageInfoProxy {
        guard let mediaSource = try? MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpg") else {
            fatalError("Invalid mock media source URL")
        }
        
        return .init(source: mediaSource, size: .init(width: 800, height: 600), aspectRatio: 4 / 3, fileSize: 84000)
    }
    
    static var mockVideoThumbnail: ImageInfoProxy {
        guard let mediaSource = try? MediaSourceProxy(url: .mockMXCVideo, mimeType: "image/jpg") else {
            fatalError("Invalid mock media source URL")
        }
        
        return .init(source: mediaSource, size: .init(width: 800, height: 450), aspectRatio: 16 / 9, fileSize: 98000)
    }
}

private struct MediaInfoProxy: Hashable {
    private(set) var size: CGSize?
    private(set) var mimeType: String?
    private(set) var aspectRatio: CGFloat?
    
    init(width: UInt64?, height: UInt64?, mimeType: String?) {
        if let width, let height {
            size = .init(width: CGFloat(width), height: CGFloat(height))
            
            if width > 0, height > 0 {
                aspectRatio = CGFloat(width) / CGFloat(height)
            }
        }
        
        self.mimeType = mimeType
    }
}
