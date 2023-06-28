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

import SwiftUI

struct StaticLocationScreen: View {
    @ObservedObject var context: StaticLocationScreenViewModel.Context
    
    private let builder = MapTilerStyleBuilder(appSettings: ServiceLocator.shared.settings)
    
    var body: some View {
        mapView
            .ignoresSafeArea(.all, edges: mapSafeAreaEdges)
            .navigationTitle(context.viewState.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert(item: $context.alertInfo)
    }
    
    private var mapView: some View {
        ZStack(alignment: .center) {
            MapLibreMapView(builder: builder,
                            options: mapOptions,
                            showsUserLocationMode: .hide,
                            error: $context.mapError,
                            mapCenterCoordinate: $context.mapCenterLocation,
                            userDidPan: {
                                context.send(viewAction: .userDidPan)
                            })
            if context.viewState.showPinInTheCenter {
                LocationMarkerView()
            }
        }
    }

    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            closeButton
        }

        if context.viewState.showShareAction {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
            }
        }

        if context.viewState.showBottomToolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                selectLocationButton
                Spacer()
            }
        }
    }

    private var mapOptions: MapLibreMapView.Options {
        guard let coordinate = context.viewState.mapAnnotationCoordinate else {
            return .init(zoomLevel: context.viewState.zoomLevel)
        }

        return .init(zoomLevel: context.viewState.zoomLevel,
                     mapCenter: coordinate,
                     annotations: [LocationAnnotation(coordinate: coordinate, anchorPoint: .bottomCenter) {
                         LocationMarkerView()
                     }])
    }

    private var mapSafeAreaEdges: Edge.Set {
        context.viewState.showBottomToolbar ? .horizontal : [.horizontal, .bottom]
    }
    
    @ScaledMetric private var shareMarkerSize: CGFloat = 28
    private var selectLocationButton: some View {
        Button {
            context.send(viewAction: .selectLocation)
        } label: {
            HStack(spacing: 8) {
                Image(asset: Asset.Images.locationMarker)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: shareMarkerSize, height: shareMarkerSize)
                Text(context.viewState.isPinDropSharing ? L10n.screenShareThisLocationAction : L10n.screenShareMyLocationAction)
            }
        }
    }
    
    private var closeButton: some View {
        Button(L10n.actionCancel) {
            context.send(viewAction: .close)
        }
    }

    #warning("AG: fix me")
    private var shareButton: some View {
        ShareLink(item: "foo") {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

// MARK: - Previews

struct StaticLocationScreenViewer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StaticLocationScreen(context: StaticLocationScreenViewModel(interactionMode: .picker).context)
        }
        .previewDisplayName("Picker")

        NavigationStack {
            StaticLocationScreen(context: StaticLocationScreenViewModel(interactionMode: .viewOnly(.init(latitude: 41.9027835, longitude: 12.4963655))).context)
        }
        .previewDisplayName("View Only")
    }
}

private extension CGPoint {
    static let bottomCenter: Self = .init(x: 0.5, y: 1)
}
