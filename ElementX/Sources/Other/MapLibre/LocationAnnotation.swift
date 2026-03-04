//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MapLibre
import SwiftUI

final class LocationAnnotation: NSObject, MLNAnnotation {
    let id: String
    var coordinate: CLLocationCoordinate2D
    let anchorPoint: CGPoint
    var view: AnyView
    
    // MARK: - Setup
    
    init(id: String = UUID().uuidString,
         coordinate: CLLocationCoordinate2D,
         anchorPoint: CGPoint = .init(x: 0.5, y: 0.5),
         @ViewBuilder label: () -> some View) {
        self.id = id
        self.coordinate = coordinate
        self.anchorPoint = anchorPoint
        view = AnyView(label())
        super.init()
    }
    
    func updateView(@ViewBuilder label: () -> some View) {
        view = AnyView(label())
    }
}

final class LocationAnnotationView: MLNUserLocationAnnotationView {
    private var hostingController: UIHostingController<AnyView>?
    
    // MARK: - Setup
    
    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
    }
    
    convenience init(annotation: LocationAnnotation) {
        self.init(annotation: annotation, reuseIdentifier: "\(Self.self)")
        let hostingController = UIHostingController(rootView: annotation.view)
        self.hostingController = hostingController
        let view: UIView = hostingController.view
        view.backgroundColor = .clear
        view.anchorPoint = annotation.anchorPoint
        addSubview(view)
        view.bounds.size = view.intrinsicContentSize
    }
        
    func updateContent(with view: AnyView) {
        hostingController?.rootView = view
        if let hostedView = hostingController?.view {
            hostedView.bounds.size = hostedView.intrinsicContentSize
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
