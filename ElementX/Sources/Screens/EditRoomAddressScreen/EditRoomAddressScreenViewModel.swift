//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias EditRoomAddressScreenViewModelType = StateStoreViewModel<EditRoomAddressScreenViewState, EditRoomAddressScreenViewAction>

class EditRoomAddressScreenViewModel: EditRoomAddressScreenViewModelType, EditRoomAddressScreenViewModelProtocol {
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<EditRoomAddressScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EditRoomAddressScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    @CancellableTask private var checkAliasAvailabilityTask: Task<Void, Never>?

    init(initialViewState: EditRoomAddressScreenViewState? = nil,
         roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        if let initialViewState {
            super.init(initialViewState: initialViewState)
        } else {
            super.init(initialViewState: EditRoomAddressScreenViewState(serverName: clientProxy.userIDServerName ?? ""))
            
            state.currentAliasLocalPart = localPartForMatchingAlias(computeFromDisplayName: false)
            state.bindings.desiredAliasLocalPart = localPartForMatchingAlias(computeFromDisplayName: true) ?? ""
        }
        
        setupSubscriptions()
    }
    
    /// Give priority to aliases from the current user's homeserver as remote ones
    /// cannot be edited. If none match then don't fallback and show an empty alias
    /// instead so that the user can add one sepecific to this homeserver.
    private func localPartForMatchingAlias(computeFromDisplayName: Bool) -> String? {
        if let matchingAlias = roomProxy.infoPublisher.value.firstAliasMatching(serverName: clientProxy.userIDServerName, useFallback: false) {
            return matchingAlias.aliasLocalPart
        }
        
        guard computeFromDisplayName, let displayName = roomProxy.infoPublisher.value.displayName else {
            return nil
        }
        
        return roomAliasNameFromRoomDisplayName(roomName: displayName)
    }
    
    // MARK: - Public
    
    override func process(viewAction: EditRoomAddressScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            Task { await save() }
        case .cancel:
            actionsSubject.send(.dismiss)
        }
    }
    
    private func setupSubscriptions() {
        context.$viewState
            .map(\.bindings.desiredAliasLocalPart)
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] aliasLocalPart in
                guard let self else {
                    return
                }
                
                guard let canonicalAlias = String.makeCanonicalAlias(aliasLocalPart: aliasLocalPart,
                                                                     serverName: state.serverName) else {
                    // While is empty don't display the errors, since the save button is already disabled
                    state.aliasErrors.removeAll()
                    return
                }
                
                if !isRoomAliasFormatValid(alias: canonicalAlias) {
                    state.aliasErrors.insert(.invalidSymbols)
                    // If the alias is invalid we don't need to check for availability
                    state.aliasErrors.remove(.alreadyExists)
                    checkAliasAvailabilityTask = nil
                    return
                }
                
                state.aliasErrors.remove(.invalidSymbols)
                
                guard aliasLocalPart != state.currentAliasLocalPart else {
                    // Doesn't make sense to check the availability and display an error if the alias didn't change, the save button should also be disabled
                    state.aliasErrors.remove(.alreadyExists)
                    checkAliasAvailabilityTask = nil
                    return
                }
                
                checkAliasAvailabilityTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    
                    if case .success(false) = await self.clientProxy.isAliasAvailable(canonicalAlias) {
                        guard !Task.isCancelled else { return }
                        state.aliasErrors.insert(.alreadyExists)
                    } else {
                        guard !Task.isCancelled else { return }
                        state.aliasErrors.remove(.alreadyExists)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func save() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        guard let canonicalAlias = String.makeCanonicalAlias(aliasLocalPart: state.bindings.desiredAliasLocalPart, serverName: state.serverName),
              isRoomAliasFormatValid(alias: canonicalAlias) else {
            state.aliasErrors = [.invalidSymbols]
            return
        }
        
        switch await clientProxy.isAliasAvailable(canonicalAlias) {
        case .success(true):
            break
        case .success(false):
            state.aliasErrors = [.alreadyExists]
            return
        case .failure:
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        let oldAlias = roomProxy.infoPublisher.value.firstAliasMatching(serverName: clientProxy.userIDServerName, useFallback: false)
        
        // First publish the new alias
        if case .failure = await roomProxy.publishRoomAliasInRoomDirectory(canonicalAlias) {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        // Then set it as the main alias
        if case .failure = await roomProxy.updateCanonicalAlias(canonicalAlias, altAliases: []) {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        // And finally delete the old one
        if let oldAlias, case .failure = await roomProxy.removeRoomAliasFromRoomDirectory(oldAlias) {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        actionsSubject.send(.dismiss)
    }
    
    private static let loadingIndicatorIdentifier = "\(EditRoomAddressScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}

private extension String {
    var aliasLocalPart: String {
        dropFirst().split(separator: ":").first.flatMap(String.init) ?? ""
    }
}
