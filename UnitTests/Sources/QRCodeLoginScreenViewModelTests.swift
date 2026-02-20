//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDKMocks
import Testing

@Suite
@MainActor
struct QRCodeLoginScreenViewModelTests {
    private enum Mode { case login, linkDesktop, linkMobile }
    
    var qrLoginProgressSubject: CurrentValueSubject<QRLoginProgress, AuthenticationServiceError>!
    var qrCodeLoginService: QRCodeLoginServiceMock!
    
    var linkMobileProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>!
    var linkDesktopProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkDesktopProgress, QRCodeLoginError>!
    var linkNewDeviceService: LinkNewDeviceServiceMock!
    
    var appMediator: AppMediatorMock!
    
    var viewModel: QRCodeLoginScreenViewModelProtocol!
    var context: QRCodeLoginScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test
    mutating func loginInitialState() {
        setup(mode: .login)
        
        #expect(context.viewState.state == .loginInstructions)
        #expect(context.qrResult == nil)
        #expect(!qrCodeLoginService.loginWithQRCodeDataCalled)
        #expect(!appMediator.requestAuthorizationIfNeededCalled)
        #expect(!appMediator.openAppSettingsCalled)
        
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
        #expect(!linkNewDeviceService.linkDesktopDeviceWithCalled)
    }
    
    @Test
    mutating func linkDesktopInitialState() {
        setup(mode: .linkDesktop)
        
        #expect(context.viewState.state == .linkDesktopInstructions)
        #expect(context.qrResult == nil)
        #expect(!linkNewDeviceService.linkDesktopDeviceWithCalled)
        #expect(!appMediator.requestAuthorizationIfNeededCalled)
        #expect(!appMediator.openAppSettingsCalled)
        
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
        #expect(!qrCodeLoginService.loginWithQRCodeDataCalled)
    }
    
    @Test
    mutating func linkMobileInitialState() {
        setup(mode: .linkMobile)
        
        #expect(context.viewState.state.isDisplayQR)
        #expect(linkNewDeviceService.linkMobileDeviceCalled)
        
        #expect(!linkNewDeviceService.linkDesktopDeviceWithCalled)
        #expect(!qrCodeLoginService.loginWithQRCodeDataCalled)
        #expect(context.qrResult == nil)
    }
    
    @Test
    mutating func requestCameraPermission() async throws {
        setup(mode: .login)
        appMediator.requestAuthorizationIfNeededReturnValue = false
        #expect(context.viewState.state == .loginInstructions)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.state == .error(.noCameraPermission)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        #expect(appMediator.requestAuthorizationIfNeededCalled)
        
        context.send(viewAction: .errorAction(.openSettings))
        await Task.yield()
        #expect(appMediator.openAppSettingsCalled)
        #expect(context.qrResult == nil)
    }
    
    @Test
    mutating func login() async throws {
        setup(mode: .login)
        #expect(context.viewState.state == .loginInstructions)
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.state == .scan(.scanning)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        #expect(appMediator.requestAuthorizationIfNeededCalled)
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.state == .scan(.connecting)
        }
        context.qrResult = .init()
        try await deferred.fulfill()

