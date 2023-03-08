//
// Copyright 2023 New Vector Ltd
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

extension SessionVerificationControllerProxyMock {
    static let emojis = [SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
                         SessionVerificationEmoji(symbol: "🐘", description: "Elephant"),
                         SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
                         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
                         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
                         SessionVerificationEmoji(symbol: "🏁", description: "Flag"),
                         SessionVerificationEmoji(symbol: "🌏", description: "Globe")]

    static func configureMock(callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never> = .init(),
                              isVerified: Bool = false,
                              requestDelay: Duration = .seconds(1)) -> SessionVerificationControllerProxyMock {
        let mock = SessionVerificationControllerProxyMock()
        mock.underlyingCallbacks = callbacks
        mock.underlyingIsVerified = isVerified

        mock.requestVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.callbacks.send(.acceptedVerificationRequest)
            }

            return .success(())
        }

        mock.startSasVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.callbacks.send(.startedSasVerification)

                Task.detached {
                    try await Task.sleep(for: requestDelay)
                    mock.callbacks.send(.receivedVerificationData(Self.emojis))
                }
            }

            return .success(())
        }

        mock.approveVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.callbacks.send(.finished)
            }

            return .success(())
        }

        mock.declineVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.callbacks.send(.cancelled)
            }

            return .success(())
        }

        mock.cancelVerificationClosure = { [unowned mock] in
            Task.detached {
                try await Task.sleep(for: requestDelay)
                mock.callbacks.send(.cancelled)
            }

            return .success(())
        }
        
        return mock
    }
}
