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
        view.anchorPoint = annotation.anchorPoint
        addMarkerView(view)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func addMarkerView(_ markerView: UIView) {
        markerView.backgroundColor = .clear
        addSubview(markerView)
        markerView.bounds.size = markerView.intrinsicContentSize
    }
}
