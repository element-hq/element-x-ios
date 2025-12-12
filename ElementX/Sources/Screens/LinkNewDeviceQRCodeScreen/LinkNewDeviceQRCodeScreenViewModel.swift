//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

typealias LinkNewDeviceQRCodeScreenViewModelType = StateStoreViewModel<LinkNewDeviceQRCodeScreenViewState, LinkNewDeviceQRCodeScreenViewAction>

class LinkNewDeviceQRCodeScreenViewModel: LinkNewDeviceQRCodeScreenViewModelType, LinkNewDeviceQRCodeScreenViewModelProtocol {
    private let linkNewDeviceService: LinkNewDeviceService
    private let appMediator: AppMediatorProtocol
    
    private let actionsSubject: PassthroughSubject<LinkNewDeviceQRCodeScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceQRCodeScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var linkNewDeviceTask: Task<Void, Never>?

    init(mode: LinkNewDeviceQRCodeScreenMode,
         linkNewDeviceService: LinkNewDeviceService,
         appMediator: AppMediatorProtocol) {
        self.linkNewDeviceService = linkNewDeviceService
        self.appMediator = appMediator
        
        let initialState: LinkNewDeviceQRCodeState = switch mode {
        case .scanQRCode:
            .scanInstructions
        case .generateQRCode(let progressPublisher):
            switch progressPublisher.value {
            case .qrReady(let image):
                .displayQR(image)
            default:
                .error(.unknown)
            }
        }
        
        super.init(initialViewState: LinkNewDeviceQRCodeScreenViewState(state: initialState))
        setupSubscriptions()
        
        if case .generateQRCode(let progressPublisher) = mode {
            startShowQRIfPossible(progressPublisher: progressPublisher)
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: LinkNewDeviceQRCodeScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .startScan:
            Task { await startScanIfPossible() }
        case .startOver:
            actionsSubject.send(.cancel)
        case .checkCodeInput:
            Task { await checkCodeInput() }
        case .openSettings:
            appMediator.openAppSettings()
        }
    }
    
    // MARK: - Private
    
    // TODO: when user cancels in UI then the underlying login needs to be cancelled too. It's unclear if we have that exposed in the bindings yet.

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

    private func startShowQRIfPossible(progressPublisher: LinkNewDeviceService.GenerateProgressPublisher) {
        state.bindings.qrResult = nil
        
        linkNewDeviceTask = Task { [weak self] in
            guard let self else { return }
            defer { linkNewDeviceTask = nil }
            
            MXLog.info("Generating QR code")
            progressPublisher
                // .removeDuplicates() FIXME: not Equatable
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self else { return }
                    if case .failure(let error) = completion {
                        handleError(error)
                    }
                } receiveValue: { [weak self] progress in
                    MXLog.info("QR Login Progress changed to: \(progress)")

                    guard let self,
                          // Let's not advance the state if the current state is already invalid
                          !state.state.isError else {
                        return
                    }
                    
                    switch progress {
                    case .starting, .qrReady:
                        break // These should have already happened so don't need any processing.
                    case .qrScanned(let checkCodeSender):
                        state.state = .checkCode(checkCodeSender)
                    case .waitingForAuthorisation(let url):
                        actionsSubject.send(.requestOIDCAuthorisation(url))
                    case .syncingSecrets:
                        break // Nothing to do.
                    case .done:
                        MXLog.info("QR Reciprocate completed")
                        actionsSubject.send(.done)
                    }
                }
                .store(in: &cancellables)
        }
    }

    private func startScanIfPossible() async {
        state.bindings.qrResult = nil
        state.state = await appMediator.requestAuthorizationIfNeeded() ? .scan(.scanning) : .error(.noCameraPermission)
    }

    private func checkCodeInput() async {
        if let checkCodeSender = state.state.checkCodeSender {
            let stringValue = state.bindings.checkCodeInput
            let code = UInt8(stringValue) ?? 0
            state.state = .checkCode(checkCodeSender)
            // we only send if validated above
            do {
                try await checkCodeSender.send(code: code)
            } catch {
                MXLog.error("Failed to send check code: \(error)")
                handleError(.unknown)
            }
        }
    }

    private func handleScan(qrData: Data) {
        guard linkNewDeviceTask == nil else { return }
        
        state.state = .scan(.connecting)
        
        linkNewDeviceTask = Task { [weak self] in
            guard let self else { return }
            defer { linkNewDeviceTask = nil }
            
            MXLog.info("Scanning QR code: \(qrData)")
            let progressPublisher = linkNewDeviceService.scanQRCode(qrData)
            
            progressPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self else { return }
                    if case .failure(let error) = completion {
                        handleError(error)
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
                        break // TODO: How long does this take, should we show a spinner/disable the button etc?
                    case .establishingSecureChannel(_, let stringCode):
                        state.state = .displayCode(.deviceCode(stringCode))
                    case .waitingForAuthorisation(let url):
                        actionsSubject.send(.requestOIDCAuthorisation(url))
                    case .syncingSecrets:
                        break // Nothing to do.
                    case .done:
                        MXLog.info("QR Reciprocate completed")
                        actionsSubject.send(.done)
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
        // these are not applicable to reciprocate so map these to unknown:
        case .providerNotAllowed, .deviceNotSignedIn, .unknown:
            state.state = .error(.unknown)
        }
    }
        
    /// Only for mocking initial states
    fileprivate init(state: LinkNewDeviceQRCodeState) {
        linkNewDeviceService = LinkNewDeviceService(handler: GrantLoginWithQrCodeHandlerSDKMock(.init()))
        appMediator = AppMediatorMock.default
        super.init(initialViewState: .init(state: state))
    }
}

extension LinkNewDeviceQRCodeScreenViewModel {
    static func mock(state: LinkNewDeviceQRCodeState) -> LinkNewDeviceQRCodeScreenViewModel {
        LinkNewDeviceQRCodeScreenViewModel(state: state)
    }
}
