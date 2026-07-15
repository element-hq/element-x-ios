//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

/// A service responsible for managing analytics clients and sending events through them.
///
/// Events may include user activity, or app health data such as crashes,
/// non-fatal issues and performance.
///
/// ## Creating Analytics Events
///
/// Events are managed in a shared repo for all Element clients https://github.com/matrix-org/matrix-analytics-events
/// To add a new event create a PR to that repo with the new/updated schema. Once merged
/// into `main`, update the AnalyticsEvents Swift package in `project.yml`.
protocol AnalyticsServiceProtocol: AnyObject {
    /// A signpost client for performance testing the app. This client doesn't respect the
    /// `isRunning` state or behave any differently when `start`/`reset` are called.
    var signpost: Signposter { get }
    
    /// Whether to show the user the analytics opt in prompt.
    var shouldShowAnalyticsPrompt: Bool { get }
    
    /// Whether analytics tracking is currently enabled.
    var isEnabled: Bool { get }
    
    /// Opts in to analytics tracking.
    func optIn()
    
    /// Stops analytics tracking and calls `reset` to clear any IDs and event queues.
    func optOut()
    
    /// Starts the analytics client if the user has opted in, otherwise does nothing.
    func startIfEnabled()
    
    /// Resets any IDs and event queues in the analytics client. This method should
    /// be called on sign-out to maintain opt-in status, whilst ensuring the next
    /// account used isn't associated with the previous one.
    /// Note: **MUST** be called before stopping PostHog or the reset is ignored.
    
    /// Resets the consent state for analytics.
    func resetConsentState()
    
    /// Track the presentation of a screen.
    /// - Parameter screen: The screen that was shown.
    /// - Parameter milliseconds: An optional value representing how long the screen was shown for in milliseconds.
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName, duration milliseconds: Int?)
    func trackInteraction(index: Int?, name: AnalyticsEvent.Interaction.Name)
    
    /// Track an analytics error event.
    /// - Parameter context: Additional context or description for the error.
    /// - Parameter domain: The domain to which the error belongs.
    /// - Parameter name: The name of the error.
    /// - Parameter timeToDecryptMillis: The time it took to decrypt the event in milliseconds. Only used for UTD errors; pass `nil` otherwise.
    ///   Can be found in `UnableToDecryptInfo`. If `UnableToDecryptInfo` contains `nil` for this value, pass `-1`.
    func trackError(context: String?, domain: AnalyticsEvent.Error.Domain,
                    name: AnalyticsEvent.Error.Name,
                    timeToDecryptMillis: Int?,
                    eventLocalAgeMillis: Int?,
                    isFederated: Bool?,
                    isMatrixDotOrg: Bool?,
                    userTrustsOwnIdentity: Bool?,
                    wasVisibleToUser: Bool?)
    
    /// Track the creation of a room.
    /// - Parameter isDM: `true` if the created room is a direct message, `false` otherwise.
    func trackCreatedRoom(isDM: Bool)
    
    /// Track the composer.
    /// - Parameters:
    ///   - inThread: Whether the composer is used in a thread.
    ///   - isEditing: Whether the composer is used to edit a message.
    ///   - isReply: Whether the composer is used to reply to a message.
    ///   - messageType: The type of the message.
    ///   - startsThread: Whether the composer is used to start a new thread.
    func trackComposer(inThread: Bool,
                       isEditing: Bool,
                       isReply: Bool,
                       messageType: AnalyticsEvent.Composer.MessageType,
                       startsThread: Bool?)
    
    /// Track the presentation of a room.
    /// - Parameters:
    ///   - isDM: Whether the room is a direct message.
    ///   - isSpace: Whether the room is a space.
    func trackViewRoom(isDM: Bool, isSpace: Bool)
    
    /// Track the action of joining a room.
    /// - Parameters:
    ///   - isDM: Whether the room is a direct message.
    ///   - isSpace: Whether the room is a space.
    ///   - activeMemberCount: The number of active members in the room.
    func trackJoinedRoom(isDM: Bool, isSpace: Bool, activeMemberCount: UInt)
    
    /// Track the action of creating a poll.
    /// - Parameters:
    ///   - isUndisclosed: Whether the poll is undisclosed.
    ///   - numberOfAnswers: The number of options in the poll.
    func trackPollCreated(isUndisclosed: Bool, numberOfAnswers: Int)
    
    /// Track the action of voting on a poll.
    func trackPollVote()
    
    /// Track the action of ending a poll.
    func trackPollEnd()
    
    /// Track a room moderation action.
    func trackRoomModeration(action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?)
    func trackSessionSecurityState(_ state: SessionSecurityState)
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties)
    func trackPinUnpinEvent(_ event: AnalyticsEvent.PinUnpinAction)
}

// sourcery: AutoMockable
extension AnalyticsServiceProtocol {
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName) {
        track(screen: screen, duration: nil)
    }
    
    func trackInteraction(name: AnalyticsEvent.Interaction.Name) {
        trackInteraction(index: nil, name: name)
    }
    
    @_disfavoredOverload // make sure this doesn't cause infinite recursion
    func trackError(context: String?,
                    domain: AnalyticsEvent.Error.Domain,
                    name: AnalyticsEvent.Error.Name,
                    timeToDecryptMillis: Int? = nil,
                    eventLocalAgeMillis: Int? = nil,
                    isFederated: Bool? = nil,
                    isMatrixDotOrg: Bool? = nil,
                    userTrustsOwnIdentity: Bool? = nil,
                    wasVisibleToUser: Bool? = nil) {
        trackError(context: context,
                   domain: domain,
                   name: name,
                   timeToDecryptMillis: timeToDecryptMillis,
                   eventLocalAgeMillis: eventLocalAgeMillis,
                   isFederated: isFederated,
                   isMatrixDotOrg: isMatrixDotOrg,
                   userTrustsOwnIdentity: userTrustsOwnIdentity,
                   wasVisibleToUser: wasVisibleToUser)
    }
    
    func trackComposer(inThread: Bool,
                       isEditing: Bool,
                       isReply: Bool,
                       startsThread: Bool?) {
        trackComposer(inThread: inThread,
                      isEditing: isEditing,
                      isReply: isReply,
                      messageType: .Text,
                      startsThread: startsThread)
    }
}
