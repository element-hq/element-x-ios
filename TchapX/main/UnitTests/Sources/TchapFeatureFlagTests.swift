/*
 * MIT License
 *
 * Copyright (c) 2024. DINUM
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
