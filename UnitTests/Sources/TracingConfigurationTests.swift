//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

@testable import ElementX

class TracingConfigurationTests: XCTestCase {
    func testConfiguration() {
        let configuration = TracingConfiguration(overrides: [.common: .trace,
                                                             .matrix_sdk_base_sliding_sync: .error,
                                                             .matrix_sdk_http_client: .warn,
                                                             .matrix_sdk_crypto: .info,
                                                             .hyper: .debug])
        
        let filterComponents = configuration.filter.components(separatedBy: ",")
        XCTAssertEqual(filterComponents.first, "trace")
        XCTAssertTrue(filterComponents.contains("matrix_sdk_base::sliding_sync=error"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk::http_client=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_crypto=info"))
        XCTAssertTrue(filterComponents.contains("hyper=debug"))
    }
}
