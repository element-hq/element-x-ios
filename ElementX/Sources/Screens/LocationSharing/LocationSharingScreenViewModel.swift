//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

typealias LocationSharingScreenViewModelType = StateStoreViewModelV2<LocationSharingScreenViewState, LocationSharingScreenViewAction>

class LocationSharingScreenViewModel: LocationSharingScreenViewModelType, LocationSharingScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineController: TimelineControllerProtocol
    private let liveLocationManager: LiveLocationManagerProtocol
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationCenter: NotificationCenter
    
    private let actionsSubject: PassthroughSubject<LocationSharingScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<LocationSharingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var authorizationStatusSubscription: AnyCancellable?
    
    init(interactionMode: LocationSharingInteractionMode,
         mapURLBuilder: MapTilerURLBuilderProtocol,
         liveLocationSharingEnabled: Bool,
         roomProxy: JoinedRoomProxyProtocol,
         timelineController: TimelineControllerProtocol,
         liveLocationManager: LiveLocationManagerProtocol,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         notificationCenter: NotificationCenter = .default) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.liveLocationManager = liveLocationManager
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.notificationCenter = notificationCenter
        
        super.init(initialViewState: .init(interactionMode: interactionMode,
                                           mapURLBuilder: mapURLBuilder,
                                           showLiveLocationSharingButton: liveLocationSharingEnabled,
                                           ownUserID: roomProxy.ownUserID),
                   mediaProvider: mediaProvider)
        
        updateShownUserProfile(members: roomProxy.membersPublisher.value)
        setupSubscriptions()
    }
    
    override func process(viewAction: LocationSharingScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .startLiveLocation:
            startLiveLocationSharing()
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
    
    private func setupSubscriptions() {
        roomProxy.membersPublisher.sink { [weak self] members in
            self?.updateShownUserProfile(members: members)
        }
        .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                // Let's remove the subscription if the user backgrounds the app (maybe to change their location settings)
                self?.authorizationStatusSubscription = nil
            }
            .store(in: &cancellables)
    }
    
    private func updateShownUserProfile(members: [RoomMemberProxyProtocol]) {
        switch state.interactionMode {
        case .picker:
            if let ownUser = members.first(where: { $0.userID == roomProxy.ownUserID }).map(UserProfileProxy.init) {
                state.userProfile = ownUser
            } else {
                state.userProfile = .init(userID: roomProxy.ownUserID)
            }
        case .viewStatic(let location):
            if let sender = members.first(where: { $0.userID == location.sender.id }).map(UserProfileProxy.init) {
                state.userProfile = sender
            } else {
                state.userProfile = .init(sender: location.sender)
            }
        }
    }
    
    private func startLiveLocationSharing() {
        authorizationStatusSubscription = nil
        let authorizationStatus = liveLocationManager.authorizationStatus.value
        switch authorizationStatus {
        case .authorizedAlways:
            // TODO: Start sending live location updates to the room
            break
        case .notDetermined:
            // This is to solve a race condition with map libre which always tries first
            // to request the when in use permission, we wait for it and then try again
            authorizationStatusSubscription = liveLocationManager.authorizationStatus
                .filter { $0 != authorizationStatus } // skip current status
                .first() // this publisher only fires when there is an actual change, and if the user is done with permissions
                .sink { [weak self] newValue in
                    guard newValue == .authorizedWhenInUse else { return }
                    self?.startLiveLocationSharing()
                }
        case .authorizedWhenInUse:
            guard liveLocationManager.requestAlwaysAuthorizationIfPossible() else {
                // Already requested before — iOS won't show the prompt again.
                showMissingAlwaysAuthorizedAlert()
                break
            }
            
            authorizationStatusSubscription = liveLocationManager.authorizationStatus
                .filter { $0 != authorizationStatus } // skip current status
                .first() // this publisher only fires when there is an actual change, and if the user is done with permissions
                .sink { newValue in
                    guard newValue == .authorizedAlways else { return }
                    // TODO: Start sending live location updates to the room
                }
        default:
            showMissingAlwaysAuthorizedAlert()
        }
    }
    
    private func showMissingAlwaysAuthorizedAlert() {
        state.bindings.alertInfo = .init(locationSharingViewError: .missingAlwaysAuthorization,
                                         primaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil),
                                         secondaryButton: .init(title: L10n.commonSettings) { [weak self] in self?.actionsSubject.send(.openSystemSettings) })
    }
    
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

extension LocationSharingScreenViewModel {
    enum MockType {
        case picker
        case staticSenderLocation
        case staticPinLocation
    }
    
    static func mock(type: MockType,
                     senderID: String = "@dan:matrix.org",
                     liveLocationSharingEnabled: Bool = true) -> LocationSharingScreenViewModel {
        let interactionMode: LocationSharingInteractionMode = switch type {
        case .picker:
            .picker
        case .staticPinLocation:
            .viewStatic(.init(sender: .init(id: senderID),
                              geoURI: .init(latitude: 41.9027835,
                                            longitude: 12.4963655),
                              kind: .pin,
                              timestamp: .mock))
        case .staticSenderLocation:
            .viewStatic(.init(sender: .init(id: senderID),
                              geoURI: .init(latitude: 41.9027835,
                                            longitude: 12.4963655),
                              kind: .sender,
                              timestamp: .mock))
        }
        
        return LocationSharingScreenViewModel(interactionMode: interactionMode,
                                              mapURLBuilder: ServiceLocator.shared.settings.mapTilerConfiguration,
                                              liveLocationSharingEnabled: liveLocationSharingEnabled,
                                              roomProxy: JoinedRoomProxyMock(.init()),
                                              timelineController: MockTimelineController(),
                                              liveLocationManager: LiveLocationManagerMock(),
                                              analytics: ServiceLocator.shared.analytics,
                                              userIndicatorController: UserIndicatorControllerMock(),
                                              mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
