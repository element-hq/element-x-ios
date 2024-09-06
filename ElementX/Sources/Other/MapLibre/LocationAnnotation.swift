//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Mapbox
import SwiftUI

final class LocationAnnotation: NSObject, MGLAnnotation {
    let coordinate: CLLocationCoordinate2D
    let anchorPoint: CGPoint
    let view: AnyView
    
    // MARK: - Setup
    
    init(coordinate: CLLocationCoordinate2D,
         anchorPoint: CGPoint = .init(x: 0.5, y: 0.5),
         @ViewBuilder label: () -> some View) {
        self.coordinate = coordinate
        self.anchorPoint = anchorPoint
        view = AnyView(label())
        super.init()
    }
}

final class LocationAnnotationView: MGLUserLocationAnnotationView {
    // MARK: - Setup
    
    override init(annotation: MGLAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
    }
    
    convenience init(annotation: LocationAnnotation) {
        self.init(annotation: annotation, reuseIdentifier: "\(Self.self)")
        let view: UIView = UIHostingController(rootView: annotation.view).view
        view.backgroundColor = .clear
        view.anchorPoint = annotation.anchorPoint
        addSubview(view)
        view.bounds.size = view.intrinsicContentSize
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
