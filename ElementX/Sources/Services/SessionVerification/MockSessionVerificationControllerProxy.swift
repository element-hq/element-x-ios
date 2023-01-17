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
import Foundation
import MatrixRustSDK

struct MockSessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol {
    var callbacks = PassthroughSubject<SessionVerificationControllerProxyCallback, Never>()
    
    var isVerified = false
    var requestDelay: Duration = .seconds(1)
    
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        Task.detached {
            try await Task.sleep(for: requestDelay)
            callbacks.send(.acceptedVerificationRequest)
        }
        
        return .success(())
    }
    
    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        Task.detached {
            try await Task.sleep(for: requestDelay)
            callbacks.send(.startedSasVerification)
            
            Task.detached {
                try await Task.sleep(for: requestDelay)
                callbacks.send(.receivedVerificationData(Self.emojis))
            }
        }
        
        return .success(())
    }
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        Task.detached {
            try await Task.sleep(for: requestDelay)
            callbacks.send(.finished)
        }
        
        return .success(())
    }
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        Task.detached {
            try await Task.sleep(for: requestDelay)
            callbacks.send(.cancelled)
        }
        
        return .success(())
    }
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        Task.detached {
            try await Task.sleep(for: requestDelay)
            callbacks.send(.cancelled)
        }
        
        return .success(())
    }
    
    // MARK: - Private
    
    static var emojis: [SessionVerificationEmoji] {
        [
            SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
            SessionVerificationEmoji(symbol: "🐘", description: "Elephant"),
            SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
            SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
            SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
            SessionVerificationEmoji(symbol: "🏁", description: "Flag"),
            SessionVerificationEmoji(symbol: "🌏", description: "Globe")
        ]
    }
}
