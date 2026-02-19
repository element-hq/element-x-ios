//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents
@testable import ElementX
import PostHog
import Testing

@Suite
final class AnalyticsTests {
    private var appSettings: AppSettings
    private var analyticsClient: AnalyticsClientMock
    private var posthogMock: PHGPostHogMock
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        
        analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: appSettings))
        
        posthogMock = PHGPostHogMock()
        posthogMock.configureMockBehavior()
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func analyticsPromptNewUser() {
        // Given a fresh install of the app (without PostHog analytics having been set).
        // When the user is prompted for analytics.
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt
        
        // Then the prompt should be shown.
        #expect(showPrompt, "A prompt should be shown for a new user.")
    }
    
    @Test
    func analyticsPromptUserDeclinedPostHog() {
        // Given an existing install of the app where the user previously declined PostHog
        appSettings.analyticsConsentState = .optedOut
        
        // When the user is prompted for analytics
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt
        
        // Then no prompt should be shown.
        #expect(!showPrompt, "A prompt should not be shown any more.")
    }
    
    @Test
    func analyticsPromptUserAcceptedPostHog() {
        // Given an existing install of the app where the user previously accepted PostHog
        appSettings.analyticsConsentState = .optedIn
        
        // When the user is prompted for analytics
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt
        
        // Then no prompt should be shown.
        #expect(!showPrompt, "A prompt should not be shown any more.")
    }
    
    @Test
    func analyticsPromptNotDisplayed() {
        // Given a fresh install of the app Analytics should be disabled
        #expect(appSettings.analyticsConsentState == .unknown)
        #expect(!ServiceLocator.shared.analytics.isEnabled)
        #expect(!analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    @Test
    func analyticsOptOut() {
        // Given a fresh install of the app (without PostHog analytics having been set).
        // When analytics is opt-out
        ServiceLocator.shared.analytics.optOut()
        // Then analytics should be disabled
        #expect(appSettings.analyticsConsentState == .optedOut)
        #expect(!ServiceLocator.shared.analytics.isEnabled)
        #expect(!analyticsClient.isRunning)
        // Analytics client should have been stopped
        #expect(analyticsClient.stopCalled)
    }
    
    @Test
    func analyticsOptIn() {
        // Given a fresh install of the app (without PostHog analytics having been set).
        // When analytics is opt-in
        ServiceLocator.shared.analytics.optIn()
        // The analytics should be enabled
        #expect(appSettings.analyticsConsentState == .optedIn)
        #expect(ServiceLocator.shared.analytics.isEnabled)
        // Analytics client should have been started
        #expect(analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    @Test
    func analyticsStartIfNotEnabled() {
        // Given an existing install of the app where the user previously declined the tracking
        appSettings.analyticsConsentState = .optedOut
        // Analytics should not start
        #expect(!ServiceLocator.shared.analytics.isEnabled)
        ServiceLocator.shared.analytics.startIfEnabled()
        #expect(!analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    @Test
    func analyticsStartIfEnabled() {
        // Given an existing install of the app where the user previously accepted the tracking
        appSettings.analyticsConsentState = .optedIn
        // Analytics should start
        #expect(ServiceLocator.shared.analytics.isEnabled)
        ServiceLocator.shared.analytics.startIfEnabled()
        #expect(analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    @Test
    func addingUserProperties() {
        // Given a client with no user properties set
        let client = PostHogAnalyticsClient()
        #expect(client.pendingUserProperties == nil, "No user properties should have been set yet.")
        
        // When updating the user properties
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil,
                                                                  ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: 4,
                                                                  numSpaces: 5, recoveryState: .Disabled, verificationState: .Verified))
        
        // Then the properties should be cached
        #expect(client.pendingUserProperties != nil, "The user properties should be cached.")
        #expect(client.pendingUserProperties?.ftueUseCaseSelection == .PersonalMessaging, "The use case selection should match.")
        #expect(client.pendingUserProperties?.numFavouriteRooms == 4, "The number of favorite rooms should match.")
        #expect(client.pendingUserProperties?.numSpaces == 5, "The number of spaces should match.")
        #expect(client.pendingUserProperties?.verificationState == AnalyticsEvent.UserProperties.VerificationState.Verified, "The verification state should match.")
        #expect(client.pendingUserProperties?.recoveryState == AnalyticsEvent.UserProperties.RecoveryState.Disabled, "The recovery state should match.")
    }
    
    @Test
    func mergingUserProperties() {
        // Given a client with a cached use case user properties
        let client = PostHogAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: nil,
                                                                  numSpaces: nil, recoveryState: nil, verificationState: nil))
        
        #expect(client.pendingUserProperties != nil, "The user properties should be cached.")
        #expect(client.pendingUserProperties?.ftueUseCaseSelection == .PersonalMessaging, "The use case selection should match.")
        #expect(client.pendingUserProperties?.numFavouriteRooms == nil, "The number of favorite rooms should not be set.")
        #expect(client.pendingUserProperties?.numSpaces == nil, "The number of spaces should not be set.")
        
        // When updating the number of spaced
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: nil,
                                                                  numFavouriteRooms: 4,
                                                                  numSpaces: 5, recoveryState: nil, verificationState: nil))
        
        // Then the new properties should be updated and the existing properties should remain unchanged
        #expect(client.pendingUserProperties != nil, "The user properties should be cached.")
        #expect(client.pendingUserProperties?.ftueUseCaseSelection == .PersonalMessaging, "The use case selection shouldn't have changed.")
        #expect(client.pendingUserProperties?.numFavouriteRooms == 4, "The number of favorite rooms should have been updated.")
        #expect(client.pendingUserProperties?.numSpaces == 5, "The number of spaces should have been updated.")
    }
    
    @Test
    func sendingUserProperties() throws {
        // Given a client with user properties set
        
        let client = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        try client.start(analyticsConfiguration: #require(appSettings.analyticsConfiguration))
        
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: nil,
                                                                  numSpaces: nil, recoveryState: nil, verificationState: nil))
        
        #expect(client.pendingUserProperties != nil, "The user properties should be cached.")
        #expect(client.pendingUserProperties?.ftueUseCaseSelection == .PersonalMessaging, "The use case selection should match.")
        
        // When sending an event (tests run under Debug configuration so this is sent to the development instance)
        let someEvent = AnalyticsEvent.Error(context: nil,
                                             cryptoModule: .Rust,
                                             cryptoSDK: .Rust,
                                             domain: .E2EE,
                                             eventLocalAgeMillis: nil,
                                             isFederated: nil,
                                             isMatrixDotOrg: nil,
                                             name: .OlmKeysNotSentError,
                                             timeToDecryptMillis: nil,
                                             userTrustsOwnIdentity: nil,
                                             wasVisibleToUser: nil)
        client.capture(someEvent)
        
        let capturedEvent = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        // The user properties should have been added
        #expect(capturedEvent?.userProperties?["ftueUseCaseSelection"] as? String == AnalyticsEvent.UserProperties.FtueUseCaseSelection.PersonalMessaging.rawValue)
        
        // Then the properties should be cleared
        #expect(client.pendingUserProperties == nil, "The user properties should be cleared.")
    }
    
    @Test
    func resetConsentState() {
        // Given an existing install of the app where the user previously accpeted the tracking
        appSettings.analyticsConsentState = .optedIn
        #expect(!ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt)
        
        // When forgetting analytics consents
        ServiceLocator.shared.analytics.resetConsentState()
        
        // Then the analytics prompt should be presented again
        #expect(appSettings.analyticsConsentState == .unknown)
        #expect(ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt)
    }
    
    @Test
    func sendingAndUpdatingSuperProperties() throws {
        // Given a client with user properties set
        let client = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        try client.start(analyticsConfiguration: #require(appSettings.analyticsConfiguration))
        
        client.updateSuperProperties(AnalyticsEvent.SuperProperties(appPlatform: .EXI,
                                                                    cryptoSDK: .Rust,
                                                                    cryptoSDKVersion: "000"))
        
        // When sending an event (tests run under Debug configuration so this is sent to the development instance)
        client.screen(AnalyticsEvent.MobileScreen(durationMs: nil, screenName: .Home))
        
        let screenEvent = posthogMock.screenPropertiesReceivedArguments
        
        #expect(screenEvent?.screenTitle == AnalyticsEvent.MobileScreen.ScreenName.Home.rawValue)
        
        // All the super properties should have been added
        #expect(screenEvent?.properties?["cryptoSDK"] as? String == AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        #expect(screenEvent?.properties?["appPlatform"] as? String == "EXI")
        #expect(screenEvent?.properties?["cryptoSDKVersion"] as? String == "000")
        
        // It should be the same for any event
        let someEvent = AnalyticsEvent.Error(context: nil,
                                             cryptoModule: .Rust,
                                             cryptoSDK: .Rust,
                                             domain: .E2EE,
                                             eventLocalAgeMillis: nil,
                                             isFederated: nil,
                                             isMatrixDotOrg: nil,
                                             name: .OlmKeysNotSentError,
                                             timeToDecryptMillis: nil,
                                             userTrustsOwnIdentity: nil,
                                             wasVisibleToUser: nil)
        client.capture(someEvent)
        
        let capturedEvent = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        // All the super properties should have been added
        #expect(capturedEvent?.properties?["cryptoSDK"] as? String == AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        #expect(capturedEvent?.properties?["appPlatform"] as? String == "EXI")
        #expect(capturedEvent?.properties?["cryptoSDKVersion"] as? String == "000")
        
        // Updating should keep the previously set properties
        client.updateSuperProperties(AnalyticsEvent.SuperProperties(appPlatform: .EXI,
                                                                    cryptoSDK: .Rust,
                                                                    cryptoSDKVersion: "001"))
        
        client.capture(someEvent)
        let capturedEvent2 = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        // All the super properties should have been added, with the one udpated
        #expect(capturedEvent2?.properties?["cryptoSDK"] as? String == AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        #expect(capturedEvent2?.properties?["appPlatform"] as? String == "EXI")
        #expect(capturedEvent2?.properties?["cryptoSDKVersion"] as? String == "001")
    }
    
    @Test
    func shouldNotReportIfNotStarted() throws {
        // Given a client with user properties set
        let client = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        
        // No call to start
        
        client.screen(AnalyticsEvent.MobileScreen(durationMs: nil, screenName: .Home))
        
        #expect(posthogMock.screenPropertiesCalled == false)
        
        // It should be the same for any event
        let someEvent = AnalyticsEvent.Error(context: nil,
                                             cryptoModule: .Rust,
                                             cryptoSDK: .Rust,
                                             domain: .E2EE,
                                             eventLocalAgeMillis: nil,
                                             isFederated: nil,
                                             isMatrixDotOrg: nil,
                                             name: .OlmKeysNotSentError,
                                             timeToDecryptMillis: nil,
                                             userTrustsOwnIdentity: nil,
                                             wasVisibleToUser: nil)
        client.capture(someEvent)
        
        #expect(posthogMock.capturePropertiesUserPropertiesCalled == false)
        
        // start now
        try client.start(analyticsConfiguration: #require(appSettings.analyticsConfiguration))
        #expect(posthogMock.optInCalled == true)
        
        client.capture(someEvent)
        #expect(posthogMock.capturePropertiesUserPropertiesCalled == true)
    }
}
