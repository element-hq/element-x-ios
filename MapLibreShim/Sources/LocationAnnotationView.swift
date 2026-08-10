//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MapInterface
import MapLibre
import SwiftUI

final class LocationAnnotationView: MLNUserLocationAnnotationView {
    private var hostingController: UIHostingController<AnyView>?

    // MARK: - Setup

    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
    }

    convenience init(annotation: MapAnnotation) {
        self.init(annotation: annotation, reuseIdentifier: "\(Self.self)")
        let hostingController = UIHostingController(rootView: annotation.makeContent())
        self.hostingController = hostingController
        let view: UIView = hostingController.view
        view.backgroundColor = .clear
        view.anchorPoint = .init(x: 0.5, y: 1.0)
        addSubview(view)
        view.bounds.size = view.intrinsicContentSize
    }

    func updateContent(with makeContent: () -> AnyView) {
        hostingController?.rootView = makeContent()
        if let hostedView = hostingController?.view {
            hostedView.bounds.size = hostedView.intrinsicContentSize
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
