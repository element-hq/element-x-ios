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

struct MapLibreStaticMapView<PinAnnotation: View>: View {
    private let coordinates: CLLocationCoordinate2D
    private let zoomLevel: Double
    private let mapTilerStatic: MapTilerStaticMapProtocol
    private let mapTilerAttributionPlacement: MapTilerAttributionPlacement
    private let pinAnnotationView: PinAnnotation
    @Environment(\.colorScheme) private var colorScheme
    @State private var fetchAttempt = 0
    
    init(coordinates: CLLocationCoordinate2D,
         zoomLevel: Double,
         attributionPlacement: MapTilerAttributionPlacement,
         mapTilerStatic: MapTilerStaticMapProtocol,
         @ViewBuilder pinAnnotationView: () -> PinAnnotation) {
        self.coordinates = coordinates
        self.zoomLevel = zoomLevel
        self.mapTilerStatic = mapTilerStatic
        mapTilerAttributionPlacement = attributionPlacement
        self.pinAnnotationView = pinAnnotationView()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let url = mapTilerStatic.staticMapURL(for: colorScheme.mapStyle,
                                                     coordinates: coordinates,
                                                     zoomLevel: zoomLevel,
                                                     size: geometry.size,
                                                     attribution: mapTilerAttributionPlacement) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image("mapBlurred")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .success(let image):
                        ZStack {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                            pinAnnotationView
                        }
                    case .failure:
                        errorView
                    @unknown default:
                        EmptyView()
                    }
                }
                .id(fetchAttempt)
                .clipped()
            } else {
                Image("mapBlurred")
            }
        }
    }
    
    private var errorView: some View {
        Button {
            fetchAttempt += 1
        } label: {
            ZStack {
                Image("mapBlurred")
                VStack {
                    Image(systemName: "arrow.clockwise")
                    Text(L10n.actionStaticMapLoad)
                }
            }
        }
    }
}

private extension ColorScheme {
    var mapStyle: MapLibreStyle {
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
        MapLibreStaticMapView(coordinates: CLLocationCoordinate2D(),
                              zoomLevel: 15,
                              attributionPlacement: .bottomLeft,
                              mapTilerStatic: MapTilerStaticMapMock()) {
            Image(systemName: "mappin.circle.fill")
                .padding(.bottom, 35)
        }
    }
}

private struct MapTilerStaticMapMock: MapTilerStaticMapProtocol {
    func staticMapURL(for style: MapLibreStyle, coordinates: CLLocationCoordinate2D, zoomLevel: Double, size: CGSize, attribution: MapTilerAttributionPlacement) -> URL? {
        switch style {
        case .light:
            return URL(string: "https://www.maptiler.com/img/cloud/home/map5.webp")
        case .dark:
            return URL(string: "https://www.maptiler.com/img/cloud/home/map6.webp")
        }
    }
}
