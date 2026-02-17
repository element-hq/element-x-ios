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

@MainActor
@Suite
struct QRCodeLoginScreenViewModelTests {
    private enum Mode { case login, linkDesktop, linkMobile }
    
    @MainActor
    private struct TestSetup {
        var qrLoginProgressSubject: CurrentValueSubject<QRLoginProgress, AuthenticationServiceError>
        var qrCodeLoginService: QRCodeLoginServiceMock
        
        var linkMobileProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>
        var linkDesktopProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkDesktopProgress, QRCodeLoginError>
        var linkNewDeviceService: LinkNewDeviceServiceMock
        
        var appMediator: AppMediatorMock
        
        var viewModel: QRCodeLoginScreenViewModelProtocol
        var context: QRCodeLoginScreenViewModelType.Context {
            viewModel.context
        }
        
        init(mode: Mode) {
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
    
    @Test
    func loginInitialState() {
        let testSetup = TestSetup(mode: .login)
        
        #expect(testSetup.context.viewState.state == .loginInstructions)
        #expect(testSetup.context.qrResult == nil)
        #expect(!testSetup.qrCodeLoginService.loginWithQRCodeDataCalled)
        #expect(!testSetup.appMediator.requestAuthorizationIfNeededCalled)
        #expect(!testSetup.appMediator.openAppSettingsCalled)
        
        #expect(!testSetup.linkNewDeviceService.linkMobileDeviceCalled)
        #expect(!testSetup.linkNewDeviceService.linkDesktopDeviceWithCalled)
    }
    
    @Test
    func linkDesktopInitialState() {
        let testSetup = TestSetup(mode: .linkDesktop)
        
        #expect(testSetup.context.viewState.state == .linkDesktopInstructions)
        #expect(testSetup.context.qrResult == nil)
        #expect(!testSetup.linkNewDeviceService.linkDesktopDeviceWithCalled)
        #expect(!testSetup.appMediator.requestAuthorizationIfNeededCalled)
        #expect(!testSetup.appMediator.openAppSettingsCalled)
        
        #expect(!testSetup.linkNewDeviceService.linkMobileDeviceCalled)
        #expect(!testSetup.qrCodeLoginService.loginWithQRCodeDataCalled)
    }
    
    @Test
    func linkMobileInitialState() {
        let testSetup = TestSetup(mode: .linkMobile)
        
        #expect(testSetup.context.viewState.state.isDisplayQR)
        #expect(testSetup.linkNewDeviceService.linkMobileDeviceCalled)
        
        #expect(!testSetup.linkNewDeviceService.linkDesktopDeviceWithCalled)
        #expect(!testSetup.qrCodeLoginService.loginWithQRCodeDataCalled)
        #expect(testSetup.context.qrResult == nil)
    }
    
    @Test
    func requestCameraPermission() async throws {
        var testSetup = TestSetup(mode: .login)
        testSetup.appMediator.requestAuthorizationIfNeededReturnValue = false
        #expect(testSetup.context.viewState.state == .loginInstructions)
        
        let deferred = deferFulfillment(testSetup.viewModel.context.$viewState) { state in
            state.state == .error(.noCameraPermission)
        }
        testSetup.context.send(viewAction: .startScan)
        try await deferred.fulfill()
        #expect(testSetup.appMediator.requestAuthorizationIfNeededCalled)
        
        testSetup.context.send(viewAction: .errorAction(.openSettings))
        await Task.yield()
        #expect(testSetup.appMediator.openAppSettingsCalled)
        #expect(testSetup.context.qrResult == nil)
    }
    
    @Test
    func login() async throws {
        var testSetup = TestSetup(mode: .login)
        #expect(testSetup.context.viewState.state == .loginInstructions)
        
        var deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.state == .scan(.scanning)
        }
        testSetup.context.send(viewAction: .startScan)
        try await deferred.fulfill()
        #expect(testSetup.appMediator.requestAuthorizationIfNeededCalled)
        
        deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.state == .scan(.connecting)
        }
        testSetup.context.qrResult = .init()
        try await deferred.fulfill()

        deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.state == .displayCode(.deviceCode("01"))
        }
        testSetup.qrLoginProgressSubject.send(.establishingSecureChannel(checkCode: 1, checkCodeString: "01"))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(testSetup.context.$viewState) { state in
            state.state == .displayCode(.verificationCode("ABCDEF"))
        }
        testSetup.qrLoginProgressSubject.send(.waitingForToken(userCode: "ABCDEF"))
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
            switch action {
            case .signedIn: true
            default: false
            }
        }
        testSetup.qrLoginProgressSubject.send(.signedIn(UserSessionMock(.init(clientProxy: ClientProxyMock()))))
        try await deferredAction.fulfill()
    }
    
    @Test
    func linkDesktopComputer() async throws {
        var testSetup = TestSetup(mode: .linkDesktop)
        #expect(testSetup.context.viewState.state == .linkDesktopInstructions)
        
        var deferred = deferFulfillment(testSetup.context.$viewState) { $0.state == .scan(.scanning) }
        testSetup.context.send(viewAction: .startScan)
        try await deferred.fulfill()
        #expect(testSetup.appMediator.requestAuthorizationIfNeededCalled)
        
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.state == .scan(.connecting) }
        testSetup.context.qrResult = .init()
        try await deferred.fulfill()
        
        deferred = deferFulfillment(testSetup.context.$viewState) { $0.state == .displayCode(.deviceCode("01")) }
        testSetup.linkDesktopProgressSubject.send(.establishingSecureChannel(checkCodeString: "01"))
        try await deferred.fulfill()
        
        var deferredAction = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
            guard case .requestOIDCAuthorisation = action else { return false }
            return true
        }
        testSetup.linkDesktopProgressSubject.send(.waitingForAuthorisation(verificationURL: .homeDirectory))
        try await deferredAction.fulfill()
        
        let currentState = testSetup.context.viewState.state
        let deferredFailure = deferFailure(testSetup.context.$viewState, timeout: 1) { $0.state != currentState }
        testSetup.linkDesktopProgressSubject.send(.syncingSecrets)
        try await deferredFailure.fulfill()
        
        deferredAction = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
            guard case .linkedDevice = action else { return false }
            return true
        }
        testSetup.linkDesktopProgressSubject.send(.done)
        try await deferredAction.fulfill()
    }
    
    @Test
    func linkMobileDevice() async throws {
        var testSetup = TestSetup(mode: .linkMobile)
        #expect(testSetup.context.viewState.state.isDisplayQR)
        
        let checkCodeSender = CheckCodeSenderSDKMock()
        let checkCodeSenderProxy = CheckCodeSenderProxy(underlyingSender: checkCodeSender)
        var deferredState = deferFulfillment(testSetup.context.$viewState) { $0.state == .confirmCode(.inputCode(checkCodeSenderProxy)) }
        testSetup.linkMobileProgressSubject.send(.qrScanned(checkCodeSenderProxy))
        try await deferredState.fulfill()
        
        deferredState = deferFulfillment(testSetup.context.$viewState) { $0.state == .confirmCode(.sendingCode) }
        testSetup.context.checkCodeInput = "01"
        testSetup.context.send(viewAction: .sendCheckCode)
        try await deferredState.fulfill()
        
        var deferredAction = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
            guard case .requestOIDCAuthorisation = action else { return false }
            return true
        }
        testSetup.linkMobileProgressSubject.send(.waitingForAuthorisation(verificationURL: .homeDirectory))
        try await deferredAction.fulfill()
        
        // Note: The SDK rarely sends the done action, so this test has been updated for the workaround of finishing early.
        deferredAction = deferFulfillment(testSetup.viewModel.actionsPublisher) { action in
            guard case .linkedDevice = action else { return false }
            return true
        }
        testSetup.linkMobileProgressSubject.send(.syncingSecrets)
        try await deferredAction.fulfill()
        
        let currentState = testSetup.context.viewState.state
        let deferredFailure = deferFailure(testSetup.context.$viewState, timeout: 1) { $0.state != currentState }
        testSetup.linkMobileProgressSubject.send(.done)
        try await deferredFailure.fulfill()
    }
}
