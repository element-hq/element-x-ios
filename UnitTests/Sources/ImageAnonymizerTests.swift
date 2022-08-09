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

@testable import ElementX
import XCTest

enum ImageAnonymizerTestsError: String, Error {
    case screenshotNotFound
}

class ImageAnonymizerTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func sampleScreenshot() throws -> UIImage {
        let bundle = Bundle(for: classForCoder)
        guard let path = bundle.path(forResource: "sample_screenshot", ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            throw ImageAnonymizerTestsError.screenshotNotFound
        }
        return image
    }

    func testImageAnonymizationConfidenceLevel() async throws {
        let image = try sampleScreenshot()

        let anonymized5 = try await ImageAnonymizer.anonymizedImage(from: image)
        let anonymized1 = try await ImageAnonymizer.anonymizedImage(from: image, confidenceLevel: 0.1)

        //  comparing colors is a complicated process, just compare images for now
        XCTAssertNotEqual(image, anonymized5)
        XCTAssertNotEqual(anonymized1, anonymized5)
    }

    func testImageAnonymizationFillColor() async throws {
        let image = try sampleScreenshot()

        let anonymizedRed = try await ImageAnonymizer.anonymizedImage(from: image)
        let anonymizedBlue = try await ImageAnonymizer.anonymizedImage(from: image, fillColor: .blue)

        //  comparing colors is a complicated process, just compare images for now
        XCTAssertNotEqual(image, anonymizedRed)
        XCTAssertNotEqual(anonymizedBlue, anonymizedRed)
    }
}
