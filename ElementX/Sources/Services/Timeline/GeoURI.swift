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
struct GeoURI: Hashable {
    // MARK: - Properties

    let latitude: Double
    let longitude: Double
    let uncertainty: Double?

    // MARK: - Setup

    init?(string: String) {
        guard let parsedURI = Self.parseGeoURI(from: string) else {
            MXLog.warning("\(Self.self) failed to parse the string: \(string)")
            return nil
        }
        self = parsedURI
    }

    init(latitude: Double, longitude: Double, uncertainty: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.uncertainty = uncertainty
    }

    var string: String {
        if let uncertainty {
            return "geo:\(latitude),\(longitude);u=\(uncertainty)"
        } else {
            return "geo:\(latitude),\(longitude)"
        }
    }

    // MARK: - Private

    // Parse a geo URI string like "geo:53.99803101552848,-8.25347900390625;u=10"
    private static func parseGeoURI(from string: String) -> GeoURI? {
        guard
            let matchOutput = try? RegexGeoURI.standard.wholeMatch(in: string)?.output,
            let latitude = Double(matchOutput.latitude),
            let longitude = Double(matchOutput.longitude)
        else {
            return nil
        }

        let uncertainty = matchOutput.uncertainty.flatMap(Double.init)
        return .init(latitude: latitude, longitude: longitude, uncertainty: uncertainty)
    }
}

// swiftlint:disable:next large_tuple
private typealias RegexGeoURI = Regex<(Substring, latitude: Substring, longitude: Substring, uncertainty: Substring?)>

private extension RegexGeoURI {
    static let standard: Self = /geo:(?<latitude>-?\d+(?:\.\d+)?),(?<longitude>-?\d+(?:\.\d+)?)(?:;u=(?<uncertainty>\d+(?:\.\d+)?))?/
}
