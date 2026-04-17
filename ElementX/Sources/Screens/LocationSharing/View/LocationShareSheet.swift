//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import SwiftUI

struct LocationShareSheet: View {
    let annotation: LocationAnnotation
    
    private var location: CLLocationCoordinate2D {
        annotation.coordinate
    }
    
    private var senderName: String? {
        annotation.kind.displayName ?? annotation.kind.userProfile?.userID
    }
    
    var body: some View {
        AppActivityView(activityItems: [ShareToMapsAppActivity.MapsAppType.apple.activityURL(for: location, senderName: senderName)],
                        applicationActivities: ShareToMapsAppActivity.MapsAppType.allCases.map { ShareToMapsAppActivity(type: $0, location: location, senderName: senderName) })
            .ignoresSafeArea(edges: .bottom)
            .presentationDetents([.medium, .large])
            .presentationCompactAdaptation(compactPresentation)
            .presentationDragIndicator(.hidden)
    }
    
    private var compactPresentation: PresentationAdaptation {
        if #available(iOS 26.0, *) {
            .none // ShareLinks use a popover presentation on iOS 26, let it match that.
        } else {
            .sheet
        }
    }
}

// MARK: - Previews

struct LocationShareSheet_Previews: PreviewProvider {
    static let profile = UserProfileProxy(userID: "@alice:example.com", displayName: "Alice")
    static let annotation = LocationAnnotation(id: profile.userID,
                                               coordinate: .init(latitude: 51.509865, longitude: -0.118092),
                                               kind: .liveUser(profile))

    static var previews: some View {
        LocationShareSheet(annotation: annotation)
            .previewDisplayName("Live location share sheet")
    }
}
