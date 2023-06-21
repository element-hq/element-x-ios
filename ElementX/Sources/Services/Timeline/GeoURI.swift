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

import Foundation

/// A structure that parses a geo URI (i.e. geo:53.99803101552848,-8.25347900390625;u=10) and constructs their constituent parts.
struct GeoURI {
    // MARK: - Properties

    let latitude: Double
    let longitude: Double
    let uncertainty: Double?

    // MARK: - Setup

    init?(geoURI: String) {
        guard let parsedURI = Self.parseGeoURI(from: geoURI) else {
            return nil
        }
        self = parsedURI
    }

    init(latitude: Double, longitude: Double, uncertainty: Double?) {
        self.latitude = latitude
        self.longitude = longitude
        self.uncertainty = uncertainty
    }

    var geoURI: String {
        if let uncertainty {
            return "geo:\(latitude),\(longitude);u=\(uncertainty)"
        } else {
            return "geo:\(latitude),\(longitude)"
        }
    }

    // MARK: - Private

    // Parse a geo URI string like "geo:53.99803101552848,-8.25347900390625;u=10"
    private static func parseGeoURI(from geoURIString: String) -> GeoURI? {
        let matches = NSRegularExpression.geoURI.matches(in: geoURIString, range: geoURIString.nsRange)

        guard let match = matches.first else {
            return nil
        }

        var groups: [String] = []
        for rangeIndex in 1..<match.numberOfRanges {
            let range = match.range(at: rangeIndex)
            guard range.location != NSNotFound else {
                continue
            }
            let string = (geoURIString as NSString).substring(with: range)
            groups.append(string)
        }

        // index 0: latitude
        // index 1: longitude
        // index 2: uncertainty (if any)
        guard groups.count >= 2 else {
            return nil
        }

        guard
            let latitude = groups[safe: 0].flatMap(Double.init),
            let longitude = groups[safe: 1].flatMap(Double.init)
        else {
            return nil
        }

        let uncertainty = groups[safe: 2].flatMap(Double.init)

        return GeoURI(latitude: latitude, longitude: longitude, uncertainty: uncertainty)
    }
}

private extension NSRegularExpression {
    // swiftlint:disable:next force_try
    static let geoURI = try! NSRegularExpression(pattern: #"^geo:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)(?:;u=(-?\d+(?:\.\d+)?))?$"#, options: .anchorsMatchLines)
}

private extension String {
    var nsRange: NSRange {
        NSRange(location: 0, length: utf16.count)
    }
}
