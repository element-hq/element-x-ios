//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CoreLocation
import SwiftUI

struct MapLibreStaticMapView<PinAnnotation: View>: View {
    private let coordinates: CLLocationCoordinate2D
    private let zoomLevel: Double
    private let mapTilerStatic: MapTilerStaticMapProtocol
    private let mapTilerAttributionPlacement: MapTilerAttributionPlacement
    private let mapSize: CGSize
    private let pinAnnotationView: PinAnnotation

    @Environment(\.colorScheme) private var colorScheme
    @State private var fetchAttempt = 0
    
    init(coordinates: CLLocationCoordinate2D,
         zoomLevel: Double,
         attributionPlacement: MapTilerAttributionPlacement,
         mapTilerStatic: MapTilerStaticMapProtocol,
         mapSize: CGSize,
         @ViewBuilder pinAnnotationView: () -> PinAnnotation) {
        self.coordinates = coordinates
        self.zoomLevel = zoomLevel
        self.mapTilerStatic = mapTilerStatic
        mapTilerAttributionPlacement = attributionPlacement
        self.mapSize = mapSize
        self.pinAnnotationView = pinAnnotationView()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let url = mapTilerStatic.staticMapURL(for: colorScheme.mapStyle,
                                                     coordinates: coordinates,
                                                     zoomLevel: zoomLevel,
                                                     size: mapSize, // temporary using a fixed size since the refresh doesn't work properly on the UITableView based timeline
                                                     attribution: mapTilerAttributionPlacement) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderImage
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
                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                .id(fetchAttempt)
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Image("mapBlurred")
            .resizable()
            .scaledToFill()
    }

    private var errorView: some View {
        Button {
            fetchAttempt += 1
        } label: {
            placeholderImage
                .overlay {
                    VStack(spacing: 0) {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.actionStaticMapLoad)
                    }
                }
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

struct MapLibreStaticMapView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        MapLibreStaticMapView(coordinates: CLLocationCoordinate2D(),
                              zoomLevel: 15,
                              attributionPlacement: .bottomLeft,
                              mapTilerStatic: MapTilerStaticMapMock(), mapSize: .init(width: 300, height: 200)) {
            Image(systemName: "mappin.circle.fill")
                .padding(.bottom, 35)
        }
    }
}

private struct MapTilerStaticMapMock: MapTilerStaticMapProtocol {
    func staticMapURL(for style: MapTilerStyle, coordinates: CLLocationCoordinate2D, zoomLevel: Double, size: CGSize, attribution: MapTilerAttributionPlacement) -> URL? {
        switch style {
        case .light:
            return URL(string: "https://www.maptiler.com/img/cloud/home/map5.webp")
        case .dark:
            return URL(string: "https://www.maptiler.com/img/cloud/home/map6.webp")
        }
    }
}
