//
//  ScreenshotDetectorTests.swift
//  UnitTests
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
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
                        guard let error = error else {
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
                    guard let error = error else {
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
