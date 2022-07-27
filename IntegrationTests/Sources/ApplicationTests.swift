//
//  ApplicationTests.swift
//  IntegrationTests
//
//  Created by Stefan Ceriu on 27/07/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest

class ApplicationTests: XCTestCase {
    func testLaunchPerformance() throws {
        let parser = XCTestMeasurementParser()
        
        parser.capture(testCase: self) {
            self.measure(metrics: [XCTApplicationLaunchMetric()]) {
                Application.launch()
            }
        }
        
        guard let actualDuration = parser.valueForMetric(.appLaunch) else {
            XCTFail("Couldn't retrieve app launch duration")
            return
        }
        
        let expectedDuration = 2.75
        
        XCTAssert(actualDuration <= expectedDuration, "App launch duration: \(actualDuration) greater than expected: \(expectedDuration)")
    }
}
