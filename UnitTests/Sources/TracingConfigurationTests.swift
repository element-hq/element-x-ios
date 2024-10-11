//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

class TracingConfigurationTests: XCTestCase {
    func testConfiguration() { // swiftlint:disable line_length
        var filter = TracingConfiguration(logLevel: .error, currentTarget: "tests", filePrefix: nil).filter
        
        XCTAssertEqual(filter, "hyper=warn,matrix_sdk_ffi=info,matrix_sdk::client=trace,matrix_sdk_crypto=debug,matrix_sdk_crypto::olm::account=trace,matrix_sdk::oidc=trace,matrix_sdk::http_client=debug,matrix_sdk::sliding_sync=info,matrix_sdk_base::sliding_sync=info,matrix_sdk_ui::timeline=info,tests=error")
        
        filter = TracingConfiguration(logLevel: .warn, currentTarget: "tests", filePrefix: nil).filter
        
        XCTAssertEqual(filter, "hyper=warn,matrix_sdk_ffi=info,matrix_sdk::client=trace,matrix_sdk_crypto=debug,matrix_sdk_crypto::olm::account=trace,matrix_sdk::oidc=trace,matrix_sdk::http_client=debug,matrix_sdk::sliding_sync=info,matrix_sdk_base::sliding_sync=info,matrix_sdk_ui::timeline=info,tests=warn")
        
        filter = TracingConfiguration(logLevel: .info, currentTarget: "tests", filePrefix: nil).filter
        
        XCTAssertEqual(filter, "hyper=warn,matrix_sdk_ffi=info,matrix_sdk::client=trace,matrix_sdk_crypto=debug,matrix_sdk_crypto::olm::account=trace,matrix_sdk::oidc=trace,matrix_sdk::http_client=debug,matrix_sdk::sliding_sync=info,matrix_sdk_base::sliding_sync=info,matrix_sdk_ui::timeline=info,tests=info")
        
        filter = TracingConfiguration(logLevel: .debug, currentTarget: "tests", filePrefix: nil).filter
        
        XCTAssertEqual(filter, "hyper=warn,matrix_sdk_ffi=debug,matrix_sdk::client=trace,matrix_sdk_crypto=debug,matrix_sdk_crypto::olm::account=trace,matrix_sdk::oidc=trace,matrix_sdk::http_client=debug,matrix_sdk::sliding_sync=debug,matrix_sdk_base::sliding_sync=debug,matrix_sdk_ui::timeline=debug,tests=debug")
        
        filter = TracingConfiguration(logLevel: .trace, currentTarget: "tests", filePrefix: nil).filter
        
        XCTAssertEqual(filter, "hyper=warn,matrix_sdk_ffi=trace,matrix_sdk::client=trace,matrix_sdk_crypto=trace,matrix_sdk_crypto::olm::account=trace,matrix_sdk::oidc=trace,matrix_sdk::http_client=trace,matrix_sdk::sliding_sync=trace,matrix_sdk_base::sliding_sync=trace,matrix_sdk_ui::timeline=trace,tests=trace")
    } // swiftlint:enable line_length
    
    func testLevelOrdering() {
        var logLevels: [TracingConfiguration.LogLevel] = [.info, .error, .trace, .debug, .warn]
        
        XCTAssertEqual(logLevels.sorted(), [.error, .warn, .info, .debug, .trace])
        
        logLevels = [.warn, .error, .debug, .trace, .info, .error]
        
        XCTAssertEqual(logLevels.sorted(), [.error, .error, .warn, .info, .debug, .trace])
    }
}
