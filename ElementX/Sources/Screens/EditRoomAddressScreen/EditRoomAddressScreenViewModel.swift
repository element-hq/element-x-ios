//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        
        guard let desiredCanonicalAlias = String.makeCanonicalAlias(aliasLocalPart: state.bindings.desiredAliasLocalPart, serverName: state.serverName),
              isRoomAliasFormatValid(alias: desiredCanonicalAlias) else {
            state.aliasErrors = [.invalidSymbols]
            return
        }
        
        switch await clientProxy.isAliasAvailable(desiredCanonicalAlias) {
        case .success(true):
            break
        case .success(false):
            state.aliasErrors = [.alreadyExists]
            return
        case .failure:
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        let savedAliasFromHomeserver = roomProxy.infoPublisher.value.firstAliasMatching(serverName: state.serverName, useFallback: false)
        let savedCanonicalAlias = roomProxy.infoPublisher.value.canonicalAlias
        
        // First publish the desired new alias in the room directory
        if case .failure = await roomProxy.publishRoomAliasInRoomDirectory(desiredCanonicalAlias) {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        // Then try remove the old alias from the room directory on our current HS
        if let savedAliasFromHomeserver {
            if case .failure = await roomProxy.removeRoomAliasFromRoomDirectory(savedAliasFromHomeserver) {
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                return
            }
        }
        
        // Finally update the canonical alias state..
        // Allow to update the canonical alias only if the saved canonical alias matches the homeserver or if there is no canonical alias
        if savedCanonicalAlias == nil || savedCanonicalAlias?.hasSuffix(state.serverName) == true {
            var newAlternativeAliases = roomProxy.infoPublisher.value.alternativeAliases
            newAlternativeAliases.removeAll { $0 == savedAliasFromHomeserver }

            if case .failure = await roomProxy.updateCanonicalAlias(desiredCanonicalAlias, altAliases: newAlternativeAliases) {
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                return
            }
            // Otherwise, update the alternative aliases and keep the current canonical alias
        } else {
            var newAlternativeAliases = roomProxy.infoPublisher.value.alternativeAliases
            // We also remove the existing saved alias from our homeserver if exists
            newAlternativeAliases.removeAll { $0 == savedAliasFromHomeserver }
            newAlternativeAliases.insert(desiredCanonicalAlias, at: 0)
            
            if case .failure = await roomProxy.updateCanonicalAlias(savedCanonicalAlias, altAliases: newAlternativeAliases) {
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                return
            }
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
