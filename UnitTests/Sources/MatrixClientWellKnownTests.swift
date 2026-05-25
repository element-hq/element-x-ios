//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDKMocks
import Testing

/// Exercises ``ClientProtocol/updateMapTilerSettings(in:)``. The SDK is now the
/// source of truth for parsing the matrix client well-known and exposing the
/// `tile_server` field as a typed ``TileServerInfo``; these tests just check
/// that we forward it into ``AppSettings`` correctly.
struct MatrixClientWellKnownTests {
    private static let mapStyleURLString = "https://maps.example.com/maps/streets-v2/style.json?key=server"

    @Test
    func mapStyleURLIsApplied() async throws {
        let appSettings = AppSettings.volatile()
        let client = ClientSDKMock(.init(tileServerMapStyleURL: Self.mapStyleURLString))

        await client.updateMapTilerSettings(in: appSettings)

        #expect(appSettings.mapTilerSettings.isRemotelyConfigured)
        let expectedURL = try #require(URL(string: Self.mapStyleURLString))
        #expect(appSettings.mapTilerSettings.publisher.value == .url(expectedURL))
    }

    @Test
    func missingTileServerClearsExistingOverride() async throws {
        let appSettings = AppSettings.volatile()
        let expectedURL = try #require(URL(string: Self.mapStyleURLString))
        appSettings.mapTilerSettings.applyRemoteValue(.url(expectedURL))
        #expect(appSettings.mapTilerSettings.isRemotelyConfigured)

        // The SDK returns nil when the homeserver hasn't advertised a tile server.
        let client = ClientSDKMock(.init())
        await client.updateMapTilerSettings(in: appSettings)

        #expect(!appSettings.mapTilerSettings.isRemotelyConfigured)
    }

    @Test
    func invalidMapStyleURLClearsOverride() async throws {
        let appSettings = AppSettings.volatile()
        let expectedURL = try #require(URL(string: Self.mapStyleURLString))
        appSettings.mapTilerSettings.applyRemoteValue(.url(expectedURL))

        // The SDK returns the string verbatim — if it isn't a valid URL we just
        // drop any previous override rather than crash.
        let client = ClientSDKMock(.init(tileServerMapStyleURL: ""))
        await client.updateMapTilerSettings(in: appSettings)

        #expect(!appSettings.mapTilerSettings.isRemotelyConfigured)
    }

    @Test
    func mapTilerSettingsResolveToOverride() async {
        let appSettings = AppSettings.volatile()
        let client = ClientSDKMock(.init(tileServerMapStyleURL: Self.mapStyleURLString))

        await client.updateMapTilerSettings(in: appSettings)

        switch appSettings.mapTilerSettings.publisher.value {
        case .url(let url):
            #expect(url.absoluteString == Self.mapStyleURLString)
        case .configuration:
            Issue.record("Expected the resolved settings to be .url")
        }
    }
}
