//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

typealias LocationSharingScreenViewModelType = StateStoreViewModelV2<LocationSharingScreenViewState, LocationSharingScreenViewAction>

class LocationSharingScreenViewModel: LocationSharingScreenViewModelType, LocationSharingScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineController: TimelineControllerProtocol
    private let liveLocationManager: LiveLocationManagerProtocol
    private let analytics: AnalyticsServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationCenter: NotificationCenter
    
    private let actionsSubject: PassthroughSubject<LocationSharingScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<LocationSharingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var authorizationStatusSubscription: AnyCancellable?
    // periphery:ignore - keep alive to keep receiving updates.
    private var liveLocationService: RoomLiveLocationServiceProtocol?
    private var needsCenteringOnFirstLiveLocationUpdate = false
    
    init(interactionMode: LocationSharingInteractionMode,
         mapURLBuilder: MapTilerURLBuilderProtocol,
         roomProxy: JoinedRoomProxyProtocol,
         timelineController: TimelineControllerProtocol,
         liveLocationManager: LiveLocationManagerProtocol,
         analytics: AnalyticsServiceProtocol,
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
                                           ownUserID: roomProxy.ownUserID),
                   mediaProvider: mediaProvider)
        
        updateUserProfiles(members: roomProxy.membersPublisher.value)
        setupSubscriptions()
        
        if case .viewLive(_, let initialLiveLocation) = interactionMode {
            if initialLiveLocation == nil {
                needsCenteringOnFirstLiveLocationUpdate = true
            }
            Task { await setupLiveLocationSubscription() }
        }
    }
    
    override func process(viewAction: LocationSharingScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .startLiveLocation:
            startLiveLocation()
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
                state.bindings.alertInfo = .init(alertID: .missingAuthorization,
                                                 primaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil),
                                                 secondaryButton: .init(title: L10n.commonSettings, action: action))
            }
        case .stopLiveLocation:
            stopLiveLocation()
        case .setMapCenter(let coordinate):
            state.bindings.showsUserLocationMode = .show
            state.bindings.mapCenterLocation = coordinate
        }
    }
    
    // MARK: - Private
    
    private func stopLiveLocation() {
        state.isStoppingLiveLocation = true
        if let index = state.liveLocationShares.firstIndex(where: { $0.userID == roomProxy.ownUserID }) {
            state.liveLocationShares.remove(at: index)
        }
        Task { await liveLocationManager.stopLiveLocation(roomID: roomProxy.id) }
    }
    
    private func setupLiveLocationSubscription() async {
        let liveLocationService = await roomProxy.makeLiveLocationService()
        self.liveLocationService = liveLocationService
        
        liveLocationService.liveLocationsPublisher
            .sink { [weak self] liveLocationsShares in
                guard let self else { return }
                MXLog.info("Received live location shares update: \(liveLocationsShares.count) share(s)")
                
                let ownUserID = roomProxy.ownUserID
                let isStoppingLiveLocation = state.isStoppingLiveLocation
                state.liveLocationShares = liveLocationsShares
                    .filter { !(isStoppingLiveLocation && ownUserID == $0.userID) }
                    .sorted { lhs, rhs in
                        if lhs.userID == ownUserID { return true }
                        if rhs.userID == ownUserID { return false }
                        return lhs.timestamp > rhs.timestamp
                    }
                
                updateUserProfiles(members: roomProxy.membersPublisher.value)
                
                if needsCenteringOnFirstLiveLocationUpdate,
                   let liveLocation = state.liveLocationShares.first,
                   let geoURI = liveLocation.geoURI {
                    needsCenteringOnFirstLiveLocationUpdate = false
                    context.send(viewAction: .setMapCenter(.init(latitude: geoURI.latitude, longitude: geoURI.longitude)))
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSubscriptions() {
        roomProxy.membersPublisher.sink { [weak self] members in
            self?.updateUserProfiles(members: members)
        }
        .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                // Let's remove the subscription if the user backgrounds the app (maybe to change their location settings)
                self?.authorizationStatusSubscription = nil
            }
            .store(in: &cancellables)
    }
    
    private func updateUserProfiles(members: [RoomMemberProxyProtocol]) {
        switch state.interactionMode {
        case .picker:
            let ownUser = members.first { $0.userID == roomProxy.ownUserID }.map(UserProfileProxy.init) ?? .init(userID: roomProxy.ownUserID)
            state.userProfiles = [ownUser.userID: ownUser]
        case .viewStatic(let location):
            let sender = members.first { $0.userID == location.sender.id }.map(UserProfileProxy.init) ?? .init(sender: location.sender)
            state.userProfiles = [sender.userID: sender]
        case .viewLive(let sender, _):
            var userIDs = Set(state.liveLocationShares.map(\.userID))
            if let senderID = sender?.id {
                userIDs.insert(senderID)
            }
            state.userProfiles = userIDs.reduce(into: [:]) { dict, userID in
                if let member = members.first(where: { $0.userID == userID }) {
                    dict[userID] = UserProfileProxy(member: member)
                } else {
                    dict[userID] = UserProfileProxy(userID: userID)
                }
            }
        }
    }
    
    private func startLiveLocation() {
        guard let powerLevels = roomProxy.infoPublisher.value.powerLevels,
              powerLevels.canOwnUser(sendStateEvent: .beaconInfo),
              powerLevels.canOwnUser(sendMessage: .beacon) else {
            state.bindings.alertInfo = .init(alertID: .missingLiveLocationSharingPermission)
            return
        }
        
        checkAlwaysShareLocationPermission()
    }
    
    private func checkAlwaysShareLocationPermission() {
        authorizationStatusSubscription = nil
        let authorizationStatus = liveLocationManager.authorizationStatus.value
        switch authorizationStatus {
        case .authorizedAlways:
            showLiveLocationFlow()
        case .notDetermined:
            // This is to solve a race condition with map libre which always tries first
            // to request the when in use permission, we wait for it and then try again
            authorizationStatusSubscription = liveLocationManager.authorizationStatus
                .filter { $0 != authorizationStatus } // skip current status
                .first() // this publisher only fires when there is an actual change, and if the user is done with permissions
                .sink { [weak self] newValue in
                    guard newValue == .authorizedWhenInUse else { return }
                    self?.checkAlwaysShareLocationPermission()
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
                .sink { [weak self] newValue in
                    guard newValue == .authorizedAlways else { return }
                    self?.showLiveLocationFlow()
                }
        default:
            showMissingAlwaysAuthorizedAlert()
        }
    }
    
    private func showLiveLocationFlow() {
        if liveLocationManager.hasDisplayedLiveLocationDisclaimer {
            showLiveLocationDurationPicker()
        } else {
            state.bindings.alertInfo = .init(alertID: .liveLocationDisclaimer,
                                             primaryButton: .init(title: L10n.actionDecline, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionAccept) { [weak self] in
                                                 guard let self else { return }
                                                 liveLocationManager.hasDisplayedLiveLocationDisclaimer = true
                                                 // Delay so SwiftUI finishes dismissing the current alert
                                                 // before presenting the next one.
                                                 DispatchQueue.main.async {
                                                     self.showLiveLocationDurationPicker()
                                                 }
                                             })
        }
    }
    
    /// It's easier to achieve the format we want with a DateComponentsFormatter
    /// than using the `.formatted` function of Duration.
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    private func showLiveLocationDurationPicker() {
        let durations: [Duration] = [.seconds(15 * 60), // 15 minutes
                                     .seconds(60 * 60), // 1 hour
                                     .seconds(60 * 60 * 8)] // 8 hours
        
        let durationButtons: [AlertInfo<LocationSharingViewAlert>.AlertButton] = durations.compactMap { duration in
            guard let title = Self.durationFormatter.string(from: duration.seconds) else { return nil }
            return .init(title: title) { [weak self] in
                Task { [weak self] in await self?.startLiveLocationSharingInRoom(duration: duration) }
            }
        }
        
        state.bindings.alertInfo = .init(alertID: .liveLocationDurationSelection,
                                         primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                         verticalButtons: durationButtons)
    }
    
    private func startLiveLocationSharingInRoom(duration: Duration) async {
        showLoader()
        defer {
            hideLoader()
        }
        
        let result = await liveLocationManager.startLiveLocation(roomID: roomProxy.id,
                                                                 duration: duration)
        
        switch result {
        case .success:
            actionsSubject.send(.close)
        case .failure(let error):
            MXLog.error("Failed to start live location sharing: \(error)")
            showErrorIndicator()
        }
    }
    
    private func showMissingAlwaysAuthorizedAlert() {
        state.bindings.alertInfo = .init(alertID: .missingAlwaysAuthorization,
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
        userIndicatorController.submitIndicator(UserIndicator(id: Self.statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              icon: \.close))
    }
    
    private func showLoader() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorID,
                                                              type: .modal(progress: .indeterminate,
                                                                           interactiveDismissDisabled: true,
                                                                           allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoader() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
    
    private static let loadingIndicatorID = "\(LocationSharingScreenViewModel.self)-Loading"
    
    private static let statusIndicatorID = "\(LocationSharingScreenViewModel.self)-Status"
}

extension LocationSharingScreenViewModel {
    enum MockType {
        case picker
        case pickerWithoutLiveLocationOption
        case staticSenderLocation
        case staticPinLocation
        case viewLive
        case viewLiveEmpty
    }
    
    static func mock(type: MockType,
                     senderID: String = "@dan:matrix.org") -> LocationSharingScreenViewModel {
        let interactionMode: LocationSharingInteractionMode = switch type {
        case .picker:
            .picker(shouldShowLiveLocationOption: true)
        case .pickerWithoutLiveLocationOption:
            .picker(shouldShowLiveLocationOption: false)
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
        case .viewLive, .viewLiveEmpty:
            .viewLive(sender: .init(id: senderID, displayName: "Me"),
                      initialLiveLocationShare: LiveLocationShare(userID: senderID,
                                                                  geoURI: .init(latitude: 41.9027835, longitude: 12.4963655),
                                                                  timestamp: .mock,
                                                                  timeoutDate: .distantFuture))
        }
        
        let liveLocationShares: [LiveLocationShare] = if type == .viewLive {
            [
                LiveLocationShare(userID: RoomMemberProxyMock.mockMe.userID,
                                  geoURI: .init(latitude: 41.9027835, longitude: 12.4963655),
                                  timestamp: .mock,
                                  timeoutDate: .distantFuture),
                LiveLocationShare(userID: RoomMemberProxyMock.mockAlice.userID,
                                  geoURI: .init(latitude: 48.8566, longitude: 2.3522),
                                  timestamp: .mock,
                                  timeoutDate: .distantFuture),
                LiveLocationShare(userID: RoomMemberProxyMock.mockBob.userID,
                                  geoURI: .init(latitude: 51.5074, longitude: -0.1278),
                                  timestamp: .mock,
                                  timeoutDate: .distantFuture)
            ]
        } else {
            []
        }
        
        let liveLocationServiceMock = RoomLiveLocationServiceMock(.init(shares: liveLocationShares))
        let roomProxy = JoinedRoomProxyMock(.init(members: .allMembers, ownUserID: RoomMemberProxyMock.mockMe.userID))
        roomProxy.makeLiveLocationServiceReturnValue = liveLocationServiceMock
        
        return LocationSharingScreenViewModel(interactionMode: interactionMode,
                                              mapURLBuilder: AppSettings.volatile().mapTilerSettings.publisher.value,
                                              roomProxy: roomProxy,
                                              timelineController: MockTimelineController(),
                                              liveLocationManager: LiveLocationManagerMock(),
                                              analytics: AnalyticsServiceMock(.init()),
                                              userIndicatorController: UserIndicatorControllerMock(),
                                              mediaProvider: MediaProviderMock(.init()))
    }
}
