//
// Copyright 2021 New Vector Ltd
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

import AnalyticsEvents
import PostHog

/// A class responsible for managing a variety of analytics clients
/// and sending events through these clients.
///
/// Events may include user activity, or app health data such as crashes,
/// non-fatal issues and performance. `Analytics` class serves as a façade
/// to all these use cases.
///
/// ## Creating Analytics Events
///
/// Events are managed in a shared repo for all Element clients https://github.com/matrix-org/matrix-analytics-events
/// To add a new event create a PR to that repo with the new/updated schema. Once merged
/// into `main`, update the AnalyticsEvents Swift package in `project.yml`.
///
class Analytics {
    // MARK: - Properties
    
    /// The singleton instance to be used within the Riot target.
    static let shared = Analytics()
    
    /// The analytics client to send events with.
    private var client: AnalyticsClientProtocol = PostHogAnalyticsClient()
    
    /// The monitoring client to track crashes, issues and performance
//    private var monitoringClient = SentryMonitoringClient()
    
    /// The service used to interact with account data settings.
    private var service: AnalyticsService?
    
    /// Whether or not the object is enabled and sending events to the server.
    var isRunning: Bool { client.isRunning }
    
    /// Whether to show the user the analytics opt in prompt.
    var shouldShowAnalyticsPrompt: Bool {
        // Only show the prompt once, and when analytics are enabled in BuildSettings.
        !ElementSettings.shared.hasSeenAnalyticsPrompt && BuildSettings.analyticsConfiguration.isEnabled
    }
    
    // MARK: - Public
    
    /// Opts in to analytics tracking with the supplied user session.
    /// - Parameter userSession: The user session to use to when reading/generating the analytics ID.
    ///  The session will be ignored if not running.
    func optIn(with userSession: UserSessionProtocol) {
        ElementSettings.shared.enableAnalytics = true
        startIfEnabled()
        
        Task { await useAnalyticsSettings(from: userSession) }
    }
    
    /// Stops analytics tracking and calls `reset` to clear any IDs and event queues.
    func optOut() {
        ElementSettings.shared.enableAnalytics = false
        
        // The order is important here. PostHog ignores the reset if stopped.
        reset()
        client.stop()
//        monitoringClient.stop()
        
        MXLog.debug("Stopped.")
    }
    
    /// Starts the analytics client if the user has opted in, otherwise does nothing.
    func startIfEnabled() {
        guard ElementSettings.shared.enableAnalytics, !isRunning else { return }
        
        client.start()
//        monitoringClient.start()
        
        // Sanity check in case something went wrong.
        guard client.isRunning else { return }
        
        MXLog.debug("Started.")
        
        // Catch and log crashes
//        MXLogger.logCrashes(true)
//        MXLogger.setBuildVersion(Bundle.bundleShortVersionString)
    }
    
    /// Use the analytics settings from the supplied user session to configure analytics.
    /// For now this is only used for (pseudonymous) identification.
    /// - Parameter userSession: The user session to read analytics settings from.
    func useAnalyticsSettings(from userSession: UserSessionProtocol) async {
        guard
            ElementSettings.shared.enableAnalytics,
            !ElementSettings.shared.isIdentifiedForAnalytics
        else { return }
        
        let service = AnalyticsService(userSession: userSession)
        self.service = service
        
        switch await service.settings() {
        case .success(let settings):
            identify(with: settings)
            self.service = nil
        case .failure:
            MXLog.error("Failed to use analytics settings. Will continue to run without analytics ID.")
            self.service = nil
        }
    }
    
    /// Resets the any IDs and event queues in the analytics client. This method should
    /// be called on sign-out to maintain opt-in status, whilst ensuring the next
    /// account used isn't associated with the previous one.
    /// Note: **MUST** be called before stopping PostHog or the reset is ignored.
    func reset() {
        client.reset()
//        monitoringClient.reset()
        
        MXLog.debug("Reset.")
        ElementSettings.shared.isIdentifiedForAnalytics = false
        
        // Stop collecting crash logs
//        MXLogger.logCrashes(false)
    }
    
    /// Flushes the event queue in the analytics client, uploading all pending events.
    /// Normally events are sent in batches. Call this method when you need an event
    /// to be sent immediately.
    func forceUpload() {
        client.flush()
    }
    
    // MARK: - Private
    
    /// Identify (pseudonymously) any future events with the ID from the analytics account data settings.
    /// - Parameter settings: The settings to use for identification. The ID must be set *before* calling this method.
    private func identify(with settings: AnalyticsSettings) {
        guard let id = settings.id else {
            MXLog.error("identify(with:) called before an ID has been generated.")
            return
        }
        
        client.identify(id: id)
        MXLog.debug("Identified.")
        ElementSettings.shared.isIdentifiedForAnalytics = true
    }
    
    /// Capture an event in the `client`.
    /// - Parameter event: The event to capture.
    private func capture(event: AnalyticsEventProtocol) {
        client.capture(event)
    }
}

// MARK: - Public tracking methods

// The following methods are exposed for compatibility with Objective-C as
// the `capture` method and the generated events cannot be bridged from Swift.
extension Analytics { }

// MARK: - MXAnalyticsDelegate

// extension Analytics: MXAnalyticsDelegate {
// }
