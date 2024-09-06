//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class TracingConfigurationTests: XCTestCase {
    func testConfiguration() {
        let configuration = TracingConfiguration(logLevel: .trace, target: nil)
        
        let filterComponents = configuration.filter.components(separatedBy: ",")
        XCTAssertEqual(filterComponents.first, "info")
        XCTAssertTrue(filterComponents.contains("matrix_sdk_base::sliding_sync=trace"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk::http_client=debug"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_crypto=debug"))
        XCTAssertTrue(filterComponents.contains("hyper=warn"))
    }
}
