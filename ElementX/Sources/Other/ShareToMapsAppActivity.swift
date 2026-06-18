//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    private let senderName: String?
    
    init(type: MapsAppType, location: CLLocationCoordinate2D, senderName: String?) {
        self.type = type
        self.location = location
        self.senderName = senderName
        super.init()
    }
    
    override private nonisolated init() {
        fatalError()
    }
    
    override nonisolated var activityTitle: String? {
        type.activityTitle
    }
    
    override nonisolated var activityType: UIActivity.ActivityType {
        .shareToMapsApp
    }
    
    override nonisolated func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }
    
    override nonisolated func prepare(withActivityItems activityItems: [Any]) {
        // UIActivity isn't annotated but UIKit guarantees this is called on the main thread.
        MainActor.assumeIsolated {
            UIApplication.shared.open(type.activityURL(for: location, senderName: senderName), options: [:]) { [weak self] result in
                self?.activityDidFinish(result)
            }
        }
    }
}

nonisolated extension ShareToMapsAppActivity.MapsAppType {
    func activityURL(for location: CLLocationCoordinate2D, senderName: String?) -> URL {
        switch self {
        case .apple:
            var url: URL = "https://maps.apple.com/"
            url.append(queryItems: [
                .init(name: "ll", value: "\(location.latitude),\(location.longitude)"),
                .init(name: "q", value: senderName ?? "Pin") // We need to provide a value or no marker is displayed.
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

private nonisolated extension UIActivity.ActivityType {
    static let shareToMapsApp = UIActivity.ActivityType("ElementX.ShareToMapsApp")
}
