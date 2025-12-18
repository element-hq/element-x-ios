//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

import MatrixRustSDK

@testable import ElementX

@MainActor
final class QRCodeLoginScreenViewModelTests: XCTestCase {
    private var qrProgressSubject: CurrentValueSubject<QRLoginProgress, AuthenticationServiceError>!
    private var qrServiceMock: QRCodeLoginServiceMock!
    private var appMediatorMock: AppMediatorMock!
    private var viewModel: QRCodeLoginScreenViewModelProtocol!

    private var context: QRCodeLoginScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        qrProgressSubject = .init(.starting)
        qrServiceMock = QRCodeLoginServiceMock()
        qrServiceMock.loginWithQRCodeDataReturnValue = qrProgressSubject.asCurrentValuePublisher()
        appMediatorMock = AppMediatorMock.default
        viewModel = QRCodeLoginScreenViewModel(mode: .login(qrServiceMock),
                                               canSignInManually: true,
                                               appMediator: appMediatorMock)
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.state, .loginInstructions)
        XCTAssertNil(context.qrResult)
        XCTAssertFalse(qrServiceMock.loginWithQRCodeDataCalled)
        XCTAssertFalse(appMediatorMock.requestAuthorizationIfNeededCalled)
        XCTAssertFalse(appMediatorMock.openAppSettingsCalled)
    }
    
    func testRequestCameraPermission() async throws {
        appMediatorMock.requestAuthorizationIfNeededReturnValue = false
        XCTAssert(context.viewState.state == .loginInstructions)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.state == .error(.noCameraPermission)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(appMediatorMock.requestAuthorizationIfNeededCalled)
        
        context.send(viewAction: .errorAction(.openSettings))
        await Task.yield()
        XCTAssertTrue(appMediatorMock.openAppSettingsCalled)
        XCTAssertNil(context.qrResult)
    }
    
    func testLogin() async throws {
        XCTAssert(context.viewState.state == .loginInstructions)
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.state == .scan(.scanning)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(appMediatorMock.requestAuthorizationIfNeededCalled)
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.state == .scan(.connecting)
        }
        context.qrResult = .init()
        try await deferred.fulfill()

        deferred = deferFulfillment(context.$viewState) { state in
            state.state == .displayCode(.deviceCode("01"))
        }
        qrProgressSubject.send(.establishingSecureChannel(checkCode: 1, checkCodeString: "01"))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.state == .displayCode(.verificationCode("ABCDEF"))
        }
        qrProgressSubject.send(.waitingForToken(userCode: "ABCDEF"))
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .signedIn: true
            default: false
            }
        }
        qrProgressSubject.send(.signedIn(UserSessionMock(.init(clientProxy: ClientProxyMock()))))
        try await deferredAction.fulfill()
    }
}
