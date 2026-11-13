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
    
    @Test("The homeserver mode uses the homeserver preview")
    func homeserverMode() async throws {
        userSettings.app.linkPreviewsMode = .homeserver
        clientProxy.urlPreviewForReturnValue = .success(.init(title: "Element", imageURL: nil))
        
        let item = try await makeProvider().fetchMetadataFor(url: url).get()
        
        #expect(item.metadata?.title == "Element")
        #expect(clientProxy.urlPreviewForCalled)
    }
    
    @Test("The Apple mode never shares the link with the homeserver")
    func appleMode() async {
        userSettings.app.linkPreviewsMode = .apple
        
        // The device fetch result doesn't matter, only that the homeserver isn't asked.
        _ = await makeProvider().fetchMetadataFor(url: "about:blank")
        
        #expect(!clientProxy.urlPreviewForCalled)
    }
    
    // MARK: - Helpers
    
    private func makeProvider() -> LinkMetadataProvider {
        LinkMetadataProvider(userSession: UserSessionMock(.init(clientProxy: clientProxy, userSettings: userSettings)))
    }
}
