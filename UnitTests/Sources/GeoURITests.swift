//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
struct GeoURITests {
    @Test
    func validPositiveCoordinates() throws {
        let string = "geo:53.9980310155285,8.25347900390625;u=10.123"
        let uri = try #require(GeoURI(string: string))
        #expect(uri.latitude == 53.9980310155285)
        #expect(uri.longitude == 8.25347900390625)
        #expect(uri.uncertainty == 10.123)
        #expect(uri.string == string)
    }

    @Test
    func validNegativeCoordinates() throws {
        let string = "geo:-53.9980310155285,-8.25347900390625;u=10"
        let uri = try #require(GeoURI(string: string))
        #expect(uri.latitude == -53.9980310155285)
        #expect(uri.longitude == -8.25347900390625)
        #expect(uri.uncertainty == 10)
        #expect(uri.string == string)
    }

    @Test
    func validMixedCoordinates() throws {
        let string = "geo:53.9980310155285,-8.25347900390625;u=10"
        let uri = try #require(GeoURI(string: string))
        #expect(uri.latitude == 53.9980310155285)
        #expect(uri.longitude == -8.25347900390625)
        #expect(uri.uncertainty == 10)
        #expect(uri.string == string)
    }

    @Test
    func validCoordinatesNoUncertainty() throws {
        let string = "geo:53.9980310155285,-8.25347900390625"
        let uri = try #require(GeoURI(string: string))
        #expect(uri.latitude == 53.9980310155285)
        #expect(uri.longitude == -8.25347900390625)
        #expect(uri.uncertainty == nil)
        #expect(uri.string == string)
    }

    @Test
    func validIntegerCoordinates() throws {
        let string = "geo:53,-8;u=35"
        let uri = try #require(GeoURI(string: string))
        #expect(uri.latitude == 53)
        #expect(uri.longitude == -8)
        #expect(uri.uncertainty == 35)
        #expect(uri.string == "geo:53,-8;u=35")
    }

    @Test
    func formattingExponentialNotation() {
        let uri = GeoURI(latitude: 1e2, longitude: -1e-2, uncertainty: 1e-4)
        #expect(uri.string == "geo:100,-0.01;u=0.0001")
    }

    @Test
    func invalidURI1() {
        let string = "geo:53.99803101552848,-8.25347900390625;" // final ; without a u=number
        #expect(GeoURI(string: string) == nil)
    }

    @Test
    func invalidURI2() {
        let string = "geo:53.99803101552848, -8.25347900390625;" // spaces in the middle
        #expect(GeoURI(string: string) == nil)
    }

    @Test
    func invalidURI3() {
        let string = "geo:+53.99803101552848,-8.25347900390625" // '+' before a number
        #expect(GeoURI(string: string) == nil)
    }

    @Test
    func invalidURI4() {
        let string = "geo:53.99803101552848,-8.25347900390625;u=-20" // u is negative
        #expect(GeoURI(string: string) == nil)
    }
}
