//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LocationSharingScreen: View {
    @Bindable var context: LocationSharingScreenViewModel.Context
    
    var body: some View {
        switch context.viewState.interactionMode {
        case .picker:
            mainContent
                .sheet(isPresented: .constant(true)) {
                    LocationPickerSheet(context: context)
                        .alert(item: $context.alertInfo)
                }
        case .viewStatic:
            mainContent
                .sheet(isPresented: .constant(true)) {
                    StaticLocationSheet(context: context)
                        .alert(item: $context.alertInfo)
                        .popover(item: $context.sharedAnnotation) { annotation in
                            LocationShareSheet(annotation: annotation)
                        }
                }
        case .viewLive:
            mainContent
        }
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        mapView
            .ignoresSafeArea(edges: .bottom)
            .track(screen: context.viewState.interactionMode == .picker ? .LocationSend : .LocationView)
            .navigationTitle(L10n.screenViewLocationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
    }
    
    private var mapView: some View {
        ZStack(alignment: .center) {
            MapLibreMapView(mapURLBuilder: context.viewState.mapURLBuilder,
                            options: mapOptions,
                            mediaProvider: context.mediaProvider,
                            showsUserLocationMode: $context.showsUserLocationMode,
                            error: $context.mapError,
                            mapCenterCoordinate: $context.mapCenterLocation,
                            hasLoadedUserLocation: $context.hasLoadedUserLocation,
                            isLocationAuthorized: $context.isLocationAuthorized,
                            geolocationUncertainty: $context.geolocationUncertainty) {
                context.send(viewAction: .userDidPan)
            }
            .ignoresSafeArea(edges: mapSafeAreaEdges)
            
            if let pickerMarkerKind = context.viewState.pickerMarkerKind {
                LocationMarkerView(kind: pickerMarkerKind, mediaProvider: context.mediaProvider)
            }
        }
        .overlay(alignment: .topTrailing) {
            centerToUserLocationButton
        }
    }
    
    private var mapSafeAreaEdges: Edge.Set {
        context.viewState.interactionMode == .picker ? .horizontal : [.horizontal, .bottom]
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ToolbarButton(role: .close) {
                context.send(viewAction: .close)
            }
        }
    }
    
    private var mapOptions: MapLibreMapView.Options {
        .init(zoomLevel: context.viewState.zoomLevel,
              initialZoomLevel: context.viewState.initialZoomLevel,
              mapCenter: context.viewState.initialMapCenter,
              annotations: context.viewState.annotations)
    }
    
    @ViewBuilder
    private var centerToUseIcon: some View {
        if context.viewState.isLocationLoading {
            ProgressView()
                .tint(.compound.iconPrimary)
                .padding(13)
        } else {
            CompoundIcon(context.viewState.isSharingUserLocation ? \.locationNavigatorCentred : \.locationNavigator)
                .foregroundStyle(.compound.iconPrimary)
                .padding(13)
        }
    }
    
    private var centerToUserLocationButton: some View {
        Button {
            context.send(viewAction: .centerToUser)
        } label: {
            if #available(iOS 26.0, *) {
                centerToUseIcon
                    .glassEffect(.regular.interactive(), in: Circle())
                    .tint(.compound.bgCanvasDefault)
            } else {
                centerToUseIcon
                    .background(.compound.bgCanvasDefault, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .disabled(context.viewState.isLocationLoading)
        .dynamicTypeSize(.large)
        .padding(13)
    }
}

// MARK: - Previews

struct LocationSharingScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingScreenViewModel.mock(type: .staticSenderLocation)
    
    static let withoutLiveSharingViewModel = LocationSharingScreenViewModel.mock(type: .picker, liveLocationSharingEnabled: false)
    
    static let pinViewModel = LocationSharingScreenViewModel.mock(type: .staticPinLocation)
    
    static let pickerViewModel = LocationSharingScreenViewModel.mock(type: .picker)
    
    static var previews: some View {
        ElementNavigationStack {
            LocationSharingScreen(context: pickerViewModel.context)
        }
        .previewDisplayName("Picker")
        
        ElementNavigationStack {
            LocationSharingScreen(context: withoutLiveSharingViewModel.context)
        }
        .previewDisplayName("Picker without live location sharing")
        
        ElementNavigationStack {
            LocationSharingScreen(context: viewModel.context)
        }
        .previewDisplayName("User Static Location")
        
        ElementNavigationStack {
            LocationSharingScreen(context: pinViewModel.context)
        }
        .previewDisplayName("Pin Static Location")
    }
}
