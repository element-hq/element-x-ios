//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents
@testable import ElementX
import PostHog
import XCTest

class AnalyticsTests: XCTestCase {
    private var appSettings: AppSettings!
    private var analyticsClient: AnalyticsClientMock!
    private var posthogMock: PHGPostHogMock!
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        
        analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: appSettings))
        
        posthogMock = PHGPostHogMock()
        posthogMock.configureMockBehavior()
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testAnalyticsPromptNewUser() {
        // Given a fresh install of the app (without PostHog analytics having been set).
        // When the user is prompted for analytics.
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt
        
        // Then the prompt should be shown.
        XCTAssertTrue(showPrompt, "A prompt should be shown for a new user.")
    }
    
    func testAnalyticsPromptUserDeclinedPostHog() {
        // Given an existing install of the app where the user previously declined PostHog
        appSettings.analyticsConsentState = .optedOut
        
        // When the user is prompted for analytics
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt
        
        // Then no prompt should be shown.
        XCTAssertFalse(showPrompt, "A prompt should not be shown any more.")
    }
    
    func testAnalyticsPromptUserAcceptedPostHog() {
        // Given an existing install of the app where the user previously accepted PostHog
        appSettings.analyticsConsentState = .optedIn
        
        // When the user is prompted for analytics
        let showPrompt = ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt
        
        // Then no prompt should be shown.
        XCTAssertFalse(showPrompt, "A prompt should not be shown any more.")
    }
    
    func testAnalyticsPromptNotDisplayed() {
        // Given a fresh install of the app Analytics should be disabled
        XCTAssertEqual(appSettings.analyticsConsentState, .unknown)
        XCTAssertFalse(ServiceLocator.shared.analytics.isEnabled)
        XCTAssertFalse(analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    func testAnalyticsOptOut() {
        // Given a fresh install of the app (without PostHog analytics having been set).
        // When analytics is opt-out
        ServiceLocator.shared.analytics.optOut()
        // Then analytics should be disabled
        XCTAssertEqual(appSettings.analyticsConsentState, .optedOut)
        XCTAssertFalse(ServiceLocator.shared.analytics.isEnabled)
        XCTAssertFalse(analyticsClient.isRunning)
        // Analytics client should have been stopped
        XCTAssertTrue(analyticsClient.stopCalled)
    }
    
    func testAnalyticsOptIn() {
        // Given a fresh install of the app (without PostHog analytics having been set).
        // When analytics is opt-in
        ServiceLocator.shared.analytics.optIn()
        // The analytics should be enabled
        XCTAssertEqual(appSettings.analyticsConsentState, .optedIn)
        XCTAssertTrue(ServiceLocator.shared.analytics.isEnabled)
        // Analytics client should have been started
        XCTAssertTrue(analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    func testAnalyticsStartIfNotEnabled() {
        // Given an existing install of the app where the user previously declined the tracking
        appSettings.analyticsConsentState = .optedOut
        // Analytics should not start
        XCTAssertFalse(ServiceLocator.shared.analytics.isEnabled)
        ServiceLocator.shared.analytics.startIfEnabled()
        XCTAssertFalse(analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    func testAnalyticsStartIfEnabled() {
        // Given an existing install of the app where the user previously accepted the tracking
        appSettings.analyticsConsentState = .optedIn
        // Analytics should start
        XCTAssertTrue(ServiceLocator.shared.analytics.isEnabled)
        ServiceLocator.shared.analytics.startIfEnabled()
        XCTAssertTrue(analyticsClient.startAnalyticsConfigurationCalled)
    }
    
    func testAddingUserProperties() {
        // Given a client with no user properties set
        let client = PostHogAnalyticsClient()
        XCTAssertNil(client.pendingUserProperties, "No user properties should have been set yet.")
        
        // When updating the user properties
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil,
                                                                  ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: 4,
                                                                  numSpaces: 5, recoveryState: .Disabled, verificationState: .Verified))
        
        // Then the properties should be cached
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should match.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should match.")
        XCTAssertEqual(client.pendingUserProperties?.verificationState, AnalyticsEvent.UserProperties.VerificationState.Verified, "The verification state should match.")
        XCTAssertEqual(client.pendingUserProperties?.recoveryState, AnalyticsEvent.UserProperties.RecoveryState.Disabled, "The recovery state should match.")
    }
    
    func testMergingUserProperties() {
        // Given a client with a cached use case user properties
        let client = PostHogAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: nil,
                                                                  numSpaces: nil, recoveryState: nil, verificationState: nil))
        
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        XCTAssertNil(client.pendingUserProperties?.numFavouriteRooms, "The number of favorite rooms should not be set.")
        XCTAssertNil(client.pendingUserProperties?.numSpaces, "The number of spaces should not be set.")
        
        // When updating the number of spaced
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: nil,
                                                                  numFavouriteRooms: 4,
                                                                  numSpaces: 5, recoveryState: nil, verificationState: nil))
        
        // Then the new properties should be updated and the existing properties should remain unchanged
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection shouldn't have changed.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should have been updated.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should have been updated.")
    }
    
    func testSendingUserProperties() {
        // Given a client with user properties set
        
        let client = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        client.start(analyticsConfiguration: appSettings.analyticsConfiguration)
        
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging,
                                                                  numFavouriteRooms: nil,
                                                                  numSpaces: nil, recoveryState: nil, verificationState: nil))
        
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        
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
        XCTAssertEqual(capturedEvent?.userProperties?["ftueUseCaseSelection"] as? String, AnalyticsEvent.UserProperties.FtueUseCaseSelection.PersonalMessaging.rawValue)
        
        // Then the properties should be cleared
        XCTAssertNil(client.pendingUserProperties, "The user properties should be cleared.")
    }
    
    func testResetConsentState() {
        // Given an existing install of the app where the user previously accpeted the tracking
        appSettings.analyticsConsentState = .optedIn
        XCTAssertFalse(ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt)
        
        // When forgetting analytics consents
        ServiceLocator.shared.analytics.resetConsentState()
        
        // Then the analytics prompt should be presented again
        XCTAssertEqual(appSettings.analyticsConsentState, .unknown)
        XCTAssertTrue(ServiceLocator.shared.analytics.shouldShowAnalyticsPrompt)
    }
    
    func testSendingAndUpdatingSuperProperties() {
        // Given a client with user properties set
        let client = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        client.start(analyticsConfiguration: appSettings.analyticsConfiguration)
        
        client.updateSuperProperties(
            AnalyticsEvent.SuperProperties(appPlatform: .EXI,
                                           cryptoSDK: .Rust,
                                           cryptoSDKVersion: "000")
        )
        
        // When sending an event (tests run under Debug configuration so this is sent to the development instance)
        client.screen(AnalyticsEvent.MobileScreen(durationMs: nil, screenName: .Home))
        
        let screenEvent = posthogMock.screenPropertiesReceivedArguments
        
        XCTAssertEqual(screenEvent?.screenTitle, AnalyticsEvent.MobileScreen.ScreenName.Home.rawValue)
        
        // All the super properties should have been added
        XCTAssertEqual(screenEvent?.properties?["cryptoSDK"] as? String, AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        XCTAssertEqual(screenEvent?.properties?["appPlatform"] as? String, "EXI")
        XCTAssertEqual(screenEvent?.properties?["cryptoSDKVersion"] as? String, "000")
        
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
        XCTAssertEqual(capturedEvent?.properties?["cryptoSDK"] as? String, AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        XCTAssertEqual(capturedEvent?.properties?["appPlatform"] as? String, "EXI")
        XCTAssertEqual(capturedEvent?.properties?["cryptoSDKVersion"] as? String, "000")
        
        // Updating should keep the previously set properties
        client.updateSuperProperties(
            AnalyticsEvent.SuperProperties(appPlatform: .EXI,
                                           cryptoSDK: .Rust,
                                           cryptoSDKVersion: "001")
        )
        
        client.capture(someEvent)
        let capturedEvent2 = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        // All the super properties should have been added, with the one udpated
        XCTAssertEqual(capturedEvent2?.properties?["cryptoSDK"] as? String, AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        XCTAssertEqual(capturedEvent2?.properties?["appPlatform"] as? String, "EXI")
        XCTAssertEqual(capturedEvent2?.properties?["cryptoSDKVersion"] as? String, "001")
    }
    
    func testShouldNotReportIfNotStarted() {
        // Given a client with user properties set
        let client = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
    
        // No call to start
        
        client.screen(AnalyticsEvent.MobileScreen(durationMs: nil, screenName: .Home))
        
        XCTAssertEqual(posthogMock.screenPropertiesCalled, false)
        
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
        
        XCTAssertEqual(posthogMock.capturePropertiesUserPropertiesCalled, false)
        
        // start now
        client.start(analyticsConfiguration: appSettings.analyticsConfiguration)
        XCTAssertEqual(posthogMock.optInCalled, true)
        
        client.capture(someEvent)
        XCTAssertEqual(posthogMock.capturePropertiesUserPropertiesCalled, true)
    }
}
