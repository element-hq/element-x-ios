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
import Foundation
import Photos
import XCTest

class ScreenshotDetectorTests: XCTestCase {
    @MainActor func testDetection() async {
        async { expectation in
            let detector = ScreenshotDetector()
            //  disable auto request authorization
            detector.autoRequestPHAuthorization = false
            detector.callback = { image, error in

                defer {
                    expectation.fulfill()
                }

                if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized {
                    //  if Photos already authorized on the simulator

                    if PHAsset.fetchLastScreenshot() != nil {
                        //  we should get an image
                        XCTAssertNotNil(image)

                        //  we should not get an error
                        XCTAssertNil(error)
                    } else {
                        //  otherwise we should not get an image
                        XCTAssertNil(image)

                        //  and get an error
                        guard let error else {
                            XCTFail("Should get an error")
                            return
                        }

                        switch error {
                        case ScreenshotDetectorError.loadFailed:
                            break
                        default:
                            XCTFail("Unknown error")
                        }
                    }
                } else {
                    //  otherwise we should not get an image
                    XCTAssertNil(image)

                    //  and get an error
                    guard let error else {
                        XCTFail("Should get an error")
                        return
                    }

                    switch error {
                    case ScreenshotDetectorError.notAuthorized:
                        break
                    default:
                        XCTFail("Unknown error")
                    }
                }
            }

            NotificationCenter.default.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        }
    }

    private func async(_ timeout: TimeInterval = 0.5, _ block: @escaping (XCTestExpectation) -> Void) {
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation(description: "Async operation expectation")
        block(expectation)
        waiter.wait(for: [expectation], timeout: timeout)
    }
}
