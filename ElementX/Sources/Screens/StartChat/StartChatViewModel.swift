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

typealias StartChatViewModelType = StateStoreViewModel<StartChatViewState, StartChatViewAction>

class StartChatViewModel: StartChatViewModelType, StartChatViewModelProtocol {
    private let userSession: UserSessionProtocol
    
    var callback: ((StartChatViewModelAction) -> Void)?
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    init(userSession: UserSessionProtocol, userIndicatorController: UserIndicatorControllerProtocol?) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: StartChatViewState(), imageProvider: userSession.mediaProvider)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: StartChatViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .createRoom:
            callback?(.createRoom)
        case .inviteFriends:
            break
        case .selectUser(let user):
            showLoadingIndicator()
            Task {
                let currentDirectRoom = await userSession.clientProxy.directRoomForUserIdentifier(user.userId)
                switch currentDirectRoom {
                case .success(.some(let roomId)):
                    self.hideLoadingIndicator()
                    self.callback?(.openRoom(withIdentifier: roomId))
                case .success(nil):
                    await self.createDirectRoom(with: user)
                case .failure(let failure):
                    self.hideLoadingIndicator()
                    self.displayError(failure)
                }
            }
        }
    }
    
    func displayError(_ type: ClientProxyError) {
        switch type {
        case .failedRetrievingDirectRoom:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: ElementL10n.retrievingDirectRoomError)
        case .failedCreatingRoom:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: ElementL10n.retrievingDirectRoomError)
        default:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
    
    // MARK: - Private
    
    private func setupBindings() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] searchQuery in
                if MatrixEntityRegex.isMatrixUserIdentifier(searchQuery) {
                    self?.state.searchResults = [UserProfileProxy(userId: searchQuery, displayName: nil, avatarURL: nil)]
                } else {
                    self?.state.searchResults = []
                }
            })
            .store(in: &cancellables)
    }
    
    private func createDirectRoom(with user: UserProfileProxyProtocol) async {
        showLoadingIndicator()
        let result = await userSession.clientProxy.createDirectRoom(with: user.userId)
        hideLoadingIndicator()
        switch result {
        case .success(let roomId):
            callback?(.openRoom(withIdentifier: roomId))
        case .failure(let failure):
            displayError(failure)
        }
    }
    
    // MARK: Loading indicator
    
    static let loadingIndicatorIdentifier = "StartChatLoading"
    
    private func showLoadingIndicator() {
        userIndicatorController?.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                               type: .modal,
                                                               title: ElementL10n.loading,
                                                               persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
