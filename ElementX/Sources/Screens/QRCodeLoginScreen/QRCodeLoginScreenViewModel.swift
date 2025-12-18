//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
         canSignInManually: Bool,
         appMediator: AppMediatorProtocol) {
        self.qrCodeLoginService = qrCodeLoginService
        self.appMediator = appMediator
        super.init(initialViewState: QRCodeLoginScreenViewState(canSignInManually: canSignInManually))
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: QRCodeLoginScreenViewAction) {
        switch viewAction {
        case .cancel, .errorAction(.cancel):
            actionsSubject.send(.cancel)
        case .startScan, .errorAction(.startScan):
            Task { await startScanIfPossible() }
        case .errorAction(.openSettings):
            appMediator.openAppSettings()
        case .errorAction(.signInManually):
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
    }
    
    private func startScanIfPossible() async {
        state.bindings.qrResult = nil
        state.state = await appMediator.requestAuthorizationIfNeeded() ? .scan(.scanning) : .error(.noCameraPermission)
    }
    
    private func handleScan(qrData: Data) {
        guard scanTask == nil else { return }
        
        state.state = .scan(.connecting)
        
        scanTask = Task { [weak self] in
            guard let self else { return }
            defer { scanTask = nil }
            
            let progressPublisher = qrCodeLoginService.loginWithQRCode(data: qrData)
            
            progressPublisher
                // .removeDuplicates() FIXME: not Equatable
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self else { return }
                    
                    switch completion {
                    case .finished: break
                    case .failure(.qrCodeError(let error)):
                        handleError(error)
                    case .failure:
                        handleError(.unknown)
                    }
                } receiveValue: { [weak self] progress in
                    MXLog.info("QR Login Progress changed to: \(progress)")
                    
                    guard let self,
                          // Let's not advance the state if the current state is already invalid
                          !state.state.isError else {
                        return
                    }
                    
                    switch progress {
                    case .starting:
                        break // The UI is updated above, nothing to do.
                    case .establishingSecureChannel(_, let stringCode):
                        state.state = .displayCode(.deviceCode(stringCode))
                    case .waitingForToken(let code):
                        state.state = .displayCode(.verificationCode(code))
                    case .syncingSecrets:
                        break // Nothing to do.
                    case .done(let session):
                        MXLog.info("QR Login completed")
                        actionsSubject.send(.done(userSession: session))
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func handleError(_ error: QRCodeLoginError) {
        MXLog.error("Failed to scan the QR code: \(error)")
        switch error {
        case .invalidQRCode:
            state.state = .scan(.scanFailed(.invalid))
        case .providerNotAllowed(let scannedProvider, let allowedProviders):
            state.state = .scan(.scanFailed(.notAllowed(scannedProvider: scannedProvider, allowedProviders: allowedProviders)))
        case .deviceNotSignedIn:
            state.state = .scan(.scanFailed(.deviceNotSignedIn))
        case .deviceAlreadySignedIn:
            state.state = .error(.deviceAlreadySignedIn)
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
        case .unknown:
            state.state = .error(.unknown)
        }
    }
        
    /// Only for mocking initial states
    fileprivate init(state: QRCodeLoginState, canSignInManually: Bool) {
        qrCodeLoginService = QRCodeLoginServiceMock()
        appMediator = AppMediatorMock.default
        super.init(initialViewState: .init(state: state, canSignInManually: canSignInManually))
    }
}

extension QRCodeLoginScreenViewModel {
    static func mock(state: QRCodeLoginState, canSignInManually: Bool = true) -> QRCodeLoginScreenViewModel {
        QRCodeLoginScreenViewModel(state: state, canSignInManually: canSignInManually)
    }
}
