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
@testable import ElementX
import XCTest

final class UserSessionTests: XCTestCase {
    var userSession: UserSession!
    let clientProxy = MockClientProxy(userIdentifier: "@test:user.net")
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func setUpWithError() throws {
        cancellables = []
        userSession = UserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
    }

    func test_whenUserSessionReceivesSyncUpdateAndSessionControllerRetrievedAndSessionNotVerified_sessionVerificationNeededEventReceived() throws {
        let expectation = expectation(description: "SessionVerificationNeeded expectation")
        userSession.callbacks.sink { callback in
            switch callback {
            case .sessionVerificationNeeded:
                expectation.fulfill()
            default:
                break
            }
        }
        .store(in: &cancellables)
        
        let controller = MockSessionVerificationControllerProxy(callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never>(),
                                                                isVerified: false,
                                                                requestDelay: .zero)
        clientProxy.sessionVerificationControllerProxyResult = .success(controller)
        clientProxy.callbacks.send(.receivedSyncUpdate)
        waitForExpectations(timeout: 1.0)
    }
    
    func test_whenUserSessionReceivesSyncUpdateAndSessionIsVerified_didVerifySessionEventReceived() throws {
        let expectation = expectation(description: "DidVerifySessionEvent expectation")
        let controller = MockSessionVerificationControllerProxy(callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never>(),
                                                                isVerified: false,
                                                                requestDelay: .zero)
        clientProxy.sessionVerificationControllerProxyResult = .success(controller)
        
        controller.callbacks.sink { value in
            switch value {
            case .finished:
                expectation.fulfill()
            default:
                break
            }
        }
        .store(in: &cancellables)
        
        clientProxy.callbacks.send(.receivedSyncUpdate)
        controller.callbacks.send(.finished)
        waitForExpectations(timeout: 1.0)
    }
    
    func test_whenUserSessionReceivesUpdatedRestoreToken_updateRestoreTokenNeededEventReceived() throws {
        let expectation = expectation(description: "UpdatedRestoreToken expectation")
        userSession.callbacks.sink { callback in
            switch callback {
            case .updateRestoreTokenNeeded:
                expectation.fulfill()
            default:
                break
            }
        }
        .store(in: &cancellables)
        
        clientProxy.callbacks.send(.updatedRestoreToken)
        waitForExpectations(timeout: 1.0)
    }
}
