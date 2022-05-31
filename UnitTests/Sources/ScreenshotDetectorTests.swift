//
//  ScreenshotDetectorTests.swift
//  UnitTests
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
@testable import ElementX
import XCTest

class ScreenshotDetectorTests: XCTestCase {

    func testDetection() {
        async { expectation in
            let detector = ScreenshotDetector()
            detector.callback = { _, _ in

                XCTAssert(Thread.isMainThread)

                expectation.fulfill()
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
