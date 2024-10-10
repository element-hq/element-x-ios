//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

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
                              requestDelay: Duration = .seconds(1)) -> SessionVerificationControllerProxyMock {
        let mock = SessionVerificationControllerProxyMock()
        mock.underlyingActions = actions

        mock.requestVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.acceptedVerificationRequest)
            }

            return .success(())
        }

        mock.startSasVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.startedSasVerification)

                Task.detached {
                    try await Task.sleep(for: requestDelay)
                    mock.actions.send(.receivedVerificationData(emojis))
                }
            }

            return .success(())
        }

        mock.approveVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.finished)
            }

            return .success(())
        }

        mock.declineVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.cancelled)
            }

            return .success(())
        }

        mock.cancelVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.actions.send(.cancelled)
            }

            return .success(())
        }
        
        return mock
    }
}
