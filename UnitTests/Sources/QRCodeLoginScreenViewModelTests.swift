//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

import MatrixRustSDK

@testable import ElementX

@MainActor
final class QRCodeLoginScreenViewModelTests: XCTestCase {
    private var qrProgressSubject: PassthroughSubject<QrLoginProgress, Never>!
    private var qrServiceMock: QRCodeLoginServiceMock!
    private var appMediatorMock: AppMediatorMock!
    private var viewModel: QRCodeLoginScreenViewModelProtocol!

    private var context: QRCodeLoginScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        qrProgressSubject = PassthroughSubject<QrLoginProgress, Never>()
        qrServiceMock = QRCodeLoginServiceMock()
        qrServiceMock.underlyingQrLoginProgressPublisher = qrProgressSubject.eraseToAnyPublisher()
        appMediatorMock = AppMediatorMock.default
        viewModel = QRCodeLoginScreenViewModel(qrCodeLoginService: qrServiceMock,
                                               appMediator: appMediatorMock)
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.state, .initial)
        XCTAssertNil(context.qrResult)
        XCTAssertFalse(qrServiceMock.loginWithQRCodeDataCalled)
        XCTAssertFalse(appMediatorMock.requestAuthorizationIfNeededCalled)
        XCTAssertFalse(appMediatorMock.openAppSettingsCalled)
    }
    
    func testRequestCameraPermission() async throws {
        appMediatorMock.requestAuthorizationIfNeededReturnValue = false
        XCTAssert(context.viewState.state == .initial)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.state == .error(.noCameraPermission)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(appMediatorMock.requestAuthorizationIfNeededCalled)
        
        context.send(viewAction: .openSettings)
        await Task.yield()
        XCTAssertTrue(appMediatorMock.openAppSettingsCalled)
        XCTAssertNil(context.qrResult)
    }
    
    func testLogin() async throws {
        var isCompleted = false
        qrServiceMock.loginWithQRCodeDataClosure = { _ in
            while !isCompleted {
                await Task.yield()
            }
            return .success(UserSessionMock(.init(clientProxy: ClientProxyMock())))
        }
        
        XCTAssert(context.viewState.state == .initial)
        
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
            case .done:
                return true
            default:
                return false
            }
        }
        qrProgressSubject.send(.done)
        isCompleted = true
        try await deferredAction.fulfill()
    }
}
