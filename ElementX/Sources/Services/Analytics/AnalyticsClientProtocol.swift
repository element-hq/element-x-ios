//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents

/// A protocol representing an analytics client.
protocol AnalyticsClientProtocol {
    /// Whether the analytics client is currently reporting data or ignoring it.
    var isRunning: Bool { get }
    
    /// Starts the analytics client reporting data.
    func start(analyticsConfiguration: AnalyticsConfiguration)
       
    /// Reset all stored properties and any event queues on the client. Note that
    /// the client will remain active, but in a fresh unidentified state.
    func reset()
    
    /// Stop the analytics client reporting data.
    func stop()
    
    /// Capture the supplied analytics event.
    /// - Parameter event: The event to capture.
    func capture(_ event: AnalyticsEventProtocol)
    
    /// Capture the supplied analytics screen event.
    /// - Parameter event: The screen event to capture.
    func screen(_ event: AnalyticsScreenProtocol)
    
    /// Updates the user properties
    /// - Parameter userProperties: The properties event to capture.
    func updateUserProperties(_ event: AnalyticsEvent.UserProperties)
}

// sourcery: AutoMockable
extension AnalyticsClientProtocol { }
