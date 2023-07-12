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
        VStack(spacing: 0) {
            if let locationDescription = context.viewState.locationDescription {
                Text(locationDescription)
                    .lineLimit(2)
                    .foregroundColor(Color.compound.textPrimary)
                    .font(.compound.bodyMD)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            mapView
        }
        .track(screen: context.viewState.isLocationPickerMode ? .locationSend : .locationView)
        .navigationTitle(context.viewState.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }
    
    private var mapView: some View {
        ZStack(alignment: .center) {
            MapLibreMapView(builder: builder,
                            options: mapOptions,
                            showsUserLocationMode: $context.showsUserLocationMode,
                            error: $context.mapError,
                            mapCenterCoordinate: $context.mapCenterLocation,
                            isLocationAuthorized: $context.isLocationAuthorized,
                            geolocationUncertainty: $context.geolocationUncertainty) {
                context.send(viewAction: .userDidPan)
            }
            .ignoresSafeArea(.all, edges: mapSafeAreaEdges)

            if context.viewState.isLocationPickerMode {
                LocationMarkerView()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            centerToUserLocationButton
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
                    .popover(isPresented: $context.showShareSheet) { shareSheet }
            }
        }

        if context.viewState.isLocationPickerMode {
            ToolbarItemGroup(placement: .bottomBar) {
                selectLocationButton
                Spacer()
            }
        }
    }

    private var mapOptions: MapLibreMapView.Options {
        var annotations: [LocationAnnotation] = []
        if context.viewState.isLocationPickerMode == false {
            let annotation = LocationAnnotation(coordinate: context.viewState.initialMapCenter, anchorPoint: .bottomCenter) {
                LocationMarkerView()
            }
            annotations.append(annotation)
        }

        return .init(zoomLevel: context.viewState.zoomLevel,
                     initialZoomLevel: context.viewState.initialZoomLevel,
                     mapCenter: context.viewState.initialMapCenter,
                     annotations: annotations)
    }

    private var mapSafeAreaEdges: Edge.Set {
        context.viewState.isLocationPickerMode ? .horizontal : [.horizontal, .bottom]
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
                Text(context.viewState.isSharingUserLocation ? L10n.screenShareMyLocationAction : L10n.screenShareThisLocationAction)
            }
        }
    }
    
    private var centerToUserLocationButton: some View {
        Button {
            context.send(viewAction: .centerToUser)
        } label: {
            Image(asset: context.viewState.isSharingUserLocation ? Asset.Images.locationPointerFull : Asset.Images.locationPointer)
        }
        .padding(16)
    }
    
    private var closeButton: some View {
        Button(L10n.actionCancel) {
            context.send(viewAction: .close)
        }
    }

    private var shareButton: some View {
        Button {
            context.showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    @ViewBuilder
    private var shareSheet: some View {
        let location = context.viewState.initialMapCenter
        let locationDescription = context.viewState.locationDescription
        AppActivityView(activityItems: [ShareToMapsAppActivity.MapsAppType.apple.activityURL(for: location, locationDescription: locationDescription)],
                        applicationActivities: ShareToMapsAppActivity.MapsAppType.allCases.map { ShareToMapsAppActivity(type: $0, location: location, locationDescription: locationDescription) })
            .edgesIgnoringSafeArea(.bottom)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
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
            StaticLocationScreen(context: StaticLocationScreenViewModel(interactionMode: .viewOnly(geoURI: .init(latitude: 41.9027835, longitude: 12.4963655))).context)
        }
        .previewDisplayName("View Only")

        NavigationStack {
            StaticLocationScreen(context: StaticLocationScreenViewModel(interactionMode: .viewOnly(geoURI: .init(latitude: 41.9027835, longitude: 12.4963655), description: "Cool position")).context)
        }
        .previewDisplayName("View Only (with description)")
    }
}

private extension CGPoint {
    static let bottomCenter: Self = .init(x: 0.5, y: 1)
}
