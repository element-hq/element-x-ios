//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    // periphery:ignore - retaining purpose
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
