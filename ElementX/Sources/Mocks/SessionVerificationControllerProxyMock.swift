//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import Combine

extension SessionVerificationControllerProxyMock {
    static let emojis = [SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
                         SessionVerificationEmoji(symbol: "🐘", description: "Elephant"),
                         SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
                         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
                         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
                         SessionVerificationEmoji(symbol: "🏁", description: "Flag"),
                         SessionVerificationEmoji(symbol: "🌏", description: "Globe")]
    
    static func configureMock(actions: PassthroughSubject<SessionVerificationControllerProxyAction, Never> = .init(),
                              isVerified: Bool = false,
                              otherDeviceStartsSasVerification: Bool = false,
                              requestDelay: Duration = .seconds(1)) -> SessionVerificationControllerProxyMock {
        let mock = SessionVerificationControllerProxyMock()
        mock.actions = actions
        
        mock.acknowledgeVerificationRequestDetailsReturnValue = .success(())
        
        mock.requestDeviceVerificationClosure = { [weak mock] in
            Task {
                guard let mock else { return }
                
                try await Task.sleep(for: requestDelay)
                
                mock.actions.send(.acceptedVerificationRequest)
                
                if otherDeviceStartsSasVerification {
                    try await Task.sleep(for: requestDelay)
                    mock.actions.send(.startedSasVerification)
                    try await Task.sleep(for: requestDelay)
                    mock.actions.send(.receivedVerificationData(emojis))
                }
            }
            
            return .success(())
        }
        
        mock.startSasVerificationClosure = { [weak mock] in
            Task {
                guard let mock else { return }
                
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.startedSasVerification)
                
                Task {
                    try await Task.sleep(for: requestDelay)
                    mock.actions.send(.receivedVerificationData(emojis))
                }
            }
            
            return .success(())
        }
        
        mock.approveVerificationClosure = { [weak mock] in
            Task {
                guard let mock else { return }
                
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.finished)
            }
            
            return .success(())
        }
        
        mock.declineVerificationClosure = { [weak mock] in
            Task {
                guard let mock else { return }
                
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.cancelled)
            }
            
            return .success(())
        }
        
        mock.cancelVerificationClosure = { [weak mock] in
            Task {
                guard let mock else { return }
                
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.cancelled)
            }
            
            return .success(())
        }
        
        return mock
    }
}
