//
//  ImageExtensionTests.swift
//  UnitTests
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import XCTest
@testable import ElementX

class ImageExtensionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func sampleScreenshot() throws -> UIImage {
        let bundle = Bundle(for: self.classForCoder)
        guard let path = bundle.path(forResource: "sample_screenshot", ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            throw XCTestError(.failureWhileWaiting)
        }
        return image
    }

    func testImageAnonymizationConfidenceLevel() async throws {
        let image = try sampleScreenshot()

        let anonymized5 = try await image.anonymized()
        let anonymized1 = try await image.anonymized(confidenceLevel: 0.1)

        //  comparing colors is a complicated process, just compare images for now
        XCTAssertNotEqual(image, anonymized5)
        XCTAssertNotEqual(anonymized1, anonymized5)
    }

    func testImageAnonymizationFillColor() async throws {
        let image = try sampleScreenshot()

        let anonymizedRed = try await image.anonymized()
        let anonymizedBlue = try await image.anonymized(fillColor: .blue)

        //  comparing colors is a complicated process, just compare images for now
        XCTAssertNotEqual(image, anonymizedRed)
        XCTAssertNotEqual(anonymizedBlue, anonymizedRed)
    }

}
