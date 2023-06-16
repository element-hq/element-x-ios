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

/// Base class to handle a map annotation
class LocationAnnotation: NSObject, MGLAnnotation {
    // MARK: - Properties
    
    // Title property is needed to enable annotation selection and callout view showing
    var title: String?
    
    let coordinate: CLLocationCoordinate2D
    
    // MARK: - Setup
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

/// POI map annotation
class PinLocationAnnotation: LocationAnnotation { }

class LocationAnnotationView: MGLUserLocationAnnotationView {
    private enum Constants {
        static let defaultFrame = CGRect(x: 0, y: 0, width: 46, height: 46)
    }
    
    // MARK: - Setup
    
    override init(annotation: MGLAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
        frame = Constants.defaultFrame
    }
    
    convenience init(userPinLocationAnnotation: MGLAnnotation) {
        self.init(annotation: userPinLocationAnnotation, reuseIdentifier: "userPinLocation")
        
        addUserView()
    }
    
    convenience init(pinLocationAnnotation: PinLocationAnnotation) {
        self.init(annotation: pinLocationAnnotation, reuseIdentifier: nil)
        
        addPinView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func addUserView() {
        guard let pinView = UIHostingController(rootView: Image(systemName: "circle.fill")
            .resizable()
            .foregroundColor(.compound.iconPrimary)).view else {
            return
        }
        
        addMarkerView(pinView)
    }
    
    private func addPinView() {
        guard let pinView = UIHostingController(rootView: Image(systemName: "mappin")
            .resizable()
            .foregroundColor(.compound.iconPrimary)).view else {
            return
        }
        
        addMarkerView(pinView)
    }
    
    private func addMarkerView(_ markerView: UIView) {
        markerView.backgroundColor = .clear
        
        addSubview(markerView)
        
        markerView.frame = bounds
    }
}
