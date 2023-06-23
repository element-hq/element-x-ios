//
// Copyright 2023 New Vector Ltd
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

final class GeoURITests: XCTestCase {
    func testValidPositiveCoordinates() throws {
        let string = "geo:53.99803101552848,8.25347900390625;u=10.0"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53.99803101552848)
        XCTAssertEqual(uri.longitude, 8.25347900390625)
        XCTAssertEqual(uri.uncertainty, 10)
        XCTAssertEqual(uri.string, string)
    }

    func testValidNegativeCoordinates() throws {
        let string = "geo:-53.99803101552848,-8.25347900390625;u=10.0"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, -53.99803101552848)
        XCTAssertEqual(uri.longitude, -8.25347900390625)
        XCTAssertEqual(uri.uncertainty, 10)
        XCTAssertEqual(uri.string, string)
    }

    func testValidMixedCoordinates() throws {
        let string = "geo:53.99803101552848,-8.25347900390625;u=10.0"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53.99803101552848)
        XCTAssertEqual(uri.longitude, -8.25347900390625)
        XCTAssertEqual(uri.uncertainty, 10)
        XCTAssertEqual(uri.string, string)
    }

    func testValidCoordinatesNoUncertainty() throws {
        let string = "geo:53.99803101552848,-8.25347900390625"
        let uri = try XCTUnwrap(GeoURI(string: string))
        XCTAssertEqual(uri.latitude, 53.99803101552848)
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
        XCTAssertEqual(uri.string, "geo:53.0,-8.0;u=35.0")
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
