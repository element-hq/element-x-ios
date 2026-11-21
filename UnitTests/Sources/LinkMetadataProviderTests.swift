//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct LinkMetadataProviderTests {
    private let url: URL = "https://element.io"
    private let clientProxy = ClientProxyMock(.init())
    private let userSettings = UserSettings.mock()
    
    @Test("Unencrypted rooms only ever use the homeserver while encrypted rooms follow their own setting")
    func roomModes() {
        let appSettings = userSettings.app
        #expect(LinkPreviewMode(isRoomEncrypted: false, appSettings: appSettings) == .off)
        #expect(LinkPreviewMode(isRoomEncrypted: true, appSettings: appSettings) == .off)
        
        appSettings.unencryptedRoomsLinkPreviewsEnabled = true
        appSettings.encryptedRoomsLinkPreviewsMode = .apple
        
        #expect(LinkPreviewMode(isRoomEncrypted: false, appSettings: appSettings) == .homeserver)
        #expect(LinkPreviewMode(isRoomEncrypted: true, appSettings: appSettings) == .apple)
    }
    
    @Test("The homeserver mode uses the homeserver preview")
    func homeserverMode() async throws {
        clientProxy.urlPreviewForReturnValue = .success(.init(title: "Element", imageURL: nil))
        
        let item = try await makeProvider().fetchMetadataFor(url: url, mode: .homeserver).get()
        
        #expect(item.metadata?.title == "Element")
        #expect(clientProxy.urlPreviewForCalled)
    }
    
    @Test("The Apple mode never shares the link with the homeserver")
    func appleMode() async {
        // The device fetch result doesn't matter, only that the homeserver isn't asked.
        _ = await makeProvider().fetchMetadataFor(url: "about:blank", mode: .apple)
        
        #expect(!clientProxy.urlPreviewForCalled)
    }
    
    @Test("A link without a homeserver preview isn't fetched again")
    func failureIsCached() async {
        clientProxy.urlPreviewForReturnValue = .failure(.urlPreviewUnavailable)
        let provider = makeProvider()
        
        _ = await provider.fetchMetadataFor(url: url, mode: .homeserver)
        _ = await provider.fetchMetadataFor(url: url, mode: .homeserver)
        
        #expect(clientProxy.urlPreviewForCallsCount == 1)
        #expect(provider.failedURLs.contains(url))
    }
    
    @Test("A cancelled fetch isn't remembered as a failure or a preview")
    func cancelledFetch() async {
        clientProxy.urlPreviewForClosure = { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return .success(.init(title: "Element", imageURL: nil))
        }
        let provider = makeProvider()
        
        let result = await Task { await provider.fetchMetadataFor(url: url, mode: .homeserver) }.value
        
        #expect(throws: CancellationError.self) { try result.get() }
        #expect(provider.metadataItems[url] == nil)
        #expect(!provider.failedURLs.contains(url))
    }
    
    @Test("An invalid preview image keeps the rest of the preview")
    func invalidImage() throws {
        let json = #"{"og:title": "Element", "og:image": ""}"#
        
        let preview = try JSONDecoder().decode(URLPreview.self, from: Data(json.utf8))
        
        #expect(preview.title == "Element")
        #expect(preview.imageURL == nil)
    }
    
    // MARK: - Helpers
    
    private func makeProvider() -> LinkMetadataProvider {
        LinkMetadataProvider(userSession: UserSessionMock(.init(clientProxy: clientProxy, userSettings: userSettings)))
    }
}
