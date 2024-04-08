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
    private let qrCodeLoginController: QRCodeLoginControllerProtocol
    
    private let actionsSubject: PassthroughSubject<QRCodeLoginScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<QRCodeLoginScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(qrCodeLoginController: QRCodeLoginControllerProtocol) {
        self.qrCodeLoginController = qrCodeLoginController
        super.init(initialViewState: QRCodeLoginScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: QRCodeLoginScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .startScan:
            Task { await startScanIfPossible() }
        }
    }
    
    private func startScanIfPossible() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Determine if the user previously authorized camera access.
        var isAuthorized = status == .authorized
        
        // If the system hasn't determined the user's authorization status,
        // explicitly prompt them for approval.
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        state.state = isAuthorized ? .scanning : .error(.noCameraPermission)
    }
}
