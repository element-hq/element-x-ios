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

@MainActor
final class QRCodeLoginScreenViewModelTests: XCTestCase {
    private var qrLoginProgressSubject: CurrentValueSubject<QRLoginProgress, AuthenticationServiceError>!
    private var qrCodeLoginService: QRCodeLoginServiceMock!
    
    private var linkMobileProgressSubject: CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>!
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
        
        let isDisplayingQRCode = switch context.viewState.state {
        case .displayQR: true
        default: false
        }
        
        XCTAssertTrue(isDisplayingQRCode)
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
    
    #warning("Add tests for linking.")
    
    // MARK: - Helpers
    
    enum Mode { case login, linkDesktop, linkMobile }
    
    private func setupViewModel(mode: Mode) {
        qrLoginProgressSubject = .init(.starting)
        qrCodeLoginService = QRCodeLoginServiceMock()
        qrCodeLoginService.loginWithQRCodeDataReturnValue = qrLoginProgressSubject.asCurrentValuePublisher()
        
        linkMobileProgressSubject = .init(.qrReady(LinkNewDeviceServiceMock.mockQRCodeImage))
        linkNewDeviceService = LinkNewDeviceServiceMock(.init(linkMobileProgressPublisher: linkMobileProgressSubject.asCurrentValuePublisher()))
        
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
