//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation
import MapLibre
import SwiftUI

final class LocationAnnotation: NSObject, MLNAnnotation, Identifiable {
    let id: String
    var coordinate: CLLocationCoordinate2D
    var kind: LocationMarkerKind
    
    // MARK: - Setup
    
    init(id: String, coordinate: CLLocationCoordinate2D, kind: LocationMarkerKind) {
        self.id = id
        self.coordinate = coordinate
        self.kind = kind
        super.init()
    }
}

final class LocationAnnotationView: MLNUserLocationAnnotationView {
    private var hostingController: UIHostingController<AnyView>?
    
    // MARK: - Setup
    
    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
    }
    
    convenience init(annotation: LocationAnnotation, mediaProvider: MediaProviderProtocol?) {
        self.init(annotation: annotation, reuseIdentifier: "\(Self.self)")
        let markerView = LocationMarkerView(kind: annotation.kind, mediaProvider: mediaProvider)
        let hostingController = UIHostingController(rootView: AnyView(markerView))
        self.hostingController = hostingController
        let view: UIView = hostingController.view
        view.backgroundColor = .clear
        view.anchorPoint = .init(x: 0.5, y: 1.0)
        addSubview(view)
        view.bounds.size = view.intrinsicContentSize
    }
    
    func updateContent(with kind: LocationMarkerKind, mediaProvider: MediaProviderProtocol?) {
        let markerView = LocationMarkerView(kind: kind, mediaProvider: mediaProvider)
        hostingController?.rootView = AnyView(markerView)
        if let hostedView = hostingController?.view {
            hostedView.bounds.size = hostedView.intrinsicContentSize
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
