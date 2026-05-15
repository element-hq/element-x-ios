//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

// sourcery: AutoMockable
protocol AnalyticsServiceProtocol: AnyObject {
    var signpost: Signposter { get }
    var shouldShowAnalyticsPrompt: Bool { get }
    var isEnabled: Bool { get }

    func optIn()
    func optOut()
    func startIfEnabled()
    func reset()
    func resetConsentState()
    
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName, duration milliseconds: Int?)
    func trackInteraction(index: Int?, name: AnalyticsEvent.Interaction.Name)
    func trackError(context: String?, domain: AnalyticsEvent.Error.Domain,
                    name: AnalyticsEvent.Error.Name,
                    timeToDecryptMillis: Int?,
                    eventLocalAgeMillis: Int?,
                    isFederated: Bool?,
                    isMatrixDotOrg: Bool?,
                    userTrustsOwnIdentity: Bool?,
                    wasVisibleToUser: Bool?)
    func trackCreatedRoom(isDM: Bool)
    func trackComposer(inThread: Bool,
                       isEditing: Bool,
                       isReply: Bool,
                       messageType: AnalyticsEvent.Composer.MessageType,
                       startsThread: Bool?)
    func trackViewRoom(isDM: Bool, isSpace: Bool)
    func trackJoinedRoom(isDM: Bool, isSpace: Bool, activeMemberCount: UInt)
    func trackPollCreated(isUndisclosed: Bool, numberOfAnswers: Int)
    func trackPollVote()
    func trackPollEnd()
    func trackRoomModeration(action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?)
    func trackSessionSecurityState(_ state: SessionSecurityState)
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties)
    func trackPinUnpinEvent(_ event: AnalyticsEvent.PinUnpinAction)
}

extension AnalyticsServiceProtocol {
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName,
               duration milliseconds: Int? = nil) {
        track(screen: screen, duration: milliseconds)
    }

    func trackInteraction(index: Int? = nil, name: AnalyticsEvent.Interaction.Name) {
        trackInteraction(index: index, name: name)
    }

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
                       messageType: AnalyticsEvent.Composer.MessageType = .Text,
                       startsThread: Bool?) {
        trackComposer(inThread: inThread,
                      isEditing: isEditing,
                      isReply: isReply,
                      messageType: messageType,
                      startsThread: startsThread)
    }
}
