//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias BlockedUsersScreenViewModelType = StateStoreViewModelV2<BlockedUsersScreenViewState, BlockedUsersScreenViewAction>

class BlockedUsersScreenViewModel: BlockedUsersScreenViewModelType, BlockedUsersScreenViewModelProtocol {
    let hideProfiles: Bool
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    
    init(hideProfiles: Bool,
         userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.hideProfiles = hideProfiles
        clientProxy = userSession.clientProxy
        self.userIndicatorController = userIndicatorController
        
        let ignoredUsers = clientProxy.ignoredUsersPublisher.value?.map { UserProfile(userID: $0) }
        
        super.init(initialViewState: BlockedUsersScreenViewState(blockedUsers: ignoredUsers ?? []),
                   mediaProvider: userSession.mediaProvider)
        
        showLoadingIndicator()
        
        clientProxy.ignoredUsersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] blockedUsers in
                guard let blockedUsers else { return }
                Task { await self?.updateUsers(blockedUsers) }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: BlockedUsersScreenViewAction) {
        switch viewAction {
        case .unblockUser(let user):
            state.bindings.alertInfo = .init(id: .unblock,
                                             title: L10n.screenBlockedUsersUnblockAlertTitle,
                                             message: L10n.screenBlockedUsersUnblockAlertDescription,
                                             primaryButton: .init(title: L10n.screenBlockedUsersUnblockAlertAction, role: .destructive) { [weak self] in
                                                 self?.unblockUser(user)
                                             },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        }
    }
    
    func stop() {
        hideLoadingIndicator()
    }
    
    // MARK: - Private
    
    private func updateUsers(_ blockedUsers: [String]) async {
        defer { hideLoadingIndicator() }
        
        if hideProfiles {
            state.blockedUsers = blockedUsers.map { UserProfile(userID: $0) }
        } else {
            state.blockedUsers = await withTaskGroup(of: UserProfile.self) { group in
                for userID in blockedUsers {
                    group.addTask {
                        await self.profile(for: userID)
                    }
                }
                
                var profiles = [UserProfile]()
                for await profile in group {
                    profiles.append(profile)
                }
                return profiles
            }
        }
    }
    
    /// The client proxy isn't Sendable, fetch through this helper so that it
    /// never leaves the main actor when running calls in parallel.
    private func profile(for userID: String) async -> UserProfile {
        switch await clientProxy.profile(for: userID) {
        case .success(let profile): profile
        case .failure: UserProfile(userID: userID)
        }
    }
    
    private func unblockUser(_ user: UserProfile) {
        showLoadingIndicator()
        state.processingUserID = user.id
        
        Task {
            if case .failure = await clientProxy.unignoreUser(user.id) {
                state.bindings.alertInfo = .init(id: .error)
            }
            
            state.processingUserID = nil
            hideLoadingIndicator()
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(BlockedUsersScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: true),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(100))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
