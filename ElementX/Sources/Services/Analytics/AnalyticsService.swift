//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents
import Combine
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
class AnalyticsService {
    /// The analytics client to send events with.
    private let client: AnalyticsClientProtocol
    private let appSettings: AppSettings
    
    /// A signpost client for performance testing the app. This client doesn't respect the
    /// `isRunning` state or behave any differently when `start`/`reset` are called.
    let signpost = Signposter()
    
    init(client: AnalyticsClientProtocol, appSettings: AppSettings) {
        self.client = client
        self.appSettings = appSettings
    }
    
    /// Whether to show the user the analytics opt in prompt.
    var shouldShowAnalyticsPrompt: Bool {
        // Only show the prompt once, and when analytics are enabled in BuildSettings.
        appSettings.analyticsConsentState == .unknown && appSettings.analyticsConfiguration.isEnabled
    }
    
    var isEnabled: Bool {
        appSettings.analyticsConsentState == .optedIn
    }
    
    /// Opts in to analytics tracking with the supplied user session.
    func optIn() {
        appSettings.analyticsConsentState = .optedIn
        startIfEnabled()
    }
    
    /// Stops analytics tracking and calls `reset` to clear any IDs and event queues.
    func optOut() {
        appSettings.analyticsConsentState = .optedOut
        
        // The order is important here. PostHog ignores the reset if stopped.
        reset()
        client.stop()

        MXLog.info("Stopped.")
    }
    
    /// Starts the analytics client if the user has opted in, otherwise does nothing.
    func startIfEnabled() {
        guard isEnabled, !client.isRunning else { return }
        
        client.start(analyticsConfiguration: appSettings.analyticsConfiguration)

        // Sanity check in case something went wrong.
        guard client.isRunning else { return }
        
        MXLog.info("Started.")
    }
    
    /// Resets the any IDs and event queues in the analytics client. This method should
    /// be called on sign-out to maintain opt-in status, whilst ensuring the next
    /// account used isn't associated with the previous one.
    /// Note: **MUST** be called before stopping PostHog or the reset is ignored.
    func reset() {
        client.reset()
        MXLog.info("Reset.")
    }
    
    /// Reset the consent state for analytics
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
    /// Track the presentation of a screen
    /// - Parameter screen: The screen that was shown
    /// - Parameter duration: An optional value representing how long the screen was shown for in milliseconds.
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName, duration milliseconds: Int? = nil) {
        MXLog.debug("\(screen)")
        let event = AnalyticsEvent.MobileScreen(durationMs: milliseconds, screenName: screen)
        client.screen(event)
    }
    
    func trackInteraction(index: Int? = nil, name: AnalyticsEvent.Interaction.Name) {
        capture(event: AnalyticsEvent.Interaction(index: index, interactionType: .Touch, name: name))
    }
    
    /// Track the presentation of a screen
    /// - Parameter context: To provide additional context or description for the error
    /// - Parameter domain: The domain to which the error belongs to.
    /// - Parameter name: The name of the error
    /// - Parameter timeToDecryptMillis: The time it took to decrypt the event in milliseconds, needs to be used only to track UTD errors, otherwise if the error is nort related to UTD it should be nil.
    /// Can be found in `UnableToDecryptInfo`. In case the `UnableToDecryptInfo` contains the value as nil, pass it as `-1`
    func trackError(context: String?, domain: AnalyticsEvent.Error.Domain, name: AnalyticsEvent.Error.Name, timeToDecryptMillis: Int? = nil) {
        // CryptoModule is deprecated
        capture(event: AnalyticsEvent.Error(context: context,
                                            cryptoModule: .Rust,
                                            cryptoSDK: .Rust,
                                            domain: domain,
                                            eventLocalAgeMillis: nil,
                                            isFederated: nil,
                                            isMatrixDotOrg: nil,
                                            name: name,
                                            timeToDecryptMillis: timeToDecryptMillis,
                                            userTrustsOwnIdentity: nil,
                                            wasVisibleToUser: nil))
    }
    
    /// Track the creation of a room
    /// - Parameter isDM: true if the created room is a direct message, false otherwise
    func trackCreatedRoom(isDM: Bool) {
        capture(event: AnalyticsEvent.CreatedRoom(isDM: isDM))
    }
    
    /// Track the composer
    /// - Parameters:
    ///   - inThread: whether the composer is used in a Thread
    ///   - isEditing: whether the composer is used to edit a message
    ///   - isReply: whether the composer is used to reply a message
    ///   - messageType: the type of the message
    ///   - startsThread: whether the composer is used to start a new thread
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
    
    /// Track the presentation of a room
    /// - Parameters:
    ///   - isDM: whether the room is a direct message
    ///   - isSpace: whether the room is a space
    func trackViewRoom(isDM: Bool, isSpace: Bool) {
        capture(event: AnalyticsEvent.ViewRoom(activeSpace: nil, isDM: isDM, isSpace: isSpace, trigger: nil, viaKeyboard: nil))
    }
    
    /// Track the action of joining a room
    /// - Parameters:
    ///   - isDM: whether the room is a direct message
    ///   - isSpace: whether the room is a space
    ///   - activeMemberCount: the number of active members in the room
    func trackJoinedRoom(isDM: Bool, isSpace: Bool, activeMemberCount: UInt) {
        guard let roomSize = AnalyticsEvent.JoinedRoom.RoomSize(memberCount: activeMemberCount) else {
            MXLog.error("invalid room size")
            return
        }
        capture(event: AnalyticsEvent.JoinedRoom(isDM: isDM, isSpace: isSpace, roomSize: roomSize, trigger: nil))
    }

    /// Track the action of creating a poll
    /// - Parameters:
    ///   - isUndisclosed: whether the poll is undisclosed
    ///   - numberOfAnswers: the number of options in the poll
    func trackPollCreated(isUndisclosed: Bool, numberOfAnswers: Int) {
        capture(event: AnalyticsEvent.PollCreation(action: .Create,
                                                   isUndisclosed: isUndisclosed,
                                                   numberOfAnswers: numberOfAnswers))
    }

    /// Track the action of voting on a poll
    func trackPollVote() {
        capture(event: AnalyticsEvent.PollVote(doNotUse: nil))
    }

    /// Track the action of ending a poll
    func trackPollEnd() {
        capture(event: AnalyticsEvent.PollEnd(doNotUse: nil))
    }
    
    /// Track a room moderation action.
    func trackRoomModeration(action: AnalyticsEvent.RoomModeration.Action, role: RoomMemberDetails.Role?) {
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
