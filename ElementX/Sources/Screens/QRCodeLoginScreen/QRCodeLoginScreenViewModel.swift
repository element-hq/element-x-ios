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
    private let mode: QRCodeLoginScreenMode
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<QRCodeLoginScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<QRCodeLoginScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var currentTask: AnyCancellable?
    private var oidcResultTask: AnyCancellable?
    
    init(mode: QRCodeLoginScreenMode,
         canSignInManually: Bool,
         appMediator: AppMediatorProtocol) {
        self.mode = mode
        self.appMediator = appMediator
        
        let initialState: QRCodeLoginScreenViewState = switch mode {
        case .login:
            .init(state: .loginInstructions, canSignInManually: canSignInManually, isPresentedModally: true)
        case .linkDesktop:
            .init(state: .linkDesktopInstructions, canSignInManually: canSignInManually, isPresentedModally: false)
        case .linkMobile(let progressPublisher):
            switch progressPublisher.value {
            case .qrReady(let image):
                .init(state: .displayQR(image), canSignInManually: canSignInManually, isPresentedModally: false)
            default:
                .init(state: .error(.unknown), canSignInManually: canSignInManually, isPresentedModally: false)
            }
        }
        
        super.init(initialViewState: initialState)
        setupSubscriptions()
        
        if case .linkMobile(let progressPublisher) = mode {
            listenToDisplayQRProgress(progressPublisher: progressPublisher)
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: QRCodeLoginScreenViewAction) {
        switch viewAction {
        case .dismiss, .errorAction(.dismiss):
            actionsSubject.send(.dismiss)
        case .startScan:
            Task { await startScanIfPossible() }
        case .sendCheckCode:
            Task { await sendCheckCode() }
        case .errorAction(.startOver):
            switch mode {
            case .login:
                Task { await startScanIfPossible() }
            case .linkDesktop, .linkMobile:
                actionsSubject.send(.dismiss)
            }
        case .errorAction(.openSettings):
            appMediator.openAppSettings()
        case .errorAction(.signInManually):
            actionsSubject.send(.signInManually)
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        context.$viewState
            // not using compactMap before remove duplicates because if there is an error, and the same
            // code needs to be rescanned the transition to nil to clean the state would get ignored.
            .map(\.bindings.qrResult)
            .removeDuplicates()
            .compactMap { $0 }
            // this needs to be received on the main actor or the state change for connecting won't work properly
            .receive(on: DispatchQueue.main)
            .sink { [weak self] qrData in
                guard let self else { return }
                switch mode {
                case .login(let qrCodeLoginService):
                    handleScan(qrData: qrData, loginService: qrCodeLoginService)
                case .linkDesktop(let linkNewDeviceService):
                    handleScan(qrData: qrData, linkService: linkNewDeviceService)
                case .linkMobile:
                    fatalError("A code should never be scanned when showing one.")
                }
            }
            .store(in: &cancellables)
    }
    
    private func startScanIfPossible() async {
        state.bindings.qrResult = nil
        state.state = await appMediator.requestAuthorizationIfNeeded() ? .scan(.scanning) : .error(.noCameraPermission)
    }
    
    private func handleScan(qrData: Data, loginService: QRCodeLoginServiceProtocol) {
        guard currentTask == nil else { return }
        
        state.state = .scan(.connecting)
        
        MXLog.info("Login scanning QR code")
        let progressPublisher = loginService.loginWithQRCode(data: qrData)
        
        currentTask = progressPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                currentTask = nil
                
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
                    break // Nothing to do, the state was set above.
                case .establishingSecureChannel(_, let stringCode):
                    state.state = .displayCode(.deviceCode(stringCode))
                case .waitingForToken(let code):
                    state.state = .displayCode(.verificationCode(code))
                case .syncingSecrets:
                    break // Nothing to do.
                case .signedIn(let session):
                    MXLog.info("QR Login completed")
                    actionsSubject.send(.signedIn(userSession: session))
                }
            }
    }
    
    // TODO: when user cancels in UI then the underlying login needs to be cancelled too. It's unclear if we have that exposed in the bindings yet.
    
    private func handleScan(qrData: Data, linkService: LinkNewDeviceServiceProtocol) {
        guard currentTask == nil else { return }
        
        state.state = .scan(.connecting)
        
        MXLog.info("Link scanning QR code")
        let progressPublisher = linkService.linkDesktopDevice(with: qrData)
        
        currentTask = progressPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                currentTask = nil
                
                if case .failure(let error) = completion {
                    handleError(error)
                }
            } receiveValue: { [weak self] progress in
                MXLog.info("Linking with QR progress changed to: \(progress)")
                
                guard let self,
                      // Let's not advance the state if the current state is already invalid
                      !state.state.isError else {
                    return
                }
                
                switch progress {
                case .starting:
                    break // Nothing to do, the state was set above.
                case .establishingSecureChannel(let checkCodeString):
                    state.state = .displayCode(.deviceCode(checkCodeString))
                case .waitingForAuthorisation(let url):
                    requestOIDCAuthorization(url: url)
                case .syncingSecrets:
                    break // Nothing to do.
                case .done:
                    MXLog.info("Link with QR code completed.")
                    actionsSubject.send(.linkedDevice)
                }
            }
    }
    
    private func listenToDisplayQRProgress(progressPublisher: LinkNewDeviceService.LinkMobileProgressPublisher) {
        state.bindings.qrResult = nil
            
        MXLog.info("Link showing QR code.")
        
        currentTask = progressPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                currentTask = nil
                
                if case .failure(let error) = completion {
                    handleError(error)
                }
            } receiveValue: { [weak self] progress in
                MXLog.info("Linking with QR progress changed to: \(progress)")
                
                guard let self,
                      // Let's not advance the state if the current state is already invalid
                      !state.state.isError else {
                    return
                }
                
                switch progress {
                case .starting, .qrReady:
                    break // Nothing to do, we are already showing the code by the time this method is called.
                case .qrScanned(let checkCodeSender):
                    state.state = .confirmCode(.inputCode(checkCodeSender))
                case .waitingForAuthorisation(let url):
                    requestOIDCAuthorization(url: url)
                case .syncingSecrets:
                    // break // Nothing to do.
                    // .done is rarely received at the moment, so lets consider linking to be done here.
                    MXLog.info("Link with QR code completed.")
                    actionsSubject.send(.linkedDevice)
                case .done:
                    break // Not necessary right now with the workaround above in place.
                }
            }
    }
    
    private func sendCheckCode() async {
        guard case let .confirmCode(.inputCode(checkCodeSender)) = state.state else {
            fatalError("Attempting to check code from the wrong state.")
        }
        
        let stringValue = state.bindings.checkCodeInput
        let code = UInt8(stringValue) ?? 0
        
        if !checkCodeSender.validate(checkCode: code) {
            MXLog.error("Invalid code entered.")
            state.state = .confirmCode(.invalidCode)
            return
        }
        
        state.state = .confirmCode(.sendingCode)
        
        do {
            MXLog.info("Valid code entered, sending.")
            try await checkCodeSender.send(code: code)
        } catch {
            MXLog.error("Failed to send check code: \(error)")
            handleError(.unknown)
        }
    }
    
    private func requestOIDCAuthorization(url: URL) {
        let (stream, continuation) = AsyncStream<Result<Void, OIDCError>>.makeStream()
        actionsSubject.send(.requestOIDCAuthorisation(url, continuation))
        
        oidcResultTask = Task { [weak self] in
            for await result in stream {
                guard let self else { return }
                switch result {
                case .success:
                    break // The state will be updated by the status publisher.
                case .failure(.userCancellation):
                    MXLog.info("User cancelled the WAS, dismissing.")
                    actionsSubject.send(.dismiss)
                case .failure:
                    handleError(.unknown)
                }
            }
        }
        .asCancellable()
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
        case .deviceAlreadySignedIn:
            state.state = .error(.deviceAlreadySignedIn)
        case .unknown:
            state.state = .error(.unknown)
        }
    }
        
    /// Only for mocking initial states
    fileprivate init(state: QRCodeLoginState, canSignInManually: Bool, isPresentedModally: Bool, checkCodeInput: String) {
        mode = .login(QRCodeLoginServiceMock())
        appMediator = AppMediatorMock.default
        super.init(initialViewState: .init(state: state,
                                           canSignInManually: canSignInManually,
                                           isPresentedModally: isPresentedModally,
                                           bindings: .init(checkCodeInput: checkCodeInput)))
    }
}

extension QRCodeLoginScreenViewModel {
    static func mock(state: QRCodeLoginState,
                     canSignInManually: Bool = true,
                     isPresentedModally: Bool = true,
                     checkCodeInput: String = "") -> QRCodeLoginScreenViewModel {
        QRCodeLoginScreenViewModel(state: state,
                                   canSignInManually: canSignInManually,
                                   isPresentedModally: isPresentedModally,
                                   checkCodeInput: checkCodeInput)
    }
}
