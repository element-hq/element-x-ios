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
import MatrixRustSDK
import SwiftUI

typealias RoomChangePermissionsScreenViewModelType = StateStoreViewModel<RoomChangePermissionsScreenViewState, RoomChangePermissionsScreenViewAction>

class RoomChangePermissionsScreenViewModel: RoomChangePermissionsScreenViewModelType, RoomChangePermissionsScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private var actionsSubject: PassthroughSubject<RoomChangePermissionsScreenViewModelAction, Never> = .init()
    
    var actionsPublisher: AnyPublisher<RoomChangePermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(currentPermissions: RoomPermissions,
         group: RoomRolesAndPermissionsScreenPermissionsGroup,
         roomProxy: RoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: .init(currentPermissions: currentPermissions, group: group))
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomChangePermissionsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            Task { await save() }
        }
    }
    
    // MARK: - Private
    
    private func save() async {
        guard state.hasChanges else {
            MXLog.warning("Nothing to save.")
            return
        }
        
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        var changes = RoomPowerLevelChanges()
        for setting in state.bindings.settings {
            changes[keyPath: setting.rustKeyPath] = setting.value.rustPowerLevel
        }
        
        switch await roomProxy.applyPowerLevelChanges(changes) {
        case .success:
            MXLog.info("Success")
            actionsSubject.send(.complete)
        case .failure:
            context.alertInfo = AlertInfo(id: .generic)
            return
        }
    }
    
    // MARK: Loading indicator
    
    private static let indicatorID = "SavingRoomPermissions"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.indicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonSaving,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.indicatorID)
    }
}
