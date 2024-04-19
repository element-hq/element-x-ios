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

import AVFoundation
import Combine
import SwiftUI

typealias QRCodeLoginScreenViewModelType = StateStoreViewModel<QRCodeLoginScreenViewState, QRCodeLoginScreenViewAction>

class QRCodeLoginScreenViewModel: QRCodeLoginScreenViewModelType, QRCodeLoginScreenViewModelProtocol {
    private let qrCodeLoginService: QRCodeLoginServiceProtocol
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<QRCodeLoginScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<QRCodeLoginScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(qrCodeLoginService: QRCodeLoginServiceProtocol,
         appMediator: AppMediatorProtocol) {
        self.qrCodeLoginService = qrCodeLoginService
        self.appMediator = appMediator
        super.init(initialViewState: QRCodeLoginScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: QRCodeLoginScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .startScan:
            Task { await startScanIfPossible() }
        case .openSettings:
            appMediator.openAppSettings()
        }
    }
    
    private func startScanIfPossible() async {
        state.state = await qrCodeLoginService.requestAuthorizationIfNeeded() ? .scan(.scanning) : .error(.noCameraPermission)
    }
    
    /// Only for mocking initial states
    fileprivate init(state: QRCodeLoginState) {
        qrCodeLoginService = QRCodeLoginServiceMock(configuration: .init())
        appMediator = AppMediatorMock.default
        super.init(initialViewState: .init(state: state))
    }
}

extension QRCodeLoginScreenViewModel {
    static func mock(state: QRCodeLoginState) -> QRCodeLoginScreenViewModel {
        QRCodeLoginScreenViewModel(state: state)
    }
}
