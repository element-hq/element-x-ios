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
    func testReleaseConfiguration() {
        let filterComponents = TracingConfiguration.release.filter.components(separatedBy: ",")
        XCTAssertTrue(filterComponents.contains("info"))
        XCTAssertTrue(filterComponents.contains("hyper=warn"))
        XCTAssertTrue(filterComponents.contains("sled=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_sled=warn"))
    }
    
    func testDebugConfiguration() {
        let filterComponents = TracingConfiguration.debug.filter.components(separatedBy: ",")
        XCTAssertTrue(filterComponents.contains("warn"))
        XCTAssertTrue(filterComponents.contains("hyper=warn"))
        XCTAssertTrue(filterComponents.contains("sled=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_sled=warn"))
    }
    
    func testFullConfiguration() {
        let filterComponents = TracingConfiguration.full.filter.components(separatedBy: ",")
        XCTAssertTrue(filterComponents.contains("info"))
        XCTAssertTrue(filterComponents.contains("hyper=warn"))
        XCTAssertTrue(filterComponents.contains("sled=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_sled=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk::http_client=trace"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_ffi::uniffi_api=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_ffi=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk::sliding_sync=warn"))
        XCTAssertTrue(filterComponents.contains("matrix_sdk_base::sliding_sync=warn"))
    }
}
