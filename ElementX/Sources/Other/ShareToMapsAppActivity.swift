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
    private let locationDescription: String

    init(type: MapsAppType, location: CLLocationCoordinate2D, locationDescription: String) {
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

    var activityCategory: UIActivity.Category {
        .action
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
    func activityURL(for location: CLLocationCoordinate2D, locationDescription: String) -> URL {
        switch self {
        case .apple:
            var url: URL = "https://maps.apple.com"
            url.append(queryItems: [
                .init(name: "ll", value: "\(location.latitude),\(location.longitude)"),
                .init(name: "q", value: locationDescription)
            ])
            return url
        case .google:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "https://www.google.com/maps/search/?api=1&query=\(location.latitude),\(location.longitude)")!
        case .osm:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "https://www.openstreetmap.org/?mlat=\(location.latitude)&mlon=\(location.longitude)")!
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
