//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

final class GeoURITests: XCTestCase {
    func testValidPositiveCoordinates() throws {
        let string = "geo:53.9980310155285,8.25347900390625;u=10.123"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53.9980310155285)
        XCTAssertEqual(uri.longitude, 8.25347900390625)
        XCTAssertEqual(uri.uncertainty, 10.123)
        XCTAssertEqual(uri.string, string)
    }

    func testValidNegativeCoordinates() throws {
        let string = "geo:-53.9980310155285,-8.25347900390625;u=10"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, -53.9980310155285)
        XCTAssertEqual(uri.longitude, -8.25347900390625)
        XCTAssertEqual(uri.uncertainty, 10)
        XCTAssertEqual(uri.string, string)
    }

    func testValidMixedCoordinates() throws {
        let string = "geo:53.9980310155285,-8.25347900390625;u=10"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53.9980310155285)
        XCTAssertEqual(uri.longitude, -8.25347900390625)
        XCTAssertEqual(uri.uncertainty, 10)
        XCTAssertEqual(uri.string, string)
    }

    func testValidCoordinatesNoUncertainty() throws {
        let string = "geo:53.9980310155285,-8.25347900390625"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53.9980310155285)
        XCTAssertEqual(uri.longitude, -8.25347900390625)
        XCTAssertNil(uri.uncertainty)
        XCTAssertEqual(uri.string, string)
    }

    func testValidIntegerCoordinates() throws {
        let string = "geo:53,-8;u=35"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53)
        XCTAssertEqual(uri.longitude, -8)
        XCTAssertEqual(uri.uncertainty, 35)
        XCTAssertEqual(uri.string, "geo:53,-8;u=35")
    }

    func testFormattingExponentialNotation() throws {
        let uri = GeoURI(latitude: 1e2, longitude: -1e-2, uncertainty: 1e-4)
        XCTAssertEqual(uri.string, "geo:100,-0.01;u=0.0001")
    }

    func testInvalidURI1() {
        let string = "geo:53.99803101552848,-8.25347900390625;" // final ; without a u=number
        XCTAssertNil(GeoURI(string: string))
    }

    func testInvalidURI2() {
        let string = "geo:53.99803101552848, -8.25347900390625;" // spaces in the middle
        XCTAssertNil(GeoURI(string: string))
    }

    func testInvalidURI3() {
        let string = "geo:+53.99803101552848,-8.25347900390625" // '+' before a number
        XCTAssertNil(GeoURI(string: string))
    }

    func testInvalidURI4() {
        let string = "geo:53.99803101552848,-8.25347900390625;u=-20" // u is negative
        XCTAssertNil(GeoURI(string: string))
    }
}
