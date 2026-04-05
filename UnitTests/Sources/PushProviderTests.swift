//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

final class PushProviderTests: XCTestCase {
    private var appSettings: AppSettings {
        ServiceLocator.shared.settings
    }

    override func setUp() {
        AppSettings.resetAllSettings()
    }

    func test_pushProvider_encodeDecode_apns() throws {
        let original = PushProvider.apns
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PushProvider.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_pushProvider_encodeDecode_firebase() throws {
        let original = PushProvider.firebase
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PushProvider.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_pushProvider_defaultIsApns() {
        XCTAssertEqual(appSettings.pushProvider, .apns)
    }

    func test_pushProvider_persistsAfterChange() {
        appSettings.pushProvider = .apns
        XCTAssertEqual(appSettings.pushProvider, .apns)
    }
}
