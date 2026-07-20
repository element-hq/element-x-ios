//
// Copyright 2025 Element Creations Ltd.
// Copyright 2021-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents
import Combine
import PostHog

class AnalyticsService: AnalyticsServiceProtocol {
    /// The analytics client to send events with.
    private let client: AnalyticsClientProtocol
    private let appSettings: AppSettings
    
    let signpost = Signposter()
    
    init(client: AnalyticsClientProtocol, appSettings: AppSettings) {
        self.client = client
        self.appSettings = appSettings
    }
    
    var shouldShowAnalyticsPrompt: Bool {
        // Only show the prompt once, and when analytics are enabled in BuildSettings.
        appSettings.analyticsConsentState == .unknown && appSettings.canPromptForAnalytics
    }
    
    var isEnabled: Bool {
        appSettings.analyticsConsentState == .optedIn
    }
    
    func optIn() {
        appSettings.analyticsConsentState = .optedIn
        startIfEnabled()
    }
    
    func optOut() {
        appSettings.analyticsConsentState = .optedOut
        
        // The order is important here. PostHog ignores the reset if stopped.
        reset()
        client.stop()
        
        MXLog.info("Stopped.")
    }
    
    func startIfEnabled() {
        guard isEnabled, !client.isRunning, let configuration = appSettings.analyticsConfiguration else { return }
        
        client.start(analyticsConfiguration: configuration)
        
        // Sanity check in case something went wrong.
        guard client.isRunning else { return }
        
        MXLog.info("Started.")
    }
    
    /// Resets any IDs and event queues in the analytics client. This method should
    /// be called on sign-out to ensure the next
    /// account used isn't associated with the previous one.
    /// Note: **MUST** be called before stopping PostHog or the reset is ignored.
    private func reset() {
        client.reset()
        MXLog.info("Reset.")
    }
    
    func resetConsentState() {
        MXLog.warning("Resetting consent state for analytics.")
        appSettings.analyticsConsentState = .unknown
    }
    
    // MARK: - Private
    
    /// Capture an event in the `client`.
    /// - Parameter event: The event to capture.
    private func capture(event: AnalyticsEventProtocol) {
        MXLog.debug("\(event)")
        client.capture(event)
    }
}

// MARK: - Public tracking methods

extension AnalyticsService {
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName, duration milliseconds: Int? = nil) {
        MXLog.debug("\(screen)")
        let event = AnalyticsEvent.MobileScreen(durationMs: milliseconds, screenName: screen)
        client.screen(event)
    }
    
    func trackInteraction(index: Int? = nil, name: AnalyticsEvent.Interaction.Name) {
        capture(event: AnalyticsEvent.Interaction(index: index, interactionType: .Touch, name: name))
    }
    
    func trackError(context: String?, domain: AnalyticsEvent.Error.Domain,
                    name: AnalyticsEvent.Error.Name,
                    timeToDecryptMillis: Int? = nil,
                    eventLocalAgeMillis: Int? = nil,
                    isFederated: Bool? = nil,
                    isMatrixDotOrg: Bool? = nil,
                    userTrustsOwnIdentity: Bool? = nil,
                    wasVisibleToUser: Bool? = nil) {
        // CryptoModule is deprecated
        capture(event: AnalyticsEvent.Error(context: context,
                                            cryptoModule: .Rust,
                                            cryptoSDK: .Rust,
                                            domain: domain,
                                            eventLocalAgeMillis: eventLocalAgeMillis,
                                            isFederated: isFederated,
                                            isMatrixDotOrg: isMatrixDotOrg,
                                            name: name,
                                            timeToDecryptMillis: timeToDecryptMillis,
                                            userTrustsOwnIdentity: userTrustsOwnIdentity,
                                            wasVisibleToUser: wasVisibleToUser))
    }
    
    func trackCreatedRoom(isDM: Bool) {
        capture(event: AnalyticsEvent.CreatedRoom(isDM: isDM))
    }
    
    func trackComposer(inThread: Bool,
                       isEditing: Bool,
                       isReply: Bool,
                       messageType: AnalyticsEvent.Composer.MessageType = .Text,
                       startsThread: Bool?) {
        capture(event: AnalyticsEvent.Composer(inThread: inThread,
                                               isEditing: isEditing,
                                               isReply: isReply,
                                               messageType: messageType,
                                               startsThread: startsThread))
    }
    
    func trackViewRoom(isDM: Bool, isSpace: Bool) {
        capture(event: AnalyticsEvent.ViewRoom(activeSpace: nil, isDM: isDM, isSpace: isSpace, trigger: nil, viaKeyboard: nil))
    }
    
    func trackJoinedRoom(isDM: Bool, isSpace: Bool, activeMemberCount: UInt) {
        guard let roomSize = AnalyticsEvent.JoinedRoom.RoomSize(memberCount: activeMemberCount) else {
            MXLog.error("invalid room size")
            return
        }
        capture(event: AnalyticsEvent.JoinedRoom(isDM: isDM, isSpace: isSpace, roomSize: roomSize, trigger: nil))
    }
    
    func trackPollCreated(isUndisclosed: Bool, numberOfAnswers: Int) {
        capture(event: AnalyticsEvent.PollCreation(action: .Create,
                                                   isUndisclosed: isUndisclosed,
                                                   numberOfAnswers: numberOfAnswers))
    }
    
    func trackPollVote() {
        capture(event: AnalyticsEvent.PollVote(doNotUse: nil))
    }
    
    func trackPollEnd() {
        capture(event: AnalyticsEvent.PollEnd(doNotUse: nil))
    }
    
    func trackRoomModeration(action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?) {
        let role = role.map(AnalyticsEvent.RoomModeration.Role.init)
        capture(event: AnalyticsEvent.RoomModeration(action: action, role: role))
    }
    
    func trackSessionSecurityState(_ state: SessionSecurityState) {
        let analyticsVerificationState: AnalyticsEvent.CryptoSessionStateChange.VerificationState
        
        switch state.verificationState {
        case .unknown:
            return
        case .verified:
            analyticsVerificationState = .Verified
        case .unverified:
            analyticsVerificationState = .NotVerified
        }
        
        let analyticsRecoveryState: AnalyticsEvent.CryptoSessionStateChange.RecoveryState
        
        switch state.recoveryState {
        case .enabled:
            analyticsRecoveryState = .Enabled
        case .disabled:
            analyticsRecoveryState = .Disabled
        case .incomplete:
            analyticsRecoveryState = .Incomplete
        case .unknown:
            return
        case .settingUp:
            return
        }
        
        let event = AnalyticsEvent.CryptoSessionStateChange(recoveryState: analyticsRecoveryState, verificationState: analyticsVerificationState)
        client.capture(event)
    }
    
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        client.updateUserProperties(userProperties)
    }
    
    func trackPinUnpinEvent(_ event: AnalyticsEvent.PinUnpinAction) {
        capture(event: event)
    }
}
