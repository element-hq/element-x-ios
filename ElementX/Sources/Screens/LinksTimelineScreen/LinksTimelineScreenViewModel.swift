//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

typealias LinksTimelineScreenViewModelType = StateStoreViewModelV2<LinksTimelineScreenViewState, LinksTimelineScreenViewAction>

class LinksTimelineScreenViewModel: LinksTimelineScreenViewModelType, LinksTimelineScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var timelineItemProvider: TimelineItemProviderProtocol?
    
    private var actionsSubject: PassthroughSubject<LinksTimelineScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<LinksTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(roomTitle: roomProxy.infoPublisher.value.displayName ?? roomProxy.id),
                   mediaProvider: mediaProvider)
        
        setupTimeline()
    }
    
    override func process(viewAction: LinksTimelineScreenViewAction) {
        switch viewAction {
        case .openURL(let url):
            actionsSubject.send(.openURL(url))
        case .shareURL(let url):
            actionsSubject.send(.shareURL(url))
        case .navigateToMessage(let eventID):
            print("DEBUG: ViewModel received navigateToMessage action with eventID: \(eventID)")
            actionsSubject.send(.navigateToMessage(eventID: eventID))

        case .retry:
            setupTimeline()
        case .dismiss:
            print("DEBUG: ViewModel received dismiss action")
            actionsSubject.send(.dismiss)
        }
    }
    
    private func setupTimeline() {
        state.isLoading = true
        state.errorMessage = nil
        
        Task {
            await MainActor.run {
                self.timelineItemProvider = self.roomProxy.timeline.timelineItemProvider
                self.setupSubscriptions()
                self.extractLinksFromTimeline()
                self.state.isLoading = false
            }
        }
    }
    
    private func setupSubscriptions() {
        guard let timelineItemProvider = timelineItemProvider else { return }
        
        timelineItemProvider.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.extractLinksFromTimeline()
            }
            .store(in: &super.cancellables)
    }
    
    private func extractLinksFromTimeline() {
        guard let timelineItemProvider = timelineItemProvider else { return }
        
        var allLinks: [LinkItem] = []
        
        for item in timelineItemProvider.itemProxies {
            guard case let .event(eventItem) = item else { continue }
            
            // Check if it's a text message and extract body
            let body: String
            switch eventItem.content {
            case let .msgLike(messageLikeContent):
                switch messageLikeContent.kind {
                case let .message(messageContent):
                    switch messageContent.msgType {
                    case let .text(content):
                        body = content.body
                    case let .emote(content):
                        body = content.body
                    default:
                        continue
                    }
                default:
                    continue
                }
            default:
                continue
            }
            
            // Extract URLs from text content
            let urls = extractURLs(from: body)
            
            guard let firstURL = urls.first else { continue }
            
            let linkItem = LinkItem(url: firstURL,
                                    sender: eventItem.sender,
                                    timestamp: eventItem.timestamp,
                                    eventID: eventItem.id.eventID ?? String(eventItem.id.uniqueID.value),
                                    title: extractTitle(from: body, url: firstURL))
            
            allLinks.append(linkItem)
        }
        
        // Sort by timestamp (newest first)
        let sortedLinks = allLinks.sorted { $0.timestamp > $1.timestamp }
        
        // Store all links
        state.allLinks = sortedLinks
        state.links = sortedLinks
        
        state.isLoading = false
    }
    
    private func extractURLs(from text: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        return matches.compactMap { match in
            guard let url = match.url else { return nil }
            
            // If URL has no scheme, assume it's a website and add https://
            if url.scheme == nil {
                let urlString = url.absoluteString
                // Check if it looks like a domain (contains dot and no spaces)
                if urlString.contains("."), !urlString.contains(" ") {
                    return URL(string: "https://" + urlString)
                }
                return nil
            }
            
            // Filter out Matrix URIs and other non-http URLs
            guard url.scheme == "http" || url.scheme == "https" else { return nil }
            
            return url
        }
    }
    
    private func extractTitle(from text: String, url: URL) -> String? {
        // Try to extract a title from the text around the URL
        let urlString = url.absoluteString
        guard let range = text.range(of: urlString) else { return nil }
        
        let startIndex = text.startIndex
        let endIndex = text.endIndex
        
        // Get text before the URL (up to 50 characters)
        let beforeRange = startIndex..<range.lowerBound
        let beforeText = String(text[beforeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get text after the URL (up to 50 characters)
        let afterRange = range.upperBound..<endIndex
        let afterText = String(text[afterRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Combine and limit to reasonable length
        let combined = [beforeText, afterText].filter { !$0.isEmpty }.joined(separator: " ")
        
        if combined.count > 100 {
            return String(combined.prefix(100)) + "..."
        }
        
        return combined.isEmpty ? nil : combined
    }
}

// MARK: - Protocol

protocol LinksTimelineScreenViewModelProtocol: ObservableObject {
    var context: LinksTimelineScreenViewModelType.Context { get }
}