        deferred = deferFulfillment(context.$viewState) { state in
            state.state == .displayCode(.deviceCode("01"))
        }
        qrLoginProgressSubject.send(.establishingSecureChannel(checkCode: 1, checkCodeString: "01"))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.state == .displayCode(.verificationCode("ABCDEF"))
        }
        qrLoginProgressSubject.send(.waitingForToken(userCode: "ABCDEF"))
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .signedIn: true
            default: false
            }
        }
        qrLoginProgressSubject.send(.signedIn(UserSessionMock(.init(clientProxy: ClientProxyMock()))))
        try await deferredAction.fulfill()
    }
    
    @Test
    mutating func linkDesktopComputer() async throws {
        setup(mode: .linkDesktop)
        #expect(context.viewState.state == .linkDesktopInstructions)
        
        var deferred = deferFulfillment(context.$viewState) { $0.state == .scan(.scanning) }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        #expect(appMediator.requestAuthorizationIfNeededCalled)
        
        deferred = deferFulfillment(context.$viewState) { $0.state == .scan(.connecting) }
        context.qrResult = .init()
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { $0.state == .displayCode(.deviceCode("01")) }
        linkDesktopProgressSubject.send(.establishingSecureChannel(checkCodeString: "01"))
        try await deferred.fulfill()
        
        var deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            guard case .requestOIDCAuthorisation = action else { return false }
            return true
        }
        linkDesktopProgressSubject.send(.waitingForAuthorisation(verificationURL: .homeDirectory))
        try await deferredAction.fulfill()
        
        let currentState = context.viewState.state
        let deferredFailure = deferFailure(context.$viewState, timeout: .seconds(1)) { $0.state != currentState }
        linkDesktopProgressSubject.send(.syncingSecrets)
        try await deferredFailure.fulfill()
        
        deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            guard case .linkedDevice = action else { return false }
            return true
        }
        linkDesktopProgressSubject.send(.done)
        try await deferredAction.fulfill()
    }
    
    @Test
    mutating func linkMobileDevice() async throws {
        setup(mode: .linkMobile)
        #expect(context.viewState.state.isDisplayQR)
        
        let checkCodeSender = CheckCodeSenderSDKMock()
        let checkCodeSenderProxy = CheckCodeSenderProxy(underlyingSender: checkCodeSender)
        var deferredState = deferFulfillment(context.$viewState) { $0.state == .confirmCode(.inputCode(checkCodeSenderProxy)) }
        linkMobileProgressSubject.send(.qrScanned(checkCodeSenderProxy))
        try await deferredState.fulfill()
        
        deferredState = deferFulfillment(context.$viewState) { $0.state == .confirmCode(.sendingCode) }
        context.checkCodeInput = "01"
        context.send(viewAction: .sendCheckCode)
        try await deferredState.fulfill()
        
        var deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            guard case .requestOIDCAuthorisation = action else { return false }
            return true
        }
        linkMobileProgressSubject.send(.waitingForAuthorisation(verificationURL: .homeDirectory))
        try await deferredAction.fulfill()
        
        // Note: The SDK rarely sends the done action, so this test has been updated for the workaround of finishing early.
        deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            guard case .linkedDevice = action else { return false }
            return true
        }
        linkMobileProgressSubject.send(.syncingSecrets)
        try await deferredAction.fulfill()
        
        let currentState = context.viewState.state
        let deferredFailure = deferFailure(context.$viewState, timeout: .seconds(1)) { $0.state != currentState }
        linkMobileProgressSubject.send(.done)
        try await deferredFailure.fulfill()
    }
    
    // MARK: - Helpers
    
    private mutating func setup(mode: Mode) {
        qrLoginProgressSubject = .init(.starting)
        qrCodeLoginService = QRCodeLoginServiceMock()
        qrCodeLoginService.loginWithQRCodeDataReturnValue = qrLoginProgressSubject.asCurrentValuePublisher()
        
        linkMobileProgressSubject = .init(.qrReady(LinkNewDeviceServiceMock.mockQRCodeImage))
        linkDesktopProgressSubject = .init(.starting)
        linkNewDeviceService = LinkNewDeviceServiceMock(.init(linkMobileProgressPublisher: linkMobileProgressSubject.asCurrentValuePublisher(),
                                                              linkDesktopProgressPublisher: linkDesktopProgressSubject.asCurrentValuePublisher()))
        
        let screenMode: QRCodeLoginScreenMode
        switch mode {
        case .login:
            screenMode = .login(qrCodeLoginService)
        case .linkDesktop:
            screenMode = .linkDesktop(linkNewDeviceService)
        case .linkMobile:
            screenMode = .linkMobile(linkNewDeviceService.linkMobileDevice())
        }
        
        appMediator = AppMediatorMock.default
        viewModel = QRCodeLoginScreenViewModel(mode: screenMode,
                                               canSignInManually: true,
                                               appMediator: appMediator)
    }
}
