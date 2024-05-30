//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

typealias BlockedUsersScreenViewModelType = StateStoreViewModel<BlockedUsersScreenViewState, BlockedUsersScreenViewAction>

class BlockedUsersScreenViewModel: BlockedUsersScreenViewModelType, BlockedUsersScreenViewModelProtocol {
    let hideProfiles: Bool
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol

    init(hideProfiles: Bool,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.hideProfiles = hideProfiles
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        let ignoredUsers = clientProxy.ignoredUsersPublisher.value?.map { UserProfileProxy(userID: $0) }
        
        super.init(initialViewState: BlockedUsersScreenViewState(blockedUsers: ignoredUsers ?? []),
                   imageProvider: mediaProvider)
        
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
            state.blockedUsers = blockedUsers.map { UserProfileProxy(userID: $0) }
        } else {
            state.blockedUsers = await withTaskGroup(of: UserProfileProxy.self) { group in
                for userID in blockedUsers {
                    group.addTask {
                        switch await self.clientProxy.profile(for: userID) {
                        case .success(let profile): profile
                        case .failure: UserProfileProxy(userID: userID)
                        }
                    }
                }
                
                return await group.reduce(into: []) { partialResult, profile in
                    partialResult.append(profile)
                }
            }
        }
    }
    
    private func unblockUser(_ user: UserProfileProxy) {
        showLoadingIndicator()
        state.processingUserID = user.userID
        
        Task {
            if case .failure = await clientProxy.unignoreUser(user.userID) {
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
