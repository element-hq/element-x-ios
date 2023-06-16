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
import SwiftUI

struct MapLibreStaticMapView: View {
    let coordinates: CLLocationCoordinate2D
    let zoomLevel: Double
    let mapTilerStatic: MapTilerStaticMapProtocol
    @Environment(\.colorScheme) private var colorScheme
    
    @ScaledMetric var height: CGFloat = 150
    @ScaledMetric var width: CGFloat = 300
    
    var body: some View {
        if let url = mapTilerStatic.staticMapURL(for: colorScheme.mapStyle, coordinates: coordinates, zoomLevel: zoomLevel, size: .init(width: width, height: height)) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Color.red // Indicates an error.
                } else {
                    Color.blue // Acts as a placeholder.
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
    }
}

private extension ColorScheme {
    var mapStyle: MapTilerStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        @unknown default:
            return .light
        }
    }
}

struct MapLibreStaticMapView_Previews: PreviewProvider {
    static var previews: some View {
        MapLibreStaticMapView(coordinates: CLLocationCoordinate2D(latitude: 45, longitude: 7), zoomLevel: 15, mapTilerStatic: MapTilerStaticMapMock())
    }
}

struct MapTilerStaticMapMock: MapTilerStaticMapProtocol {
    func staticMapURL(for style: MapTilerStyle, coordinates: CLLocationCoordinate2D, zoomLevel: Double, size: CGSize) -> URL? {
        switch style {
        case .light:
            return URL(string: "https://www.maptiler.com/img/share/share-default.png")
        case .dark:
            return URL(string: "https://www.maptiler.com/media/2023-02-08-map-the-ocean-with-maptiler-1.jpg")
        }
    }
}
