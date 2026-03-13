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
                        .popover(isPresented: $context.showShareSheet) { shareSheet }
                }
        }
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        mapView
            .ignoresSafeArea(edges: .bottom)
            .track(screen: context.viewState.isLocationPickerMode ? .LocationSend : .LocationView)
            .navigationTitle(L10n.screenViewLocationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
    }
    
    private var mapView: some View {
        ZStack(alignment: .center) {
            MapLibreMapView(mapURLBuilder: context.viewState.mapURLBuilder,
                            options: mapOptions,
                            showsUserLocationMode: $context.showsUserLocationMode,
                            error: $context.mapError,
                            mapCenterCoordinate: $context.mapCenterLocation,
                            hasLoadedUserLocation: $context.hasLoadedUserLocation,
                            isLocationAuthorized: $context.isLocationAuthorized,
                            geolocationUncertainty: $context.geolocationUncertainty) {
                context.send(viewAction: .userDidPan)
            }
            .ignoresSafeArea(.all, edges: mapSafeAreaEdges)
            
            if context.viewState.isLocationPickerMode {
                LocationMarkerView(userProfile: context.viewState.locationMarkerUserProfile, mediaProvider: context.mediaProvider)
            }
        }
        .overlay(alignment: .topTrailing) {
            centerToUserLocationButton
        }
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
        var annotations: [String: LocationAnnotation] = [:]
        if !context.viewState.isLocationPickerMode {
            let id = context.viewState.locationMarkerUserProfile?.userID ?? UUID().uuidString
            let annotation = LocationAnnotation(id: id,
                                                coordinate: context.viewState.initialMapCenter,
                                                anchorPoint: .bottomCenter) {
                LocationMarkerView(userProfile: context.viewState.locationMarkerUserProfile, mediaProvider: context.mediaProvider)
            }
            annotations[id] = annotation
        }
        
        return .init(zoomLevel: context.viewState.zoomLevel,
                     initialZoomLevel: context.viewState.initialZoomLevel,
                     mapCenter: context.viewState.initialMapCenter,
                     annotations: annotations)
    }
    
    private var mapSafeAreaEdges: Edge.Set {
        context.viewState.isLocationPickerMode ? .horizontal : [.horizontal, .bottom]
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
    
    @ViewBuilder
    private var shareSheet: some View {
        let location = context.viewState.initialMapCenter
        let senderName = context.viewState.locationMarkerUserProfile?.displayName ?? context.viewState.locationMarkerUserProfile?.userID
        AppActivityView(activityItems: [ShareToMapsAppActivity.MapsAppType.apple.activityURL(for: location, senderName: senderName)],
                        applicationActivities: ShareToMapsAppActivity.MapsAppType.allCases.map { ShareToMapsAppActivity(type: $0, location: location, senderName: senderName) })
            .ignoresSafeArea(edges: .bottom)
            .presentationDetents([.medium, .large])
            .presentationCompactAdaptation(shareSheetCompactPresentation)
            .presentationDragIndicator(.hidden)
    }
    
    private var shareSheetCompactPresentation: PresentationAdaptation {
        if #available(iOS 26.0, *) {
            .none // ShareLinks use a popover presentation on iOS 26, let it match that.
        } else {
            .sheet
        }
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

private extension CGPoint {
    static let bottomCenter: Self = .init(x: 0.5, y: 1)
}
