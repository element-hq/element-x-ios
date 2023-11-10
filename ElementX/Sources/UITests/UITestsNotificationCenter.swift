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
import SwiftUI

@MainActor
/// A notification center that can be injected in the app to post notifications
/// that are sent from the UI tests runner. Usage:
/// - Create an instance of the center in the screen you want to test and call `startListening`.
/// - Create a `UITestSignalling.Client` in the `.tests` mode in your tests.
/// - Start the app from the tests and call `client.waitForApp()` to establish communication.
/// - Send the notification from the tests you would like posted in the app.
class UITestsNotificationCenter: NotificationCenter {
    private var client: UITestsSignalling.Client?
    private var signalCancellable: AnyCancellable?
    
    /// Starts listening for signals to post notifications.
    func startListening() throws {
        let client = try UITestsSignalling.Client(mode: .app)
        
        signalCancellable = client.signals.sink { [weak self] signal in
            Task {
                do {
                    try await self?.handleSignal(signal)
                } catch {
                    MXLog.error(error.localizedDescription)
                }
            }
        }
        
        self.client = client
    }
    
    /// Handles any notification signals, and drops anything else received.
    private func handleSignal(_ signal: UITestsSignal) async throws {
        switch signal {
        case .notification(let name):
            post(name: name, object: nil)
        default:
            break
        }
    }
}
