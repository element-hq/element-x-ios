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

typealias ReportContentViewModelType = StateStoreViewModel<ReportContentViewState, ReportContentViewAction>

class ReportContentViewModel: ReportContentViewModelType, ReportContentViewModelProtocol {
    private let itemID: String
    private let senderID: String
    private let roomProxy: RoomProxyProtocol
    private let callbackSubject: PassthroughSubject<ReportContentViewModelAction, Never> = .init()
    
    var callbackPublisher: AnyPublisher<ReportContentViewModelAction, Never> {
        callbackSubject.eraseToAnyPublisher()
    }

    init(itemID: String, senderID: String, roomProxy: RoomProxyProtocol) {
        self.itemID = itemID
        self.senderID = senderID
        self.roomProxy = roomProxy
        
        super.init(initialViewState: ReportContentViewState(bindings: ReportContentViewStateBindings(reasonText: "", ignoreUser: false)))
    }

    // MARK: - Public
    
    override func process(viewAction: ReportContentViewAction) {
        switch viewAction {
        case .cancel:
            callbackSubject.send(.cancel)
        case .submit:
            Task { await submitReport() }
        }
    }

    // MARK: Private

    private func submitReport() async {
        callbackSubject.send(.submitStarted)
        
        if case let .failure(error) = await roomProxy.reportContent(itemID, reason: state.bindings.reasonText) {
            MXLog.error("Submit Report Content failed: \(error)")
            callbackSubject.send(.submitFailed(error: error))
            return
        }
        
        // Ignore the sender if the user wants to.
        if state.bindings.ignoreUser, case let .failure(error) = await roomProxy.ignoreUser(senderID) {
            MXLog.error("Ignore user failed: \(error)")
            callbackSubject.send(.submitFailed(error: error))
            return
        }
        
        MXLog.info("Submit Report Content succeeded")
        callbackSubject.send(.submitFinished)
    }
}
