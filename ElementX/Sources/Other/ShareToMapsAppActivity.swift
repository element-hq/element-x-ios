//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CoreLocation
import UIKit

final class ShareToMapsAppActivity: UIActivity {
    enum MapsAppType: CaseIterable {
        case apple
        case google
        case osm
    }

    private let type: MapsAppType
    private let location: CLLocationCoordinate2D
    private let locationDescription: String?

    init(type: MapsAppType, location: CLLocationCoordinate2D, locationDescription: String?) {
        self.type = type
        self.location = location
        self.locationDescription = locationDescription
        super.init()
    }

    override private init() {
        fatalError()
    }

    override var activityTitle: String? {
        type.activityTitle
    }

    override var activityType: UIActivity.ActivityType {
        .shareToMapsApp
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        UIApplication.shared.open(type.activityURL(for: location, locationDescription: locationDescription), options: [:]) { [weak self] result in
            self?.activityDidFinish(result)
        }
    }
}

extension ShareToMapsAppActivity.MapsAppType {
    func activityURL(for location: CLLocationCoordinate2D, locationDescription: String?) -> URL {
        switch self {
        case .apple:
            var url: URL = "https://maps.apple.com/"
            url.append(queryItems: [
                .init(name: "ll", value: "\(location.latitude),\(location.longitude)"),
                .init(name: "q", value: locationDescription ?? "Pin")
            ])
            return url
        case .google:
            var url: URL = "https://www.google.com/maps/search/"
            url.append(queryItems: [
                .init(name: "api", value: "1"),
                .init(name: "query", value: "\(location.latitude),\(location.longitude)")
            ])
            return url
        case .osm:
            var url: URL = "https://www.openstreetmap.org/"
            url.append(queryItems: [
                .init(name: "mlat", value: "\(location.latitude)"),
                .init(name: "mlon", value: "\(location.longitude)")
            ])
            return url
        }
    }

    var activityTitle: String {
        switch self {
        case .apple:
            return L10n.screenShareOpenAppleMaps
        case .google:
            return L10n.screenShareOpenGoogleMaps
        case .osm:
            return L10n.screenShareOpenOsmMaps
        }
    }
}

private extension UIActivity.ActivityType {
    static let shareToMapsApp = UIActivity.ActivityType("ElementX.ShareToMapsApp")
}
