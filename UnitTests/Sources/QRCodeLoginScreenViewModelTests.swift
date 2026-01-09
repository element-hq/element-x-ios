//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX
import MatrixRustSDKMocks

@MainActor
final class QRCodeLoginScreenViewModelTests: XCTestCase {
    private var qrLoginProgressSubject: CurrentValueSubject<QRLoginProgress, AuthenticationServiceError>!
    private var qrCodeLoginService: QRCodeLoginServiceMock!
    
    private var linkMobileProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>!
    private var linkDesktopProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkDesktopProgress, QRCodeLoginError>!
    private var linkNewDeviceService: LinkNewDeviceServiceMock!
    
    private var appMediator: AppMediatorMock!
    
    private var viewModel: QRCodeLoginScreenViewModelProtocol!
    private var context: QRCodeLoginScreenViewModelType.Context { viewModel.context }
    
    func testLoginInitialState() {
        setupViewModel(mode: .login)
        
        XCTAssertEqual(context.viewState.state, .loginInstructions)
        XCTAssertNil(context.qrResult)
        XCTAssertFalse(qrCodeLoginService.loginWithQRCodeDataCalled)
        XCTAssertFalse(appMediator.requestAuthorizationIfNeededCalled)
        XCTAssertFalse(appMediator.openAppSettingsCalled)
        
        XCTAssertFalse(linkNewDeviceService.linkMobileDeviceCalled)
        XCTAssertFalse(linkNewDeviceService.linkDesktopDeviceWithCalled)
    }
    
    func testLinkDesktopInitialState() {
        setupViewModel(mode: .linkDesktop)
        
        XCTAssertEqual(context.viewState.state, .linkDesktopInstructions)
        XCTAssertNil(context.qrResult)
        XCTAssertFalse(linkNewDeviceService.linkDesktopDeviceWithCalled)
        XCTAssertFalse(appMediator.requestAuthorizationIfNeededCalled)
        XCTAssertFalse(appMediator.openAppSettingsCalled)
        
        XCTAssertFalse(linkNewDeviceService.linkMobileDeviceCalled)
        XCTAssertFalse(qrCodeLoginService.loginWithQRCodeDataCalled)
    }
    
    func testLinkMobileInitialState() {
        setupViewModel(mode: .linkMobile)
        
        XCTAssertTrue(context.viewState.state.isDisplayQR)
        XCTAssertTrue(linkNewDeviceService.linkMobileDeviceCalled)
        
        XCTAssertFalse(linkNewDeviceService.linkDesktopDeviceWithCalled)
        XCTAssertFalse(qrCodeLoginService.loginWithQRCodeDataCalled)
        XCTAssertNil(context.qrResult)
    }
    
    func testRequestCameraPermission() async throws {
        setupViewModel(mode: .login)
        appMediator.requestAuthorizationIfNeededReturnValue = false
        XCTAssert(context.viewState.state == .loginInstructions)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.state == .error(.noCameraPermission)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(appMediator.requestAuthorizationIfNeededCalled)
        
        context.send(viewAction: .errorAction(.openSettings))
        await Task.yield()
        XCTAssertTrue(appMediator.openAppSettingsCalled)
        XCTAssertNil(context.qrResult)
    }
    
    func testLogin() async throws {
        setupViewModel(mode: .login)
        XCTAssert(context.viewState.state == .loginInstructions)
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.state == .scan(.scanning)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(appMediator.requestAuthorizationIfNeededCalled)
        
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
    
    func testLinkDesktopComputer() async throws {
        setupViewModel(mode: .linkDesktop)
        XCTAssert(context.viewState.state == .linkDesktopInstructions)
        
        var deferred = deferFulfillment(context.$viewState) { $0.state == .scan(.scanning) }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(appMediator.requestAuthorizationIfNeededCalled)
        
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
        let deferredFailure = deferFailure(context.$viewState, timeout: 1) { $0.state != currentState }
        linkDesktopProgressSubject.send(.syncingSecrets)
        try await deferredFailure.fulfill()
        
        deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            guard case .linkedDevice = action else { return false }
            return true
        }
        linkDesktopProgressSubject.send(.done)
        try await deferredAction.fulfill()
    }
    
    func testLinkMobileDevice() async throws {
        setupViewModel(mode: .linkMobile)
        XCTAssert(context.viewState.state.isDisplayQR)
        
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
        let deferredFailure = deferFailure(context.$viewState, timeout: 1) { $0.state != currentState }
        linkMobileProgressSubject.send(.done)
        try await deferredFailure.fulfill()
    }
    
    // MARK: - Helpers
    
    enum Mode { case login, linkDesktop, linkMobile }
    
    private func setupViewModel(mode: Mode) {
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
