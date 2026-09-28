//
// Copyright 2026 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import MapLibre
import MapLibreInterface
import SwiftUI

final class MapLibreAnnotation: NSObject, MLNAnnotation, Identifiable {
    let id: String
    // @objc dynamic is required to make animations work
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    // MARK: - Setup
    
    init(_ annotation: MapAnnotation) {
        id = annotation.id
        coordinate = annotation.coordinate
        super.init()
    }
}

final class MapLibreAnnotationView: MLNUserLocationAnnotationView {
    private var hostingController: UIHostingController<AnyView>?
    
    // MARK: - Setup
    
    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
    }
    
    convenience init(annotation: MapLibreAnnotation, content: AnyView?) {
        self.init(annotation: annotation, reuseIdentifier: "\(Self.self)")
        let hostingController = UIHostingController(rootView: content ?? AnyView(EmptyView()))
        self.hostingController = hostingController
        let view: UIView = hostingController.view
        view.backgroundColor = .clear
        view.anchorPoint = .init(x: 0.5, y: 1.0)
        addSubview(view)
        view.bounds.size = view.intrinsicContentSize
    }
    
    func updateContent(_ content: AnyView?) {
        hostingController?.rootView = content ?? AnyView(EmptyView())
        if let hostedView = hostingController?.view {
            hostedView.bounds.size = hostedView.intrinsicContentSize
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
