//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias KnockRequestsListScreenViewModelType = StateStoreViewModel<KnockRequestsListScreenViewState, KnockRequestsListScreenViewAction>

class KnockRequestsListScreenViewModel: KnockRequestsListScreenViewModelType, KnockRequestsListScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<KnockRequestsListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: KnockRequestsListScreenViewState(), mediaProvider: mediaProvider)
        
        updateRoomInfo(roomInfo: roomProxy.infoPublisher.value)
        Task {
            await updatePermissions()
        }
        
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: KnockRequestsListScreenViewAction) {
        switch viewAction {
        case .acceptAllRequests:
            state.bindings.alertInfo = .init(id: .acceptAllRequests,
                                             title: L10n.screenKnockRequestsListAcceptAllAlertTitle,
                                             message: L10n.screenKnockRequestsListAcceptAllAlertDescription,
                                             primaryButton: .init(title: L10n.screenKnockRequestsListAcceptAllAlertConfirmButtonTitle,
                                                                  action: acceptAll),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .acceptRequest(let eventID):
            guard let request = getRequest(eventID: eventID) else {
                return
            }
            accept(request: request)
        case .declineRequest(let eventID):
            guard let request = getRequest(eventID: eventID) else {
                return
            }
            
            state.bindings.alertInfo = .init(id: .declineRequest,
                                             title: L10n.screenKnockRequestsListDeclineAlertTitle,
                                             message: L10n.screenKnockRequestsListDeclineAlertDescription(request.userID),
                                             primaryButton: .init(title: L10n.screenKnockRequestsListDeclineAlertConfirmButtonTitle,
                                                                  role: .destructive) { [weak self] in self?.decline(request: request) },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .ban(let eventID):
            guard let request = getRequest(eventID: eventID) else {
                return
            }
            
            state.bindings.alertInfo = .init(id: .declineAndBan,
                                             title: L10n.screenKnockRequestsListBanAlertTitle,
                                             primaryButton: .init(title: L10n.screenKnockRequestsListBanAlertConfirmButtonTitle,
                                                                  role: .destructive) { [weak self] in self?.declineAndBan(request: request) },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        }
    }
    
    // MARK: - Private
    
    private func getRequest(eventID: String) -> KnockRequestProxyProtocol? {
        guard case let .loaded(requests) = roomProxy.knockRequestsStatePublisher.value,
              let request = requests.first(where: { $0.eventID == eventID }) else {
            return nil
        }
        return request
    }
    
    private func accept(request: KnockRequestProxyProtocol) {
        showLoadingIndicator(title: L10n.screenKnockRequestsListAcceptLoadingTitle)
        
        let eventID = request.eventID
        state.handledEventIDs.insert(eventID)
        
        Task {
            switch await request.accept() {
            case .success:
                hideLoadingIndicator()
            case .failure:
                hideLoadingIndicator()
                state.handledEventIDs.remove(eventID)
                state.bindings.alertInfo = .init(id: .acceptFailed,
                                                 title: L10n.screenKnockRequestsListAcceptFailedAlertTitle,
                                                 message: L10n.screenKnockRequestsListAcceptFailedAlertDescription,
                                                 primaryButton: .init(title: L10n.actionYesTryAgain) { [weak self] in self?.accept(request: request) },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
            }
        }
    }
    
    private func decline(request: KnockRequestProxyProtocol) {
        showLoadingIndicator(title: L10n.screenKnockRequestsListDeclineLoadingTitle)
        
        let eventID = request.eventID
        state.handledEventIDs.insert(eventID)
        
        Task {
            switch await request.decline() {
            case .success:
                hideLoadingIndicator()
            case .failure:
                hideLoadingIndicator()
                state.handledEventIDs.remove(eventID)
                state.bindings.alertInfo = .init(id: .declineFailed,
                                                 title: L10n.screenKnockRequestsListDeclineFailedAlertTitle,
                                                 message: L10n.screenKnockRequestsListDeclineFailedAlertDescription,
                                                 primaryButton: .init(title: L10n.actionYesTryAgain) { [weak self] in self?.decline(request: request) },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
            }
        }
    }
    
    private func declineAndBan(request: KnockRequestProxyProtocol) {
        showLoadingIndicator(title: L10n.screenKnockRequestsListBanLoadingTitle)
        
        let eventID = request.eventID
        state.handledEventIDs.insert(eventID)
        
        Task {
            switch await request.ban() {
            case .success:
                hideLoadingIndicator()
            case .failure:
                hideLoadingIndicator()
                state.handledEventIDs.remove(eventID)
                state.bindings.alertInfo = .init(id: .declineFailed,
                                                 title: L10n.screenKnockRequestsListDeclineFailedAlertTitle,
                                                 message: L10n.screenKnockRequestsListDeclineFailedAlertDescription,
                                                 primaryButton: .init(title: L10n.actionYesTryAgain) { [weak self] in self?.declineAndBan(request: request) },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
            }
        }
    }
    
    private func acceptAll() {
        guard case let .loaded(requests) = roomProxy.knockRequestsStatePublisher.value else {
            return
        }
        showLoadingIndicator(title: L10n.screenKnockRequestsListAcceptAllLoadingTitle)
        state.handledEventIDs.formUnion(Set(requests.map(\.eventID)))
        
        Task {
            let failedIDs = await withTaskGroup(of: (String, Result<Void, KnockRequestProxyError>).self) { group in
                for request in requests {
                    group.addTask {
                        await (request.eventID, request.accept())
                    }
                }
                
                var failedIDs = [String]()
                for await result in group where result.1.isFailure {
                    failedIDs.append(result.0)
                }
                return failedIDs
            }
            hideLoadingIndicator()
            
            if !failedIDs.isEmpty {
                state.handledEventIDs.subtract(failedIDs)
                state.bindings.alertInfo = .init(id: .acceptAllFailed,
                                                 title: L10n.screenKnockRequestsListAcceptAllFailedAlertTitle,
                                                 message: L10n.screenKnockRequestsListAcceptAllFailedAlertDescription,
                                                 primaryButton: .init(title: L10n.actionYesTryAgain) { [weak self] in self?.acceptAll() },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
            }
        }
    }
    
    private func setupSubscriptions() {
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo: roomInfo)
                Task { await self?.updatePermissions() }
            }
            .store(in: &cancellables)
        
        roomProxy.knockRequestsStatePublisher
            .map(KnockRequestsListState.init)
            .removeDuplicates()
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .weakAssign(to: \.state.requestsState, on: self)
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.isLoading)
            .removeDuplicates()
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    showInitialLoadingIndicator()
                } else {
                    hideLoadingIndicator()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateRoomInfo(roomInfo: RoomInfoProxy) {
        switch roomInfo.joinRule {
        case .knock, .knockRestricted:
            state.isKnockableRoom = true
        default:
            state.isKnockableRoom = false
        }
    }
    
    private func updatePermissions() async {
        state.canAccept = await (try? roomProxy.canUserInvite(userID: roomProxy.ownUserID).get()) == true
        state.canDecline = await (try? roomProxy.canUserKick(userID: roomProxy.ownUserID).get()) == true
        state.canBan = await (try? roomProxy.canUserBan(userID: roomProxy.ownUserID).get()) == true
    }
    
    private static let loadingIndicatorIdentifier = "\(KnockRequestsListScreenViewModel.self)-Loading"
    
    private func showInitialLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate,
                                                                           interactiveDismissDisabled: false,
                                                                           allowsInteraction: true),
                                                              title: L10n.screenKnockRequestsListInitialLoadingTitle,
                                                              persistent: true),
                                                delay: .milliseconds(100))
    }
    
    private func showLoadingIndicator(title: String) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate,
                                                                           interactiveDismissDisabled: false,
                                                                           allowsInteraction: false),
                                                              title: title,
                                                              persistent: true),
                                                delay: .milliseconds(200))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
