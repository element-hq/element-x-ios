//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CoreLocation
import Foundation

/// A structure that parses a geo URI (i.e. geo:53.99803101552848,-8.25347900390625;u=10) and constructs their constituent parts.
struct GeoURI: Hashable {
    // MARK: - Properties

    let latitude: Double
    let longitude: Double
    let uncertainty: Double?
    
    var bodyMessage: String {
        "Location was shared at \(string)"
    }

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
            return "geo:\(string(for: latitude)),\(string(for: longitude));u=\(string(for: uncertainty))"
        } else {
            return "geo:\(string(for: latitude)),\(string(for: longitude))"
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

    private func string(for number: Double) -> String {
        NumberFormatter.decimal.string(from: .init(floatLiteral: number)) ?? "\(number)"
    }
}

// swiftlint:disable:next large_tuple
private typealias RegexGeoURI = Regex<(Substring, latitude: Substring, longitude: Substring, uncertainty: Substring?)>

private extension RegexGeoURI {
    static let standard: Self = /geo:(?<latitude>-?\d+(?:\.\d+)?),(?<longitude>-?\d+(?:\.\d+)?)(?:;u=(?<uncertainty>\d+(?:\.\d+)?))?/
}

extension GeoURI {
    init(coordinate: CLLocationCoordinate2D, uncertainty: CLLocationAccuracy?) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, uncertainty: uncertainty)
    }
}

private extension NumberFormatter {
    static let decimal: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 30
        return numberFormatter
    }()
}
