//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

typealias LocationSharingScreenViewModelType = StateStoreViewModelV2<LocationSharingScreenViewState, LocationSharingScreenViewAction>

class LocationSharingScreenViewModel: LocationSharingScreenViewModelType, LocationSharingScreenViewModelProtocol {
    private let timelineController: TimelineControllerProtocol
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<LocationSharingScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<LocationSharingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(interactionMode: LocationSharingInteractionMode,
         mapURLBuilder: MapTilerURLBuilderProtocol,
         liveLocationSharingEnabled: Bool,
         timelineController: TimelineControllerProtocol,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.timelineController = timelineController
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(interactionMode: interactionMode,
                                           mapURLBuilder: mapURLBuilder,
                                           showLiveLocationSharingButton: liveLocationSharingEnabled))
    }
    
    override func process(viewAction: LocationSharingScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .selectLocation:
            guard let coordinate = state.bindings.mapCenterLocation else { return }
            let uncertainty = state.isSharingUserLocation ? context.geolocationUncertainty : nil
            Task { await sendLocation(.init(coordinate: coordinate, uncertainty: uncertainty), isUserLocation: state.isSharingUserLocation) }
        case .userDidPan:
            state.bindings.showsUserLocationMode = .show
        case .centerToUser:
            switch state.bindings.isLocationAuthorized {
            case .some(true), .none:
                state.bindings.showsUserLocationMode = .showAndFollow
            case .some(false):
                let action: () -> Void = { [weak self] in self?.actionsSubject.send(.openSystemSettings) }
                state.bindings.alertInfo = .init(locationSharingViewError: .missingAuthorization,
                                                 primaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil),
                                                 secondaryButton: .init(title: L10n.commonSettings, action: action))
            }
        }
    }
    
    // MARK: - Private
    
    private func sendLocation(_ geoURI: GeoURI, isUserLocation: Bool) async {
        guard case .success = await timelineController.sendLocation(body: geoURI.bodyMessage,
                                                                    geoURI: geoURI,
                                                                    description: nil,
                                                                    zoomLevel: 15,
                                                                    assetType: isUserLocation ? .sender : .pin) else {
            showErrorIndicator()
            return
        }
        
        actionsSubject.send(.close)
        
        analytics.trackComposer(inThread: false,
                                isEditing: false,
                                isReply: false,
                                messageType: isUserLocation ? .LocationUser : .LocationPin,
                                startsThread: nil)
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
    
    private var statusIndicatorID: String {
        "\(Self.self)-Status"
    }
}
