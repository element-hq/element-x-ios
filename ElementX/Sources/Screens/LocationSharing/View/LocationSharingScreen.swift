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
        if context.viewState.isLocationPickerMode {
            mainContent
                .sheet(isPresented: .constant(true)) {
                    sharingOptionsSheet
                        .alert(item: $context.alertInfo)
                }
        } else {
            mainContent
                .alert(item: $context.alertInfo)
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
                LocationMarkerView(userProfile: context.viewState.shownUserProfile, mediaProvider: context.mediaProvider)
            }
        }
        .overlay(alignment: .topTrailing) {
            centerToUserLocationButton
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: context.viewState.showShareAction ? .topBarLeading : .topBarTrailing) {
            ToolbarButton(role: .close) {
                context.send(viewAction: .close)
            }
        }
                
        if context.viewState.showShareAction {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    context.showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .popover(isPresented: $context.showShareSheet) { shareSheet }
            }
        }
    }
    
    private var mapOptions: MapLibreMapView.Options {
        var annotations: [String: LocationAnnotation] = [:]
        if !context.viewState.isLocationPickerMode {
            let id = context.viewState.shownUserProfile?.userID ?? UUID().uuidString
            let annotation = LocationAnnotation(id: id,
                                                coordinate: context.viewState.initialMapCenter,
                                                anchorPoint: .bottomCenter) {
                LocationMarkerView(userProfile: context.viewState.shownUserProfile, mediaProvider: context.mediaProvider)
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
        let senderName = context.viewState.shownUserProfile?.displayName
        AppActivityView(activityItems: [ShareToMapsAppActivity.MapsAppType.apple.activityURL(for: location, senderName: senderName)],
                        applicationActivities: ShareToMapsAppActivity.MapsAppType.allCases.map { ShareToMapsAppActivity(type: $0, location: location, senderName: senderName) })
            .edgesIgnoringSafeArea(.bottom)
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
    
    @State private var sharingOptionsSheetHeight: CGFloat = .zero
    
    private var sharingOptionsSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                context.send(viewAction: .selectLocation)
            } label: {
                if context.viewState.isSharingUserLocation {
                    LocationSharingLabel(text: L10n.screenShareMyLocationAction,
                                         icon: \.locationNavigatorCentred,
                                         iconColor: .compound.iconSecondary)
                } else {
                    LocationSharingLabel(text: L10n.screenShareThisLocationAction,
                                         icon: \.locationNavigator,
                                         iconColor: .compound.iconSecondary)
                }
            }
            if context.viewState.showLiveLocationSharingButton {
                Button { } label: {
                    LocationSharingLabel(text: L10n.actionShareLiveLocation,
                                         icon: \.locationPinSolid,
                                         iconColor: .compound.iconAccentPrimary)
                }
            }
        }
        .font(.compound.bodyLG)
        .foregroundStyle(.compound.textPrimary)
        .padding(.top, 38)
        .readHeight($sharingOptionsSheetHeight)
        .interactiveDismissDisabled()
        .presentationBackground(.compound.bgCanvasDefault)
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.hidden)
        .presentationDetents([.height(sharingOptionsSheetHeight)])
    }
}

private struct LocationSharingLabel: View {
    let text: String
    let icon: KeyPath<CompoundIcons, Image>
    let iconColor: Color
    
    var body: some View {
        Label {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .rowDivider(alignment: .top, horizontalInsets: 16.0)
        } icon: {
            CompoundIcon(icon)
                .foregroundStyle(iconColor)
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

struct LocationSharingScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingScreenViewModel(interactionMode: .viewStatic(senderID: "@dan:matrix.org", geoURI: .init(latitude: 41.9027835,
                                                                                                                                  longitude: 12.4963655)),
                                                          mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                          liveLocationSharingEnabled: true,
                                                          roomProxy: JoinedRoomProxyMock(.init()),
                                                          timelineController: MockTimelineController(),
                                                          analytics: ServiceLocator.shared.analytics,
                                                          userIndicatorController: UserIndicatorControllerMock(),
                                                          mediaProvider: MediaProviderMock(configuration: .init()))
    
    static let pinViewModel = LocationSharingScreenViewModel(interactionMode: .viewStatic(senderID: nil, geoURI: .init(latitude: 41.9027835,
                                                                                                                       longitude: 12.4963655)),
                                                             mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                             liveLocationSharingEnabled: true,
                                                             roomProxy: JoinedRoomProxyMock(.init()),
                                                             timelineController: MockTimelineController(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             userIndicatorController: UserIndicatorControllerMock(),
                                                             mediaProvider: MediaProviderMock(configuration: .init()))
    
    static let pickerViewModel = LocationSharingScreenViewModel(interactionMode: .picker,
                                                                mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                                                liveLocationSharingEnabled: true,
                                                                roomProxy: JoinedRoomProxyMock(.init()),
                                                                timelineController: MockTimelineController(),
                                                                analytics: ServiceLocator.shared.analytics,
                                                                userIndicatorController: UserIndicatorControllerMock(),
                                                                mediaProvider: MediaProviderMock(configuration: .init()))
    
    static var previews: some View {
        ElementNavigationStack {
            LocationSharingScreen(context: pickerViewModel.context)
        }
        .previewDisplayName("Picker")
        
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
