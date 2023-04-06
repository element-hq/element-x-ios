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

typealias InvitesListViewModelType = StateStoreViewModel<InvitesListViewState, InvitesListViewAction>

class InvitesListViewModel: InvitesListViewModelType, InvitesListViewModelProtocol {
    private var actionsSubject: PassthroughSubject<InvitesListViewModelAction, Never> = .init()
    private let invitesSummaryProvider: RoomSummaryProviderProtocol?
    
    var actions: AnyPublisher<InvitesListViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol) {
        invitesSummaryProvider = userSession.clientProxy.invitesSummaryProvider
        
        super.init(initialViewState: InvitesListViewState())
        
        guard let invitesSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        invitesSummaryProvider.roomListPublisher
            .weakAssign(to: \.state.roomSummaries, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: InvitesListViewAction) { }
}
