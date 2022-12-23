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
import Foundation

class SessionVerificationControllerProxyMock: SessionVerificationControllerProxyProtocol {
    var callbacks: PassthroughSubject<ElementX.SessionVerificationControllerProxyCallback, Never>
    
    var isVerified: Bool
    
    init(callbacks: PassthroughSubject<ElementX.SessionVerificationControllerProxyCallback, Never>, isVerified: Bool) {
        self.callbacks = callbacks
        self.isVerified = isVerified
    }
    
    func requestVerification() async -> Result<Void, ElementX.SessionVerificationControllerProxyError> {
        .failure(.failedApprovingVerification)
    }
    
    func approveVerification() async -> Result<Void, ElementX.SessionVerificationControllerProxyError> {
        .failure(.failedApprovingVerification)
    }
    
    func declineVerification() async -> Result<Void, ElementX.SessionVerificationControllerProxyError> {
        .failure(.failedApprovingVerification)
    }
    
    func cancelVerification() async -> Result<Void, ElementX.SessionVerificationControllerProxyError> {
        .failure(.failedApprovingVerification)
    }
}
