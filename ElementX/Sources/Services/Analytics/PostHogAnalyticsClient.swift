//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents
import PostHog

/// An analytics client that reports events to a PostHog server.
class PostHogAnalyticsClient: AnalyticsClientProtocol {
    private var posthogFactory: PostHogFactory = DefaultPostHogFactory()
    
    init(posthogFactory: PostHogFactory? = nil) {
        if let factory = posthogFactory {
            self.posthogFactory = factory
        }
    }
    
    /// The PHGPostHog object used to report events.
    private var postHog: PHGPostHogProtocol?
    
    /// Any user properties to be included with the next captured event.
    private(set) var pendingUserProperties: AnalyticsEvent.UserProperties?
    
    /// Super Properties are properties associated with events that are set once and then sent with every capture call, be it a $screen, an autocaptured button click, or anything else.
    /// It is different from user properties that will be attached to the user and not events.
    /// Not persisted for now, should be set on start.
    private var superProperties: AnalyticsEvent.SuperProperties?
    
    var isRunning: Bool { postHog != nil }
    
    func start(analyticsConfiguration: AnalyticsConfiguration) {
        // Only start if analytics have been configured in BuildSettings
        guard let configuration = PostHogConfig.standard(analyticsConfiguration: analyticsConfiguration) else { return }
        
        if postHog != nil {
            // start has been called twice in a row without calling stop()?
            // Anyhow it's no-op if it's the case, but log for sanity
            MXLog.failure("Posthog should always be nil when it's being started")
        }
        postHog = posthogFactory.createPostHog(config: configuration)
        
        // Add super property cryptoSDK to the captured events, to allow easy
        // filtering of events across different client by using same filter.
        superProperties = AnalyticsEvent.SuperProperties(appPlatform: .EXI, cryptoSDK: .Rust, cryptoSDKVersion: nil)
        postHog?.optIn()
    }
    
    func reset() {
        postHog?.reset()
        pendingUserProperties = nil
    }
    
    func stop() {
        postHog?.optOut()
        postHog = nil
    }
    
    func capture(_ event: AnalyticsEventProtocol) {
        guard isRunning else { return }
        postHog?.capture(event.eventName, properties: attachSuperProperties(to: event.properties), userProperties: pendingUserProperties?.properties.compactMapValues { $0 })
        pendingUserProperties = nil
    }
    
    func screen(_ event: AnalyticsScreenProtocol) {
        guard isRunning else { return }
        postHog?.screen(event.screenName.rawValue, properties: attachSuperProperties(to: event.properties))
    }
    
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        guard let pendingUserProperties else {
            pendingUserProperties = userProperties
            return
        }
        
        // Merge the updated user properties with the existing ones
        self.pendingUserProperties = AnalyticsEvent.UserProperties(allChatsActiveFilter: userProperties.allChatsActiveFilter ?? pendingUserProperties.allChatsActiveFilter,
                                                                   ftueUseCaseSelection: userProperties.ftueUseCaseSelection ?? pendingUserProperties.ftueUseCaseSelection,
                                                                   numFavouriteRooms: userProperties.numFavouriteRooms ?? pendingUserProperties.numFavouriteRooms,
                                                                   numSpaces: userProperties.numSpaces ?? pendingUserProperties.numSpaces,
                                                                   recoveryState: userProperties.recoveryState ?? pendingUserProperties.recoveryState,
                                                                   verificationState: userProperties.verificationState ?? pendingUserProperties.verificationState)
    }
    
    func updateSuperProperties(_ updatedProperties: AnalyticsEvent.SuperProperties) {
        guard let currentProperties = superProperties else {
            superProperties = updatedProperties
            return
        }
        
        superProperties = AnalyticsEvent.SuperProperties(appPlatform: updatedProperties.appPlatform ??
            currentProperties.appPlatform,
            cryptoSDK: updatedProperties.cryptoSDK ??
                currentProperties.cryptoSDK,
            cryptoSDKVersion: updatedProperties.cryptoSDKVersion ??
                currentProperties.cryptoSDKVersion)
    }
    
    // MARK: - Private
    
    /// Attach super properties to events.
    /// If the property is already set on the event, the already set value will be kept.
    private func attachSuperProperties(to properties: [String: Any]) -> [String: Any] {
        guard isRunning, let superProperties else { return properties }
        
        var properties = properties
        
        superProperties.properties.forEach { (key: String, value: Any) in
            if properties[key] == nil {
                properties[key] = value
            }
        }
        return properties
    }
}
