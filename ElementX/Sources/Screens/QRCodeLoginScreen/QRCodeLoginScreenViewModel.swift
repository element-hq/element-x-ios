//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

typealias QRCodeLoginScreenViewModelType = StateStoreViewModel<QRCodeLoginScreenViewState, QRCodeLoginScreenViewAction>

class QRCodeLoginScreenViewModel: QRCodeLoginScreenViewModelType, QRCodeLoginScreenViewModelProtocol {
    private let qrCodeLoginService: QRCodeLoginServiceProtocol
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<QRCodeLoginScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<QRCodeLoginScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var scanTask: Task<Void, Never>?

    init(qrCodeLoginService: QRCodeLoginServiceProtocol,
         appMediator: AppMediatorProtocol) {
        self.qrCodeLoginService = qrCodeLoginService
        self.appMediator = appMediator
        super.init(initialViewState: QRCodeLoginScreenViewState())
        setupSubscriptions()
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
        case .signInManually:
            actionsSubject.send(.signInManually)
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        context.$viewState
            // not using compactMap before remove duplicates because if there is an error, and the same code needs to be rescanned the transition to nil to clean the state would get ignored.
            .map(\.bindings.qrResult)
            .removeDuplicates()
            .compactMap { $0 }
            // this needs to be received on the main actor or the state change for connecting won't work properly
            .receive(on: DispatchQueue.main)
            .sink { [weak self] qrData in
                self?.handleScan(qrData: qrData)
            }
            .store(in: &cancellables)
        
        qrCodeLoginService.qrLoginProgressPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                MXLog.info("QR Login Progress changed to: \(progress)")

                guard let self,
                      // Let's not advance the state if the current state is already invalid
                      !state.state.isError else {
                    return
                }
                
                switch progress {
                case .establishingSecureChannel(_, let stringCode):
                    state.state = .displayCode(.deviceCode(stringCode))
                case .waitingForToken(let code):
                    state.state = .displayCode(.verificationCode(code))
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func startScanIfPossible() async {
        state.bindings.qrResult = nil
        state.state = await appMediator.requestAuthorizationIfNeeded() ? .scan(.scanning) : .error(.noCameraPermission)
    }
    
    private func handleScan(qrData: Data) {
        guard scanTask == nil else {
            return
        }
        
        state.state = .scan(.connecting)
        
        scanTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            defer {
                scanTask = nil
            }
            
            MXLog.info("Scanning QR code: \(qrData)")
            switch await qrCodeLoginService.loginWithQRCode(data: qrData) {
            case let .success(session):
                MXLog.info("QR Login completed")
                actionsSubject.send(.done(userSession: session))
            case .failure(let error):
                handleError(error: error)
            }
        }
    }
    
    private func handleError(error: QRCodeLoginServiceError) {
        MXLog.error("Failed to scan the QR code: \(error)")
        switch error {
        case .invalidQRCode:
            state.state = .scan(.invalid)
        case .deviceNotSignedIn:
            state.state = .scan(.deviceNotSignedIn)
        case .cancelled:
            state.state = .error(.cancelled)
        case .connectionInsecure:
            state.state = .error(.connectionNotSecure)
        case .declined:
            state.state = .error(.declined)
        case .linkingNotSupported:
            state.state = .error(.linkingNotSupported)
        case .expired:
            state.state = .error(.expired)
        case .deviceNotSupported:
            state.state = .error(.deviceNotSupported)
        case .failedLoggingIn, .unknown:
            state.state = .error(.unknown)
        }
    }
        
    /// Only for mocking initial states
    fileprivate init(state: QRCodeLoginState) {
        qrCodeLoginService = QRCodeLoginServiceMock()
        appMediator = AppMediatorMock.default
        super.init(initialViewState: .init(state: state))
    }
}

extension QRCodeLoginScreenViewModel {
    static func mock(state: QRCodeLoginState) -> QRCodeLoginScreenViewModel {
        QRCodeLoginScreenViewModel(state: state)
    }
}
