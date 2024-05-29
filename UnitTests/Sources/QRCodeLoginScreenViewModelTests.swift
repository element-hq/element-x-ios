//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        qrServiceMock = QRCodeLoginServiceMock(configuration: .init())
        qrServiceMock.underlyingQrLoginProgressPublisher = qrProgressSubject.eraseToAnyPublisher()
        appMediatorMock = AppMediatorMock.default
        viewModel = QRCodeLoginScreenViewModel(qrCodeLoginService: qrServiceMock,
                                               appMediator: appMediatorMock)
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.state, .initial)
        XCTAssertNil(context.qrResult)
        XCTAssertFalse(qrServiceMock.loginWithQRCodeDataCalled)
        XCTAssertFalse(qrServiceMock.requestAuthorizationIfNeededCalled)
        XCTAssertFalse(appMediatorMock.openAppSettingsCalled)
    }
    
    func testRequestCameraPermission() async throws {
        qrServiceMock.requestAuthorizationIfNeededReturnValue = false
        XCTAssert(context.viewState.state == .initial)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.state == .error(.noCameraPermission)
        }
        context.send(viewAction: .startScan)
        try await deferred.fulfill()
        XCTAssertTrue(qrServiceMock.requestAuthorizationIfNeededCalled)
        
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
        XCTAssertTrue(qrServiceMock.requestAuthorizationIfNeededCalled)
        
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
