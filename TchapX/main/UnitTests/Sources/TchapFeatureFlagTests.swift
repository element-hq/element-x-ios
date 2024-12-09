//
//  TchapFeatureFlagTests.swift
//  IntegrationTests
//
//  Created by Nicolas Buquet on 09/12/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import XCTest

@testable import TchapX_Development

final class TchapFeatureFlagTests: XCTestCase {
    func testFeatureFlags() {
        // Test for success
        XCTAssertTrue(TchapFeatureFlag(allowedInstances: [.agent]).isActivated(for: TchapFeatureFlag.Instance.agent.homeServer!))
        XCTAssertTrue(TchapFeatureFlag(allowedInstances: [.agent, .agriculture, .culture]).isActivated(for: TchapFeatureFlag.Instance.culture.homeServer!))
        XCTAssertTrue(TchapFeatureFlag(allowedInstances: [.all]).isActivated(for: TchapFeatureFlag.Instance.culture.homeServer!))
        XCTAssertTrue(TchapFeatureFlag(allowedInstances: [.agent, .all]).isActivated(for: TchapFeatureFlag.Instance.culture.homeServer!))
        XCTAssertTrue(TchapFeatureFlag(allowedInstances: [.agent]).isActivated(for: "matrix.agent.tchap.gouv.fr"))
        XCTAssertTrue(TchapFeatureFlag(allowedInstances: [.agent]).isActivated(for: "https://matrix.agent.tchap.gouv.fr"))
        // Test for failure
        XCTAssertFalse(TchapFeatureFlag(allowedInstances: [.agent]).isActivated(for: TchapFeatureFlag.Instance.agriculture.homeServer!))
        XCTAssertFalse(TchapFeatureFlag(allowedInstances: [.agent]).isActivated(for: ""))
        XCTAssertFalse(TchapFeatureFlag(allowedInstances: []).isActivated(for: TchapFeatureFlag.Instance.agent.homeServer!))
        XCTAssertFalse(TchapFeatureFlag(allowedInstances: [.agent]).isActivated(for: "http://matrix.agent.tchap.gouv.fr"))
    }
}
