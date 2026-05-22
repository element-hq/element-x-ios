// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
@preconcurrency import Combine
@preconcurrency import SwiftUI

@preconcurrency import MatrixRustSDK

import AnalyticsEvents
import AVFoundation
import CallKit
import Foundation
import LocalAuthentication
import Photos

class AnalyticsClientMock: AnalyticsClientProtocol, @unchecked Sendable {
    var isRunning: Bool {
        get { return underlyingIsRunning }
        set(value) { underlyingIsRunning = value }
    }
    var underlyingIsRunning: Bool!

    //MARK: - start

    private let startAnalyticsConfigurationCallsCountLock = NSLock()
    private var startAnalyticsConfigurationUnderlyingCallsCount = 0
    var startAnalyticsConfigurationCallsCount: Int {
        get { startAnalyticsConfigurationCallsCountLock.withLock { startAnalyticsConfigurationUnderlyingCallsCount } }
        set { startAnalyticsConfigurationCallsCountLock.withLock { startAnalyticsConfigurationUnderlyingCallsCount = newValue } }
    }
    var startAnalyticsConfigurationCalled: Bool {
        return startAnalyticsConfigurationCallsCount > 0
    }
    private let startAnalyticsConfigurationReceivedAnalyticsConfigurationLock = NSLock()
    private var startAnalyticsConfigurationUnderlyingReceivedAnalyticsConfiguration: AnalyticsConfiguration?
    var startAnalyticsConfigurationReceivedAnalyticsConfiguration: AnalyticsConfiguration? {
        get { startAnalyticsConfigurationReceivedAnalyticsConfigurationLock.withLock { startAnalyticsConfigurationUnderlyingReceivedAnalyticsConfiguration } }
        set { startAnalyticsConfigurationReceivedAnalyticsConfigurationLock.withLock { startAnalyticsConfigurationUnderlyingReceivedAnalyticsConfiguration = newValue } }
    }
    private let startAnalyticsConfigurationReceivedInvocationsLock = NSLock()
    private var startAnalyticsConfigurationUnderlyingReceivedInvocations: [AnalyticsConfiguration] = []
    var startAnalyticsConfigurationReceivedInvocations: [AnalyticsConfiguration] {
        get { startAnalyticsConfigurationReceivedInvocationsLock.withLock { startAnalyticsConfigurationUnderlyingReceivedInvocations } }
        set { startAnalyticsConfigurationReceivedInvocationsLock.withLock { startAnalyticsConfigurationUnderlyingReceivedInvocations = newValue } }
    }
    var startAnalyticsConfigurationClosure: ((AnalyticsConfiguration) -> Void)?

    func start(analyticsConfiguration: AnalyticsConfiguration) {
        startAnalyticsConfigurationCallsCountLock.withLock { startAnalyticsConfigurationUnderlyingCallsCount += 1 }
        startAnalyticsConfigurationReceivedAnalyticsConfiguration = analyticsConfiguration
        startAnalyticsConfigurationReceivedInvocationsLock.withLock { startAnalyticsConfigurationUnderlyingReceivedInvocations.append(analyticsConfiguration) }
        startAnalyticsConfigurationClosure?(analyticsConfiguration)
    }
    //MARK: - reset

    private let resetCallsCountLock = NSLock()
    private var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get { resetCallsCountLock.withLock { resetUnderlyingCallsCount } }
        set { resetCallsCountLock.withLock { resetUnderlyingCallsCount = newValue } }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCountLock.withLock { resetUnderlyingCallsCount += 1 }
        resetClosure?()
    }
    //MARK: - stop

    private let stopCallsCountLock = NSLock()
    private var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get { stopCallsCountLock.withLock { stopUnderlyingCallsCount } }
        set { stopCallsCountLock.withLock { stopUnderlyingCallsCount = newValue } }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCountLock.withLock { stopUnderlyingCallsCount += 1 }
        stopClosure?()
    }
    //MARK: - capture

    private let captureCallsCountLock = NSLock()
    private var captureUnderlyingCallsCount = 0
    var captureCallsCount: Int {
        get { captureCallsCountLock.withLock { captureUnderlyingCallsCount } }
        set { captureCallsCountLock.withLock { captureUnderlyingCallsCount = newValue } }
    }
    var captureCalled: Bool {
        return captureCallsCount > 0
    }
    private let captureReceivedEventLock = NSLock()
    private var captureUnderlyingReceivedEvent: AnalyticsEventProtocol?
    var captureReceivedEvent: AnalyticsEventProtocol? {
        get { captureReceivedEventLock.withLock { captureUnderlyingReceivedEvent } }
        set { captureReceivedEventLock.withLock { captureUnderlyingReceivedEvent = newValue } }
    }
    private let captureReceivedInvocationsLock = NSLock()
    private var captureUnderlyingReceivedInvocations: [AnalyticsEventProtocol] = []
    var captureReceivedInvocations: [AnalyticsEventProtocol] {
        get { captureReceivedInvocationsLock.withLock { captureUnderlyingReceivedInvocations } }
        set { captureReceivedInvocationsLock.withLock { captureUnderlyingReceivedInvocations = newValue } }
    }
    var captureClosure: ((AnalyticsEventProtocol) -> Void)?

    func capture(_ event: AnalyticsEventProtocol) {
        captureCallsCountLock.withLock { captureUnderlyingCallsCount += 1 }
        captureReceivedEvent = event
        captureReceivedInvocationsLock.withLock { captureUnderlyingReceivedInvocations.append(event) }
        captureClosure?(event)
    }
    //MARK: - screen

    private let screenCallsCountLock = NSLock()
    private var screenUnderlyingCallsCount = 0
    var screenCallsCount: Int {
        get { screenCallsCountLock.withLock { screenUnderlyingCallsCount } }
        set { screenCallsCountLock.withLock { screenUnderlyingCallsCount = newValue } }
    }
    var screenCalled: Bool {
        return screenCallsCount > 0
    }
    private let screenReceivedEventLock = NSLock()
    private var screenUnderlyingReceivedEvent: AnalyticsScreenProtocol?
    var screenReceivedEvent: AnalyticsScreenProtocol? {
        get { screenReceivedEventLock.withLock { screenUnderlyingReceivedEvent } }
        set { screenReceivedEventLock.withLock { screenUnderlyingReceivedEvent = newValue } }
    }
    private let screenReceivedInvocationsLock = NSLock()
    private var screenUnderlyingReceivedInvocations: [AnalyticsScreenProtocol] = []
    var screenReceivedInvocations: [AnalyticsScreenProtocol] {
        get { screenReceivedInvocationsLock.withLock { screenUnderlyingReceivedInvocations } }
        set { screenReceivedInvocationsLock.withLock { screenUnderlyingReceivedInvocations = newValue } }
    }
    var screenClosure: ((AnalyticsScreenProtocol) -> Void)?

    func screen(_ event: AnalyticsScreenProtocol) {
        screenCallsCountLock.withLock { screenUnderlyingCallsCount += 1 }
        screenReceivedEvent = event
        screenReceivedInvocationsLock.withLock { screenUnderlyingReceivedInvocations.append(event) }
        screenClosure?(event)
    }
    //MARK: - updateUserProperties

    private let updateUserPropertiesCallsCountLock = NSLock()
    private var updateUserPropertiesUnderlyingCallsCount = 0
    var updateUserPropertiesCallsCount: Int {
        get { updateUserPropertiesCallsCountLock.withLock { updateUserPropertiesUnderlyingCallsCount } }
        set { updateUserPropertiesCallsCountLock.withLock { updateUserPropertiesUnderlyingCallsCount = newValue } }
    }
    var updateUserPropertiesCalled: Bool {
        return updateUserPropertiesCallsCount > 0
    }
    private let updateUserPropertiesReceivedEventLock = NSLock()
    private var updateUserPropertiesUnderlyingReceivedEvent: AnalyticsEvent.UserProperties?
    var updateUserPropertiesReceivedEvent: AnalyticsEvent.UserProperties? {
        get { updateUserPropertiesReceivedEventLock.withLock { updateUserPropertiesUnderlyingReceivedEvent } }
        set { updateUserPropertiesReceivedEventLock.withLock { updateUserPropertiesUnderlyingReceivedEvent = newValue } }
    }
    private let updateUserPropertiesReceivedInvocationsLock = NSLock()
    private var updateUserPropertiesUnderlyingReceivedInvocations: [AnalyticsEvent.UserProperties] = []
    var updateUserPropertiesReceivedInvocations: [AnalyticsEvent.UserProperties] {
        get { updateUserPropertiesReceivedInvocationsLock.withLock { updateUserPropertiesUnderlyingReceivedInvocations } }
        set { updateUserPropertiesReceivedInvocationsLock.withLock { updateUserPropertiesUnderlyingReceivedInvocations = newValue } }
    }
    var updateUserPropertiesClosure: ((AnalyticsEvent.UserProperties) -> Void)?

    func updateUserProperties(_ event: AnalyticsEvent.UserProperties) {
        updateUserPropertiesCallsCountLock.withLock { updateUserPropertiesUnderlyingCallsCount += 1 }
        updateUserPropertiesReceivedEvent = event
        updateUserPropertiesReceivedInvocationsLock.withLock { updateUserPropertiesUnderlyingReceivedInvocations.append(event) }
        updateUserPropertiesClosure?(event)
    }
}
class AnalyticsServiceMock: AnalyticsServiceProtocol, @unchecked Sendable {
    var signpost: Signposter {
        get { return underlyingSignpost }
        set(value) { underlyingSignpost = value }
    }
    var underlyingSignpost: Signposter!
    var shouldShowAnalyticsPrompt: Bool {
        get { return underlyingShouldShowAnalyticsPrompt }
        set(value) { underlyingShouldShowAnalyticsPrompt = value }
    }
    var underlyingShouldShowAnalyticsPrompt: Bool!
    var isEnabled: Bool {
        get { return underlyingIsEnabled }
        set(value) { underlyingIsEnabled = value }
    }
    var underlyingIsEnabled: Bool!

    //MARK: - optIn

    private let optInCallsCountLock = NSLock()
    private var optInUnderlyingCallsCount = 0
    var optInCallsCount: Int {
        get { optInCallsCountLock.withLock { optInUnderlyingCallsCount } }
        set { optInCallsCountLock.withLock { optInUnderlyingCallsCount = newValue } }
    }
    var optInCalled: Bool {
        return optInCallsCount > 0
    }
    var optInClosure: (() -> Void)?

    func optIn() {
        optInCallsCountLock.withLock { optInUnderlyingCallsCount += 1 }
        optInClosure?()
    }
    //MARK: - optOut

    private let optOutCallsCountLock = NSLock()
    private var optOutUnderlyingCallsCount = 0
    var optOutCallsCount: Int {
        get { optOutCallsCountLock.withLock { optOutUnderlyingCallsCount } }
        set { optOutCallsCountLock.withLock { optOutUnderlyingCallsCount = newValue } }
    }
    var optOutCalled: Bool {
        return optOutCallsCount > 0
    }
    var optOutClosure: (() -> Void)?

    func optOut() {
        optOutCallsCountLock.withLock { optOutUnderlyingCallsCount += 1 }
        optOutClosure?()
    }
    //MARK: - startIfEnabled

    private let startIfEnabledCallsCountLock = NSLock()
    private var startIfEnabledUnderlyingCallsCount = 0
    var startIfEnabledCallsCount: Int {
        get { startIfEnabledCallsCountLock.withLock { startIfEnabledUnderlyingCallsCount } }
        set { startIfEnabledCallsCountLock.withLock { startIfEnabledUnderlyingCallsCount = newValue } }
    }
    var startIfEnabledCalled: Bool {
        return startIfEnabledCallsCount > 0
    }
    var startIfEnabledClosure: (() -> Void)?

    func startIfEnabled() {
        startIfEnabledCallsCountLock.withLock { startIfEnabledUnderlyingCallsCount += 1 }
        startIfEnabledClosure?()
    }
    //MARK: - reset

    private let resetCallsCountLock = NSLock()
    private var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get { resetCallsCountLock.withLock { resetUnderlyingCallsCount } }
        set { resetCallsCountLock.withLock { resetUnderlyingCallsCount = newValue } }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCountLock.withLock { resetUnderlyingCallsCount += 1 }
        resetClosure?()
    }
    //MARK: - resetConsentState

    private let resetConsentStateCallsCountLock = NSLock()
    private var resetConsentStateUnderlyingCallsCount = 0
    var resetConsentStateCallsCount: Int {
        get { resetConsentStateCallsCountLock.withLock { resetConsentStateUnderlyingCallsCount } }
        set { resetConsentStateCallsCountLock.withLock { resetConsentStateUnderlyingCallsCount = newValue } }
    }
    var resetConsentStateCalled: Bool {
        return resetConsentStateCallsCount > 0
    }
    var resetConsentStateClosure: (() -> Void)?

    func resetConsentState() {
        resetConsentStateCallsCountLock.withLock { resetConsentStateUnderlyingCallsCount += 1 }
        resetConsentStateClosure?()
    }
    //MARK: - track

    private let trackScreenDurationCallsCountLock = NSLock()
    private var trackScreenDurationUnderlyingCallsCount = 0
    var trackScreenDurationCallsCount: Int {
        get { trackScreenDurationCallsCountLock.withLock { trackScreenDurationUnderlyingCallsCount } }
        set { trackScreenDurationCallsCountLock.withLock { trackScreenDurationUnderlyingCallsCount = newValue } }
    }
    var trackScreenDurationCalled: Bool {
        return trackScreenDurationCallsCount > 0
    }
    private let trackScreenDurationReceivedArgumentsLock = NSLock()
    private var trackScreenDurationUnderlyingReceivedArguments: (screen: AnalyticsEvent.MobileScreen.ScreenName, milliseconds: Int?)?
    var trackScreenDurationReceivedArguments: (screen: AnalyticsEvent.MobileScreen.ScreenName, milliseconds: Int?)? {
        get { trackScreenDurationReceivedArgumentsLock.withLock { trackScreenDurationUnderlyingReceivedArguments } }
        set { trackScreenDurationReceivedArgumentsLock.withLock { trackScreenDurationUnderlyingReceivedArguments = newValue } }
    }
    private let trackScreenDurationReceivedInvocationsLock = NSLock()
    private var trackScreenDurationUnderlyingReceivedInvocations: [(screen: AnalyticsEvent.MobileScreen.ScreenName, milliseconds: Int?)] = []
    var trackScreenDurationReceivedInvocations: [(screen: AnalyticsEvent.MobileScreen.ScreenName, milliseconds: Int?)] {
        get { trackScreenDurationReceivedInvocationsLock.withLock { trackScreenDurationUnderlyingReceivedInvocations } }
        set { trackScreenDurationReceivedInvocationsLock.withLock { trackScreenDurationUnderlyingReceivedInvocations = newValue } }
    }
    var trackScreenDurationClosure: ((AnalyticsEvent.MobileScreen.ScreenName, Int?) -> Void)?

    func track(screen: AnalyticsEvent.MobileScreen.ScreenName, duration milliseconds: Int?) {
        trackScreenDurationCallsCountLock.withLock { trackScreenDurationUnderlyingCallsCount += 1 }
        trackScreenDurationReceivedArguments = (screen: screen, milliseconds: milliseconds)
        trackScreenDurationReceivedInvocationsLock.withLock { trackScreenDurationUnderlyingReceivedInvocations.append((screen: screen, milliseconds: milliseconds)) }
        trackScreenDurationClosure?(screen, milliseconds)
    }
    //MARK: - trackInteraction

    private let trackInteractionIndexNameCallsCountLock = NSLock()
    private var trackInteractionIndexNameUnderlyingCallsCount = 0
    var trackInteractionIndexNameCallsCount: Int {
        get { trackInteractionIndexNameCallsCountLock.withLock { trackInteractionIndexNameUnderlyingCallsCount } }
        set { trackInteractionIndexNameCallsCountLock.withLock { trackInteractionIndexNameUnderlyingCallsCount = newValue } }
    }
    var trackInteractionIndexNameCalled: Bool {
        return trackInteractionIndexNameCallsCount > 0
    }
    private let trackInteractionIndexNameReceivedArgumentsLock = NSLock()
    private var trackInteractionIndexNameUnderlyingReceivedArguments: (index: Int?, name: AnalyticsEvent.Interaction.Name)?
    var trackInteractionIndexNameReceivedArguments: (index: Int?, name: AnalyticsEvent.Interaction.Name)? {
        get { trackInteractionIndexNameReceivedArgumentsLock.withLock { trackInteractionIndexNameUnderlyingReceivedArguments } }
        set { trackInteractionIndexNameReceivedArgumentsLock.withLock { trackInteractionIndexNameUnderlyingReceivedArguments = newValue } }
    }
    private let trackInteractionIndexNameReceivedInvocationsLock = NSLock()
    private var trackInteractionIndexNameUnderlyingReceivedInvocations: [(index: Int?, name: AnalyticsEvent.Interaction.Name)] = []
    var trackInteractionIndexNameReceivedInvocations: [(index: Int?, name: AnalyticsEvent.Interaction.Name)] {
        get { trackInteractionIndexNameReceivedInvocationsLock.withLock { trackInteractionIndexNameUnderlyingReceivedInvocations } }
        set { trackInteractionIndexNameReceivedInvocationsLock.withLock { trackInteractionIndexNameUnderlyingReceivedInvocations = newValue } }
    }
    var trackInteractionIndexNameClosure: ((Int?, AnalyticsEvent.Interaction.Name) -> Void)?

    func trackInteraction(index: Int?, name: AnalyticsEvent.Interaction.Name) {
        trackInteractionIndexNameCallsCountLock.withLock { trackInteractionIndexNameUnderlyingCallsCount += 1 }
        trackInteractionIndexNameReceivedArguments = (index: index, name: name)
        trackInteractionIndexNameReceivedInvocationsLock.withLock { trackInteractionIndexNameUnderlyingReceivedInvocations.append((index: index, name: name)) }
        trackInteractionIndexNameClosure?(index, name)
    }
    //MARK: - trackError

    private let trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCallsCountLock = NSLock()
    private var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingCallsCount = 0
    var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCallsCount: Int {
        get { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCallsCountLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingCallsCount } }
        set { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCallsCountLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingCallsCount = newValue } }
    }
    var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCalled: Bool {
        return trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCallsCount > 0
    }
    private let trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedArgumentsLock = NSLock()
    private var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedArguments: (context: String?, domain: AnalyticsEvent.Error.Domain, name: AnalyticsEvent.Error.Name, timeToDecryptMillis: Int?, eventLocalAgeMillis: Int?, isFederated: Bool?, isMatrixDotOrg: Bool?, userTrustsOwnIdentity: Bool?, wasVisibleToUser: Bool?)?
    var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedArguments: (context: String?, domain: AnalyticsEvent.Error.Domain, name: AnalyticsEvent.Error.Name, timeToDecryptMillis: Int?, eventLocalAgeMillis: Int?, isFederated: Bool?, isMatrixDotOrg: Bool?, userTrustsOwnIdentity: Bool?, wasVisibleToUser: Bool?)? {
        get { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedArgumentsLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedArguments } }
        set { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedArgumentsLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedArguments = newValue } }
    }
    private let trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedInvocationsLock = NSLock()
    private var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedInvocations: [(context: String?, domain: AnalyticsEvent.Error.Domain, name: AnalyticsEvent.Error.Name, timeToDecryptMillis: Int?, eventLocalAgeMillis: Int?, isFederated: Bool?, isMatrixDotOrg: Bool?, userTrustsOwnIdentity: Bool?, wasVisibleToUser: Bool?)] = []
    var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedInvocations: [(context: String?, domain: AnalyticsEvent.Error.Domain, name: AnalyticsEvent.Error.Name, timeToDecryptMillis: Int?, eventLocalAgeMillis: Int?, isFederated: Bool?, isMatrixDotOrg: Bool?, userTrustsOwnIdentity: Bool?, wasVisibleToUser: Bool?)] {
        get { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedInvocationsLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedInvocations } }
        set { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedInvocationsLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedInvocations = newValue } }
    }
    var trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserClosure: ((String?, AnalyticsEvent.Error.Domain, AnalyticsEvent.Error.Name, Int?, Int?, Bool?, Bool?, Bool?, Bool?) -> Void)?

    func trackError(context: String?, domain: AnalyticsEvent.Error.Domain, name: AnalyticsEvent.Error.Name, timeToDecryptMillis: Int?, eventLocalAgeMillis: Int?, isFederated: Bool?, isMatrixDotOrg: Bool?, userTrustsOwnIdentity: Bool?, wasVisibleToUser: Bool?) {
        trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserCallsCountLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingCallsCount += 1 }
        trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedArguments = (context: context, domain: domain, name: name, timeToDecryptMillis: timeToDecryptMillis, eventLocalAgeMillis: eventLocalAgeMillis, isFederated: isFederated, isMatrixDotOrg: isMatrixDotOrg, userTrustsOwnIdentity: userTrustsOwnIdentity, wasVisibleToUser: wasVisibleToUser)
        trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserReceivedInvocationsLock.withLock { trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserUnderlyingReceivedInvocations.append((context: context, domain: domain, name: name, timeToDecryptMillis: timeToDecryptMillis, eventLocalAgeMillis: eventLocalAgeMillis, isFederated: isFederated, isMatrixDotOrg: isMatrixDotOrg, userTrustsOwnIdentity: userTrustsOwnIdentity, wasVisibleToUser: wasVisibleToUser)) }
        trackErrorContextDomainNameTimeToDecryptMillisEventLocalAgeMillisIsFederatedIsMatrixDotOrgUserTrustsOwnIdentityWasVisibleToUserClosure?(context, domain, name, timeToDecryptMillis, eventLocalAgeMillis, isFederated, isMatrixDotOrg, userTrustsOwnIdentity, wasVisibleToUser)
    }
    //MARK: - trackCreatedRoom

    private let trackCreatedRoomIsDMCallsCountLock = NSLock()
    private var trackCreatedRoomIsDMUnderlyingCallsCount = 0
    var trackCreatedRoomIsDMCallsCount: Int {
        get { trackCreatedRoomIsDMCallsCountLock.withLock { trackCreatedRoomIsDMUnderlyingCallsCount } }
        set { trackCreatedRoomIsDMCallsCountLock.withLock { trackCreatedRoomIsDMUnderlyingCallsCount = newValue } }
    }
    var trackCreatedRoomIsDMCalled: Bool {
        return trackCreatedRoomIsDMCallsCount > 0
    }
    private let trackCreatedRoomIsDMReceivedIsDMLock = NSLock()
    private var trackCreatedRoomIsDMUnderlyingReceivedIsDM: Bool?
    var trackCreatedRoomIsDMReceivedIsDM: Bool? {
        get { trackCreatedRoomIsDMReceivedIsDMLock.withLock { trackCreatedRoomIsDMUnderlyingReceivedIsDM } }
        set { trackCreatedRoomIsDMReceivedIsDMLock.withLock { trackCreatedRoomIsDMUnderlyingReceivedIsDM = newValue } }
    }
    private let trackCreatedRoomIsDMReceivedInvocationsLock = NSLock()
    private var trackCreatedRoomIsDMUnderlyingReceivedInvocations: [Bool] = []
    var trackCreatedRoomIsDMReceivedInvocations: [Bool] {
        get { trackCreatedRoomIsDMReceivedInvocationsLock.withLock { trackCreatedRoomIsDMUnderlyingReceivedInvocations } }
        set { trackCreatedRoomIsDMReceivedInvocationsLock.withLock { trackCreatedRoomIsDMUnderlyingReceivedInvocations = newValue } }
    }
    var trackCreatedRoomIsDMClosure: ((Bool) -> Void)?

    func trackCreatedRoom(isDM: Bool) {
        trackCreatedRoomIsDMCallsCountLock.withLock { trackCreatedRoomIsDMUnderlyingCallsCount += 1 }
        trackCreatedRoomIsDMReceivedIsDM = isDM
        trackCreatedRoomIsDMReceivedInvocationsLock.withLock { trackCreatedRoomIsDMUnderlyingReceivedInvocations.append(isDM) }
        trackCreatedRoomIsDMClosure?(isDM)
    }
    //MARK: - trackComposer

    private let trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCallsCountLock = NSLock()
    private var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingCallsCount = 0
    var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCallsCount: Int {
        get { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCallsCountLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingCallsCount } }
        set { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCallsCountLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingCallsCount = newValue } }
    }
    var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCalled: Bool {
        return trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCallsCount > 0
    }
    private let trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedArgumentsLock = NSLock()
    private var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedArguments: (inThread: Bool, isEditing: Bool, isReply: Bool, messageType: AnalyticsEvent.Composer.MessageType, startsThread: Bool?)?
    var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedArguments: (inThread: Bool, isEditing: Bool, isReply: Bool, messageType: AnalyticsEvent.Composer.MessageType, startsThread: Bool?)? {
        get { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedArgumentsLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedArguments } }
        set { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedArgumentsLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedArguments = newValue } }
    }
    private let trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedInvocationsLock = NSLock()
    private var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedInvocations: [(inThread: Bool, isEditing: Bool, isReply: Bool, messageType: AnalyticsEvent.Composer.MessageType, startsThread: Bool?)] = []
    var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedInvocations: [(inThread: Bool, isEditing: Bool, isReply: Bool, messageType: AnalyticsEvent.Composer.MessageType, startsThread: Bool?)] {
        get { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedInvocationsLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedInvocations } }
        set { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedInvocationsLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedInvocations = newValue } }
    }
    var trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadClosure: ((Bool, Bool, Bool, AnalyticsEvent.Composer.MessageType, Bool?) -> Void)?

    func trackComposer(inThread: Bool, isEditing: Bool, isReply: Bool, messageType: AnalyticsEvent.Composer.MessageType, startsThread: Bool?) {
        trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadCallsCountLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingCallsCount += 1 }
        trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedArguments = (inThread: inThread, isEditing: isEditing, isReply: isReply, messageType: messageType, startsThread: startsThread)
        trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadReceivedInvocationsLock.withLock { trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadUnderlyingReceivedInvocations.append((inThread: inThread, isEditing: isEditing, isReply: isReply, messageType: messageType, startsThread: startsThread)) }
        trackComposerInThreadIsEditingIsReplyMessageTypeStartsThreadClosure?(inThread, isEditing, isReply, messageType, startsThread)
    }
    //MARK: - trackViewRoom

    private let trackViewRoomIsDMIsSpaceCallsCountLock = NSLock()
    private var trackViewRoomIsDMIsSpaceUnderlyingCallsCount = 0
    var trackViewRoomIsDMIsSpaceCallsCount: Int {
        get { trackViewRoomIsDMIsSpaceCallsCountLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingCallsCount } }
        set { trackViewRoomIsDMIsSpaceCallsCountLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingCallsCount = newValue } }
    }
    var trackViewRoomIsDMIsSpaceCalled: Bool {
        return trackViewRoomIsDMIsSpaceCallsCount > 0
    }
    private let trackViewRoomIsDMIsSpaceReceivedArgumentsLock = NSLock()
    private var trackViewRoomIsDMIsSpaceUnderlyingReceivedArguments: (isDM: Bool, isSpace: Bool)?
    var trackViewRoomIsDMIsSpaceReceivedArguments: (isDM: Bool, isSpace: Bool)? {
        get { trackViewRoomIsDMIsSpaceReceivedArgumentsLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingReceivedArguments } }
        set { trackViewRoomIsDMIsSpaceReceivedArgumentsLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingReceivedArguments = newValue } }
    }
    private let trackViewRoomIsDMIsSpaceReceivedInvocationsLock = NSLock()
    private var trackViewRoomIsDMIsSpaceUnderlyingReceivedInvocations: [(isDM: Bool, isSpace: Bool)] = []
    var trackViewRoomIsDMIsSpaceReceivedInvocations: [(isDM: Bool, isSpace: Bool)] {
        get { trackViewRoomIsDMIsSpaceReceivedInvocationsLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingReceivedInvocations } }
        set { trackViewRoomIsDMIsSpaceReceivedInvocationsLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingReceivedInvocations = newValue } }
    }
    var trackViewRoomIsDMIsSpaceClosure: ((Bool, Bool) -> Void)?

    func trackViewRoom(isDM: Bool, isSpace: Bool) {
        trackViewRoomIsDMIsSpaceCallsCountLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingCallsCount += 1 }
        trackViewRoomIsDMIsSpaceReceivedArguments = (isDM: isDM, isSpace: isSpace)
        trackViewRoomIsDMIsSpaceReceivedInvocationsLock.withLock { trackViewRoomIsDMIsSpaceUnderlyingReceivedInvocations.append((isDM: isDM, isSpace: isSpace)) }
        trackViewRoomIsDMIsSpaceClosure?(isDM, isSpace)
    }
    //MARK: - trackJoinedRoom

    private let trackJoinedRoomIsDMIsSpaceActiveMemberCountCallsCountLock = NSLock()
    private var trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingCallsCount = 0
    var trackJoinedRoomIsDMIsSpaceActiveMemberCountCallsCount: Int {
        get { trackJoinedRoomIsDMIsSpaceActiveMemberCountCallsCountLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingCallsCount } }
        set { trackJoinedRoomIsDMIsSpaceActiveMemberCountCallsCountLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingCallsCount = newValue } }
    }
    var trackJoinedRoomIsDMIsSpaceActiveMemberCountCalled: Bool {
        return trackJoinedRoomIsDMIsSpaceActiveMemberCountCallsCount > 0
    }
    private let trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedArgumentsLock = NSLock()
    private var trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedArguments: (isDM: Bool, isSpace: Bool, activeMemberCount: UInt)?
    var trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedArguments: (isDM: Bool, isSpace: Bool, activeMemberCount: UInt)? {
        get { trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedArgumentsLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedArguments } }
        set { trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedArgumentsLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedArguments = newValue } }
    }
    private let trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedInvocationsLock = NSLock()
    private var trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedInvocations: [(isDM: Bool, isSpace: Bool, activeMemberCount: UInt)] = []
    var trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedInvocations: [(isDM: Bool, isSpace: Bool, activeMemberCount: UInt)] {
        get { trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedInvocationsLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedInvocations } }
        set { trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedInvocationsLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedInvocations = newValue } }
    }
    var trackJoinedRoomIsDMIsSpaceActiveMemberCountClosure: ((Bool, Bool, UInt) -> Void)?

    func trackJoinedRoom(isDM: Bool, isSpace: Bool, activeMemberCount: UInt) {
        trackJoinedRoomIsDMIsSpaceActiveMemberCountCallsCountLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingCallsCount += 1 }
        trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedArguments = (isDM: isDM, isSpace: isSpace, activeMemberCount: activeMemberCount)
        trackJoinedRoomIsDMIsSpaceActiveMemberCountReceivedInvocationsLock.withLock { trackJoinedRoomIsDMIsSpaceActiveMemberCountUnderlyingReceivedInvocations.append((isDM: isDM, isSpace: isSpace, activeMemberCount: activeMemberCount)) }
        trackJoinedRoomIsDMIsSpaceActiveMemberCountClosure?(isDM, isSpace, activeMemberCount)
    }
    //MARK: - trackPollCreated

    private let trackPollCreatedIsUndisclosedNumberOfAnswersCallsCountLock = NSLock()
    private var trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingCallsCount = 0
    var trackPollCreatedIsUndisclosedNumberOfAnswersCallsCount: Int {
        get { trackPollCreatedIsUndisclosedNumberOfAnswersCallsCountLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingCallsCount } }
        set { trackPollCreatedIsUndisclosedNumberOfAnswersCallsCountLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingCallsCount = newValue } }
    }
    var trackPollCreatedIsUndisclosedNumberOfAnswersCalled: Bool {
        return trackPollCreatedIsUndisclosedNumberOfAnswersCallsCount > 0
    }
    private let trackPollCreatedIsUndisclosedNumberOfAnswersReceivedArgumentsLock = NSLock()
    private var trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedArguments: (isUndisclosed: Bool, numberOfAnswers: Int)?
    var trackPollCreatedIsUndisclosedNumberOfAnswersReceivedArguments: (isUndisclosed: Bool, numberOfAnswers: Int)? {
        get { trackPollCreatedIsUndisclosedNumberOfAnswersReceivedArgumentsLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedArguments } }
        set { trackPollCreatedIsUndisclosedNumberOfAnswersReceivedArgumentsLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedArguments = newValue } }
    }
    private let trackPollCreatedIsUndisclosedNumberOfAnswersReceivedInvocationsLock = NSLock()
    private var trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedInvocations: [(isUndisclosed: Bool, numberOfAnswers: Int)] = []
    var trackPollCreatedIsUndisclosedNumberOfAnswersReceivedInvocations: [(isUndisclosed: Bool, numberOfAnswers: Int)] {
        get { trackPollCreatedIsUndisclosedNumberOfAnswersReceivedInvocationsLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedInvocations } }
        set { trackPollCreatedIsUndisclosedNumberOfAnswersReceivedInvocationsLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedInvocations = newValue } }
    }
    var trackPollCreatedIsUndisclosedNumberOfAnswersClosure: ((Bool, Int) -> Void)?

    func trackPollCreated(isUndisclosed: Bool, numberOfAnswers: Int) {
        trackPollCreatedIsUndisclosedNumberOfAnswersCallsCountLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingCallsCount += 1 }
        trackPollCreatedIsUndisclosedNumberOfAnswersReceivedArguments = (isUndisclosed: isUndisclosed, numberOfAnswers: numberOfAnswers)
        trackPollCreatedIsUndisclosedNumberOfAnswersReceivedInvocationsLock.withLock { trackPollCreatedIsUndisclosedNumberOfAnswersUnderlyingReceivedInvocations.append((isUndisclosed: isUndisclosed, numberOfAnswers: numberOfAnswers)) }
        trackPollCreatedIsUndisclosedNumberOfAnswersClosure?(isUndisclosed, numberOfAnswers)
    }
    //MARK: - trackPollVote

    private let trackPollVoteCallsCountLock = NSLock()
    private var trackPollVoteUnderlyingCallsCount = 0
    var trackPollVoteCallsCount: Int {
        get { trackPollVoteCallsCountLock.withLock { trackPollVoteUnderlyingCallsCount } }
        set { trackPollVoteCallsCountLock.withLock { trackPollVoteUnderlyingCallsCount = newValue } }
    }
    var trackPollVoteCalled: Bool {
        return trackPollVoteCallsCount > 0
    }
    var trackPollVoteClosure: (() -> Void)?

    func trackPollVote() {
        trackPollVoteCallsCountLock.withLock { trackPollVoteUnderlyingCallsCount += 1 }
        trackPollVoteClosure?()
    }
    //MARK: - trackPollEnd

    private let trackPollEndCallsCountLock = NSLock()
    private var trackPollEndUnderlyingCallsCount = 0
    var trackPollEndCallsCount: Int {
        get { trackPollEndCallsCountLock.withLock { trackPollEndUnderlyingCallsCount } }
        set { trackPollEndCallsCountLock.withLock { trackPollEndUnderlyingCallsCount = newValue } }
    }
    var trackPollEndCalled: Bool {
        return trackPollEndCallsCount > 0
    }
    var trackPollEndClosure: (() -> Void)?

    func trackPollEnd() {
        trackPollEndCallsCountLock.withLock { trackPollEndUnderlyingCallsCount += 1 }
        trackPollEndClosure?()
    }
    //MARK: - trackRoomModeration

    private let trackRoomModerationActionRoleCallsCountLock = NSLock()
    private var trackRoomModerationActionRoleUnderlyingCallsCount = 0
    var trackRoomModerationActionRoleCallsCount: Int {
        get { trackRoomModerationActionRoleCallsCountLock.withLock { trackRoomModerationActionRoleUnderlyingCallsCount } }
        set { trackRoomModerationActionRoleCallsCountLock.withLock { trackRoomModerationActionRoleUnderlyingCallsCount = newValue } }
    }
    var trackRoomModerationActionRoleCalled: Bool {
        return trackRoomModerationActionRoleCallsCount > 0
    }
    private let trackRoomModerationActionRoleReceivedArgumentsLock = NSLock()
    private var trackRoomModerationActionRoleUnderlyingReceivedArguments: (action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?)?
    var trackRoomModerationActionRoleReceivedArguments: (action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?)? {
        get { trackRoomModerationActionRoleReceivedArgumentsLock.withLock { trackRoomModerationActionRoleUnderlyingReceivedArguments } }
        set { trackRoomModerationActionRoleReceivedArgumentsLock.withLock { trackRoomModerationActionRoleUnderlyingReceivedArguments = newValue } }
    }
    private let trackRoomModerationActionRoleReceivedInvocationsLock = NSLock()
    private var trackRoomModerationActionRoleUnderlyingReceivedInvocations: [(action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?)] = []
    var trackRoomModerationActionRoleReceivedInvocations: [(action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?)] {
        get { trackRoomModerationActionRoleReceivedInvocationsLock.withLock { trackRoomModerationActionRoleUnderlyingReceivedInvocations } }
        set { trackRoomModerationActionRoleReceivedInvocationsLock.withLock { trackRoomModerationActionRoleUnderlyingReceivedInvocations = newValue } }
    }
    var trackRoomModerationActionRoleClosure: ((AnalyticsEvent.RoomModeration.Action, RoomRole?) -> Void)?

    func trackRoomModeration(action: AnalyticsEvent.RoomModeration.Action, role: RoomRole?) {
        trackRoomModerationActionRoleCallsCountLock.withLock { trackRoomModerationActionRoleUnderlyingCallsCount += 1 }
        trackRoomModerationActionRoleReceivedArguments = (action: action, role: role)
        trackRoomModerationActionRoleReceivedInvocationsLock.withLock { trackRoomModerationActionRoleUnderlyingReceivedInvocations.append((action: action, role: role)) }
        trackRoomModerationActionRoleClosure?(action, role)
    }
    //MARK: - trackSessionSecurityState

    private let trackSessionSecurityStateCallsCountLock = NSLock()
    private var trackSessionSecurityStateUnderlyingCallsCount = 0
    var trackSessionSecurityStateCallsCount: Int {
        get { trackSessionSecurityStateCallsCountLock.withLock { trackSessionSecurityStateUnderlyingCallsCount } }
        set { trackSessionSecurityStateCallsCountLock.withLock { trackSessionSecurityStateUnderlyingCallsCount = newValue } }
    }
    var trackSessionSecurityStateCalled: Bool {
        return trackSessionSecurityStateCallsCount > 0
    }
    private let trackSessionSecurityStateReceivedStateLock = NSLock()
    private var trackSessionSecurityStateUnderlyingReceivedState: SessionSecurityState?
    var trackSessionSecurityStateReceivedState: SessionSecurityState? {
        get { trackSessionSecurityStateReceivedStateLock.withLock { trackSessionSecurityStateUnderlyingReceivedState } }
        set { trackSessionSecurityStateReceivedStateLock.withLock { trackSessionSecurityStateUnderlyingReceivedState = newValue } }
    }
    private let trackSessionSecurityStateReceivedInvocationsLock = NSLock()
    private var trackSessionSecurityStateUnderlyingReceivedInvocations: [SessionSecurityState] = []
    var trackSessionSecurityStateReceivedInvocations: [SessionSecurityState] {
        get { trackSessionSecurityStateReceivedInvocationsLock.withLock { trackSessionSecurityStateUnderlyingReceivedInvocations } }
        set { trackSessionSecurityStateReceivedInvocationsLock.withLock { trackSessionSecurityStateUnderlyingReceivedInvocations = newValue } }
    }
    var trackSessionSecurityStateClosure: ((SessionSecurityState) -> Void)?

    func trackSessionSecurityState(_ state: SessionSecurityState) {
        trackSessionSecurityStateCallsCountLock.withLock { trackSessionSecurityStateUnderlyingCallsCount += 1 }
        trackSessionSecurityStateReceivedState = state
        trackSessionSecurityStateReceivedInvocationsLock.withLock { trackSessionSecurityStateUnderlyingReceivedInvocations.append(state) }
        trackSessionSecurityStateClosure?(state)
    }
    //MARK: - updateUserProperties

    private let updateUserPropertiesCallsCountLock = NSLock()
    private var updateUserPropertiesUnderlyingCallsCount = 0
    var updateUserPropertiesCallsCount: Int {
        get { updateUserPropertiesCallsCountLock.withLock { updateUserPropertiesUnderlyingCallsCount } }
        set { updateUserPropertiesCallsCountLock.withLock { updateUserPropertiesUnderlyingCallsCount = newValue } }
    }
    var updateUserPropertiesCalled: Bool {
        return updateUserPropertiesCallsCount > 0
    }
    private let updateUserPropertiesReceivedUserPropertiesLock = NSLock()
    private var updateUserPropertiesUnderlyingReceivedUserProperties: AnalyticsEvent.UserProperties?
    var updateUserPropertiesReceivedUserProperties: AnalyticsEvent.UserProperties? {
        get { updateUserPropertiesReceivedUserPropertiesLock.withLock { updateUserPropertiesUnderlyingReceivedUserProperties } }
        set { updateUserPropertiesReceivedUserPropertiesLock.withLock { updateUserPropertiesUnderlyingReceivedUserProperties = newValue } }
    }
    private let updateUserPropertiesReceivedInvocationsLock = NSLock()
    private var updateUserPropertiesUnderlyingReceivedInvocations: [AnalyticsEvent.UserProperties] = []
    var updateUserPropertiesReceivedInvocations: [AnalyticsEvent.UserProperties] {
        get { updateUserPropertiesReceivedInvocationsLock.withLock { updateUserPropertiesUnderlyingReceivedInvocations } }
        set { updateUserPropertiesReceivedInvocationsLock.withLock { updateUserPropertiesUnderlyingReceivedInvocations = newValue } }
    }
    var updateUserPropertiesClosure: ((AnalyticsEvent.UserProperties) -> Void)?

    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        updateUserPropertiesCallsCountLock.withLock { updateUserPropertiesUnderlyingCallsCount += 1 }
        updateUserPropertiesReceivedUserProperties = userProperties
        updateUserPropertiesReceivedInvocationsLock.withLock { updateUserPropertiesUnderlyingReceivedInvocations.append(userProperties) }
        updateUserPropertiesClosure?(userProperties)
    }
    //MARK: - trackPinUnpinEvent

    private let trackPinUnpinEventCallsCountLock = NSLock()
    private var trackPinUnpinEventUnderlyingCallsCount = 0
    var trackPinUnpinEventCallsCount: Int {
        get { trackPinUnpinEventCallsCountLock.withLock { trackPinUnpinEventUnderlyingCallsCount } }
        set { trackPinUnpinEventCallsCountLock.withLock { trackPinUnpinEventUnderlyingCallsCount = newValue } }
    }
    var trackPinUnpinEventCalled: Bool {
        return trackPinUnpinEventCallsCount > 0
    }
    private let trackPinUnpinEventReceivedEventLock = NSLock()
    private var trackPinUnpinEventUnderlyingReceivedEvent: AnalyticsEvent.PinUnpinAction?
    var trackPinUnpinEventReceivedEvent: AnalyticsEvent.PinUnpinAction? {
        get { trackPinUnpinEventReceivedEventLock.withLock { trackPinUnpinEventUnderlyingReceivedEvent } }
        set { trackPinUnpinEventReceivedEventLock.withLock { trackPinUnpinEventUnderlyingReceivedEvent = newValue } }
    }
    private let trackPinUnpinEventReceivedInvocationsLock = NSLock()
    private var trackPinUnpinEventUnderlyingReceivedInvocations: [AnalyticsEvent.PinUnpinAction] = []
    var trackPinUnpinEventReceivedInvocations: [AnalyticsEvent.PinUnpinAction] {
        get { trackPinUnpinEventReceivedInvocationsLock.withLock { trackPinUnpinEventUnderlyingReceivedInvocations } }
        set { trackPinUnpinEventReceivedInvocationsLock.withLock { trackPinUnpinEventUnderlyingReceivedInvocations = newValue } }
    }
    var trackPinUnpinEventClosure: ((AnalyticsEvent.PinUnpinAction) -> Void)?

    func trackPinUnpinEvent(_ event: AnalyticsEvent.PinUnpinAction) {
        trackPinUnpinEventCallsCountLock.withLock { trackPinUnpinEventUnderlyingCallsCount += 1 }
        trackPinUnpinEventReceivedEvent = event
        trackPinUnpinEventReceivedInvocationsLock.withLock { trackPinUnpinEventUnderlyingReceivedInvocations.append(event) }
        trackPinUnpinEventClosure?(event)
    }
}
class AppLockServiceMock: AppLockServiceProtocol, @unchecked Sendable {
    var isMandatory: Bool {
        get { return underlyingIsMandatory }
        set(value) { underlyingIsMandatory = value }
    }
    var underlyingIsMandatory: Bool!
    var isEnabled: Bool {
        get { return underlyingIsEnabled }
        set(value) { underlyingIsEnabled = value }
    }
    var underlyingIsEnabled: Bool!
    var isEnabledPublisher: AnyPublisher<Bool, Never> {
        get { return underlyingIsEnabledPublisher }
        set(value) { underlyingIsEnabledPublisher = value }
    }
    var underlyingIsEnabledPublisher: AnyPublisher<Bool, Never>!
    var biometryType: LABiometryType {
        get { return underlyingBiometryType }
        set(value) { underlyingBiometryType = value }
    }
    var underlyingBiometryType: LABiometryType!
    var biometricUnlockEnabled: Bool {
        get { return underlyingBiometricUnlockEnabled }
        set(value) { underlyingBiometricUnlockEnabled = value }
    }
    var underlyingBiometricUnlockEnabled: Bool!
    var biometricUnlockTrusted: Bool {
        get { return underlyingBiometricUnlockTrusted }
        set(value) { underlyingBiometricUnlockTrusted = value }
    }
    var underlyingBiometricUnlockTrusted: Bool!
    var numberOfPINAttempts: AnyPublisher<Int, Never> {
        get { return underlyingNumberOfPINAttempts }
        set(value) { underlyingNumberOfPINAttempts = value }
    }
    var underlyingNumberOfPINAttempts: AnyPublisher<Int, Never>!

    //MARK: - setupPINCode

    private let setupPINCodeCallsCountLock = NSLock()
    private var setupPINCodeUnderlyingCallsCount = 0
    var setupPINCodeCallsCount: Int {
        get { setupPINCodeCallsCountLock.withLock { setupPINCodeUnderlyingCallsCount } }
        set { setupPINCodeCallsCountLock.withLock { setupPINCodeUnderlyingCallsCount = newValue } }
    }
    var setupPINCodeCalled: Bool {
        return setupPINCodeCallsCount > 0
    }
    private let setupPINCodeReceivedPinCodeLock = NSLock()
    private var setupPINCodeUnderlyingReceivedPinCode: String?
    var setupPINCodeReceivedPinCode: String? {
        get { setupPINCodeReceivedPinCodeLock.withLock { setupPINCodeUnderlyingReceivedPinCode } }
        set { setupPINCodeReceivedPinCodeLock.withLock { setupPINCodeUnderlyingReceivedPinCode = newValue } }
    }
    private let setupPINCodeReceivedInvocationsLock = NSLock()
    private var setupPINCodeUnderlyingReceivedInvocations: [String] = []
    var setupPINCodeReceivedInvocations: [String] {
        get { setupPINCodeReceivedInvocationsLock.withLock { setupPINCodeUnderlyingReceivedInvocations } }
        set { setupPINCodeReceivedInvocationsLock.withLock { setupPINCodeUnderlyingReceivedInvocations = newValue } }
    }

    private let setupPINCodeReturnValueLock = NSLock()
    private var setupPINCodeUnderlyingReturnValue: Result<Void, AppLockServiceError>!
    var setupPINCodeReturnValue: Result<Void, AppLockServiceError>! {
        get { setupPINCodeReturnValueLock.withLock { setupPINCodeUnderlyingReturnValue } }
        set { setupPINCodeReturnValueLock.withLock { setupPINCodeUnderlyingReturnValue = newValue } }
    }
    var setupPINCodeClosure: ((String) -> Result<Void, AppLockServiceError>)?

    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        setupPINCodeCallsCountLock.withLock { setupPINCodeUnderlyingCallsCount += 1 }
        setupPINCodeReceivedPinCode = pinCode
        setupPINCodeReceivedInvocationsLock.withLock { setupPINCodeUnderlyingReceivedInvocations.append(pinCode) }
        if let setupPINCodeClosure = setupPINCodeClosure {
            return setupPINCodeClosure(pinCode)
        } else {
            return setupPINCodeReturnValue
        }
    }
    //MARK: - validate

    private let validateCallsCountLock = NSLock()
    private var validateUnderlyingCallsCount = 0
    var validateCallsCount: Int {
        get { validateCallsCountLock.withLock { validateUnderlyingCallsCount } }
        set { validateCallsCountLock.withLock { validateUnderlyingCallsCount = newValue } }
    }
    var validateCalled: Bool {
        return validateCallsCount > 0
    }
    private let validateReceivedPinCodeLock = NSLock()
    private var validateUnderlyingReceivedPinCode: String?
    var validateReceivedPinCode: String? {
        get { validateReceivedPinCodeLock.withLock { validateUnderlyingReceivedPinCode } }
        set { validateReceivedPinCodeLock.withLock { validateUnderlyingReceivedPinCode = newValue } }
    }
    private let validateReceivedInvocationsLock = NSLock()
    private var validateUnderlyingReceivedInvocations: [String] = []
    var validateReceivedInvocations: [String] {
        get { validateReceivedInvocationsLock.withLock { validateUnderlyingReceivedInvocations } }
        set { validateReceivedInvocationsLock.withLock { validateUnderlyingReceivedInvocations = newValue } }
    }

    private let validateReturnValueLock = NSLock()
    private var validateUnderlyingReturnValue: Result<Void, AppLockServiceError>!
    var validateReturnValue: Result<Void, AppLockServiceError>! {
        get { validateReturnValueLock.withLock { validateUnderlyingReturnValue } }
        set { validateReturnValueLock.withLock { validateUnderlyingReturnValue = newValue } }
    }
    var validateClosure: ((String) -> Result<Void, AppLockServiceError>)?

    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        validateCallsCountLock.withLock { validateUnderlyingCallsCount += 1 }
        validateReceivedPinCode = pinCode
        validateReceivedInvocationsLock.withLock { validateUnderlyingReceivedInvocations.append(pinCode) }
        if let validateClosure = validateClosure {
            return validateClosure(pinCode)
        } else {
            return validateReturnValue
        }
    }
    //MARK: - enableBiometricUnlock

    private let enableBiometricUnlockCallsCountLock = NSLock()
    private var enableBiometricUnlockUnderlyingCallsCount = 0
    var enableBiometricUnlockCallsCount: Int {
        get { enableBiometricUnlockCallsCountLock.withLock { enableBiometricUnlockUnderlyingCallsCount } }
        set { enableBiometricUnlockCallsCountLock.withLock { enableBiometricUnlockUnderlyingCallsCount = newValue } }
    }
    var enableBiometricUnlockCalled: Bool {
        return enableBiometricUnlockCallsCount > 0
    }

    private let enableBiometricUnlockReturnValueLock = NSLock()
    private var enableBiometricUnlockUnderlyingReturnValue: Result<Void, AppLockServiceError>!
    var enableBiometricUnlockReturnValue: Result<Void, AppLockServiceError>! {
        get { enableBiometricUnlockReturnValueLock.withLock { enableBiometricUnlockUnderlyingReturnValue } }
        set { enableBiometricUnlockReturnValueLock.withLock { enableBiometricUnlockUnderlyingReturnValue = newValue } }
    }
    var enableBiometricUnlockClosure: (() -> Result<Void, AppLockServiceError>)?

    func enableBiometricUnlock() -> Result<Void, AppLockServiceError> {
        enableBiometricUnlockCallsCountLock.withLock { enableBiometricUnlockUnderlyingCallsCount += 1 }
        if let enableBiometricUnlockClosure = enableBiometricUnlockClosure {
            return enableBiometricUnlockClosure()
        } else {
            return enableBiometricUnlockReturnValue
        }
    }
    //MARK: - disableBiometricUnlock

    private let disableBiometricUnlockCallsCountLock = NSLock()
    private var disableBiometricUnlockUnderlyingCallsCount = 0
    var disableBiometricUnlockCallsCount: Int {
        get { disableBiometricUnlockCallsCountLock.withLock { disableBiometricUnlockUnderlyingCallsCount } }
        set { disableBiometricUnlockCallsCountLock.withLock { disableBiometricUnlockUnderlyingCallsCount = newValue } }
    }
    var disableBiometricUnlockCalled: Bool {
        return disableBiometricUnlockCallsCount > 0
    }
    var disableBiometricUnlockClosure: (() -> Void)?

    func disableBiometricUnlock() {
        disableBiometricUnlockCallsCountLock.withLock { disableBiometricUnlockUnderlyingCallsCount += 1 }
        disableBiometricUnlockClosure?()
    }
    //MARK: - disable

    private let disableCallsCountLock = NSLock()
    private var disableUnderlyingCallsCount = 0
    var disableCallsCount: Int {
        get { disableCallsCountLock.withLock { disableUnderlyingCallsCount } }
        set { disableCallsCountLock.withLock { disableUnderlyingCallsCount = newValue } }
    }
    var disableCalled: Bool {
        return disableCallsCount > 0
    }
    var disableClosure: (() -> Void)?

    func disable() {
        disableCallsCountLock.withLock { disableUnderlyingCallsCount += 1 }
        disableClosure?()
    }
    //MARK: - applicationDidEnterBackground

    private let applicationDidEnterBackgroundCallsCountLock = NSLock()
    private var applicationDidEnterBackgroundUnderlyingCallsCount = 0
    var applicationDidEnterBackgroundCallsCount: Int {
        get { applicationDidEnterBackgroundCallsCountLock.withLock { applicationDidEnterBackgroundUnderlyingCallsCount } }
        set { applicationDidEnterBackgroundCallsCountLock.withLock { applicationDidEnterBackgroundUnderlyingCallsCount = newValue } }
    }
    var applicationDidEnterBackgroundCalled: Bool {
        return applicationDidEnterBackgroundCallsCount > 0
    }
    var applicationDidEnterBackgroundClosure: (() -> Void)?

    func applicationDidEnterBackground() {
        applicationDidEnterBackgroundCallsCountLock.withLock { applicationDidEnterBackgroundUnderlyingCallsCount += 1 }
        applicationDidEnterBackgroundClosure?()
    }
    //MARK: - computeNeedsUnlock

    private let computeNeedsUnlockDidBecomeActiveAtCallsCountLock = NSLock()
    private var computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount = 0
    var computeNeedsUnlockDidBecomeActiveAtCallsCount: Int {
        get { computeNeedsUnlockDidBecomeActiveAtCallsCountLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount } }
        set { computeNeedsUnlockDidBecomeActiveAtCallsCountLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount = newValue } }
    }
    var computeNeedsUnlockDidBecomeActiveAtCalled: Bool {
        return computeNeedsUnlockDidBecomeActiveAtCallsCount > 0
    }
    private let computeNeedsUnlockDidBecomeActiveAtReceivedDateLock = NSLock()
    private var computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedDate: Date?
    var computeNeedsUnlockDidBecomeActiveAtReceivedDate: Date? {
        get { computeNeedsUnlockDidBecomeActiveAtReceivedDateLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedDate } }
        set { computeNeedsUnlockDidBecomeActiveAtReceivedDateLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedDate = newValue } }
    }
    private let computeNeedsUnlockDidBecomeActiveAtReceivedInvocationsLock = NSLock()
    private var computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedInvocations: [Date] = []
    var computeNeedsUnlockDidBecomeActiveAtReceivedInvocations: [Date] {
        get { computeNeedsUnlockDidBecomeActiveAtReceivedInvocationsLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedInvocations } }
        set { computeNeedsUnlockDidBecomeActiveAtReceivedInvocationsLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedInvocations = newValue } }
    }

    private let computeNeedsUnlockDidBecomeActiveAtReturnValueLock = NSLock()
    private var computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue: Bool!
    var computeNeedsUnlockDidBecomeActiveAtReturnValue: Bool! {
        get { computeNeedsUnlockDidBecomeActiveAtReturnValueLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue } }
        set { computeNeedsUnlockDidBecomeActiveAtReturnValueLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReturnValue = newValue } }
    }
    var computeNeedsUnlockDidBecomeActiveAtClosure: ((Date) -> Bool)?

    func computeNeedsUnlock(didBecomeActiveAt date: Date) -> Bool {
        computeNeedsUnlockDidBecomeActiveAtCallsCountLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingCallsCount += 1 }
        computeNeedsUnlockDidBecomeActiveAtReceivedDate = date
        computeNeedsUnlockDidBecomeActiveAtReceivedInvocationsLock.withLock { computeNeedsUnlockDidBecomeActiveAtUnderlyingReceivedInvocations.append(date) }
        if let computeNeedsUnlockDidBecomeActiveAtClosure = computeNeedsUnlockDidBecomeActiveAtClosure {
            return computeNeedsUnlockDidBecomeActiveAtClosure(date)
        } else {
            return computeNeedsUnlockDidBecomeActiveAtReturnValue
        }
    }
    //MARK: - unlock

    private let unlockWithCallsCountLock = NSLock()
    private var unlockWithUnderlyingCallsCount = 0
    var unlockWithCallsCount: Int {
        get { unlockWithCallsCountLock.withLock { unlockWithUnderlyingCallsCount } }
        set { unlockWithCallsCountLock.withLock { unlockWithUnderlyingCallsCount = newValue } }
    }
    var unlockWithCalled: Bool {
        return unlockWithCallsCount > 0
    }
    private let unlockWithReceivedPinCodeLock = NSLock()
    private var unlockWithUnderlyingReceivedPinCode: String?
    var unlockWithReceivedPinCode: String? {
        get { unlockWithReceivedPinCodeLock.withLock { unlockWithUnderlyingReceivedPinCode } }
        set { unlockWithReceivedPinCodeLock.withLock { unlockWithUnderlyingReceivedPinCode = newValue } }
    }
    private let unlockWithReceivedInvocationsLock = NSLock()
    private var unlockWithUnderlyingReceivedInvocations: [String] = []
    var unlockWithReceivedInvocations: [String] {
        get { unlockWithReceivedInvocationsLock.withLock { unlockWithUnderlyingReceivedInvocations } }
        set { unlockWithReceivedInvocationsLock.withLock { unlockWithUnderlyingReceivedInvocations = newValue } }
    }

    private let unlockWithReturnValueLock = NSLock()
    private var unlockWithUnderlyingReturnValue: Bool!
    var unlockWithReturnValue: Bool! {
        get { unlockWithReturnValueLock.withLock { unlockWithUnderlyingReturnValue } }
        set { unlockWithReturnValueLock.withLock { unlockWithUnderlyingReturnValue = newValue } }
    }
    var unlockWithClosure: ((String) -> Bool)?

    func unlock(with pinCode: String) -> Bool {
        unlockWithCallsCountLock.withLock { unlockWithUnderlyingCallsCount += 1 }
        unlockWithReceivedPinCode = pinCode
        unlockWithReceivedInvocationsLock.withLock { unlockWithUnderlyingReceivedInvocations.append(pinCode) }
        if let unlockWithClosure = unlockWithClosure {
            return unlockWithClosure(pinCode)
        } else {
            return unlockWithReturnValue
        }
    }
    //MARK: - unlockWithBiometrics

    private let unlockWithBiometricsCallsCountLock = NSLock()
    private var unlockWithBiometricsUnderlyingCallsCount = 0
    var unlockWithBiometricsCallsCount: Int {
        get { unlockWithBiometricsCallsCountLock.withLock { unlockWithBiometricsUnderlyingCallsCount } }
        set { unlockWithBiometricsCallsCountLock.withLock { unlockWithBiometricsUnderlyingCallsCount = newValue } }
    }
    var unlockWithBiometricsCalled: Bool {
        return unlockWithBiometricsCallsCount > 0
    }

    private let unlockWithBiometricsReturnValueLock = NSLock()
    private var unlockWithBiometricsUnderlyingReturnValue: AppLockServiceBiometricResult!
    var unlockWithBiometricsReturnValue: AppLockServiceBiometricResult! {
        get { unlockWithBiometricsReturnValueLock.withLock { unlockWithBiometricsUnderlyingReturnValue } }
        set { unlockWithBiometricsReturnValueLock.withLock { unlockWithBiometricsUnderlyingReturnValue = newValue } }
    }
    var unlockWithBiometricsClosure: (() async -> AppLockServiceBiometricResult)?

    func unlockWithBiometrics() async -> AppLockServiceBiometricResult {
        unlockWithBiometricsCallsCountLock.withLock { unlockWithBiometricsUnderlyingCallsCount += 1 }
        if let unlockWithBiometricsClosure = unlockWithBiometricsClosure {
            return await unlockWithBiometricsClosure()
        } else {
            return unlockWithBiometricsReturnValue
        }
    }
}
class AppMediatorMock: AppMediatorProtocol, @unchecked Sendable {
    var windowManager: WindowManagerProtocol {
        get { return underlyingWindowManager }
        set(value) { underlyingWindowManager = value }
    }
    var underlyingWindowManager: WindowManagerProtocol!
    var networkMonitor: NetworkMonitorProtocol {
        get { return underlyingNetworkMonitor }
        set(value) { underlyingNetworkMonitor = value }
    }
    var underlyingNetworkMonitor: NetworkMonitorProtocol!
    var appState: UIApplication.State {
        get { return underlyingAppState }
        set(value) { underlyingAppState = value }
    }
    var underlyingAppState: UIApplication.State!

    //MARK: - beginBackgroundTask

    private let beginBackgroundTaskExpirationHandlerCallsCountLock = NSLock()
    private var beginBackgroundTaskExpirationHandlerUnderlyingCallsCount = 0
    var beginBackgroundTaskExpirationHandlerCallsCount: Int {
        get { beginBackgroundTaskExpirationHandlerCallsCountLock.withLock { beginBackgroundTaskExpirationHandlerUnderlyingCallsCount } }
        set { beginBackgroundTaskExpirationHandlerCallsCountLock.withLock { beginBackgroundTaskExpirationHandlerUnderlyingCallsCount = newValue } }
    }
    var beginBackgroundTaskExpirationHandlerCalled: Bool {
        return beginBackgroundTaskExpirationHandlerCallsCount > 0
    }

    private let beginBackgroundTaskExpirationHandlerReturnValueLock = NSLock()
    private var beginBackgroundTaskExpirationHandlerUnderlyingReturnValue: UIBackgroundTaskIdentifier!
    var beginBackgroundTaskExpirationHandlerReturnValue: UIBackgroundTaskIdentifier! {
        get { beginBackgroundTaskExpirationHandlerReturnValueLock.withLock { beginBackgroundTaskExpirationHandlerUnderlyingReturnValue } }
        set { beginBackgroundTaskExpirationHandlerReturnValueLock.withLock { beginBackgroundTaskExpirationHandlerUnderlyingReturnValue = newValue } }
    }
    var beginBackgroundTaskExpirationHandlerClosure: (((() -> Void)?) -> UIBackgroundTaskIdentifier)?

    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        beginBackgroundTaskExpirationHandlerCallsCountLock.withLock { beginBackgroundTaskExpirationHandlerUnderlyingCallsCount += 1 }
        if let beginBackgroundTaskExpirationHandlerClosure = beginBackgroundTaskExpirationHandlerClosure {
            return beginBackgroundTaskExpirationHandlerClosure(handler)
        } else {
            return beginBackgroundTaskExpirationHandlerReturnValue
        }
    }
    //MARK: - endBackgroundTask

    private let endBackgroundTaskCallsCountLock = NSLock()
    private var endBackgroundTaskUnderlyingCallsCount = 0
    var endBackgroundTaskCallsCount: Int {
        get { endBackgroundTaskCallsCountLock.withLock { endBackgroundTaskUnderlyingCallsCount } }
        set { endBackgroundTaskCallsCountLock.withLock { endBackgroundTaskUnderlyingCallsCount = newValue } }
    }
    var endBackgroundTaskCalled: Bool {
        return endBackgroundTaskCallsCount > 0
    }
    private let endBackgroundTaskReceivedIdentifierLock = NSLock()
    private var endBackgroundTaskUnderlyingReceivedIdentifier: UIBackgroundTaskIdentifier?
    var endBackgroundTaskReceivedIdentifier: UIBackgroundTaskIdentifier? {
        get { endBackgroundTaskReceivedIdentifierLock.withLock { endBackgroundTaskUnderlyingReceivedIdentifier } }
        set { endBackgroundTaskReceivedIdentifierLock.withLock { endBackgroundTaskUnderlyingReceivedIdentifier = newValue } }
    }
    private let endBackgroundTaskReceivedInvocationsLock = NSLock()
    private var endBackgroundTaskUnderlyingReceivedInvocations: [UIBackgroundTaskIdentifier] = []
    var endBackgroundTaskReceivedInvocations: [UIBackgroundTaskIdentifier] {
        get { endBackgroundTaskReceivedInvocationsLock.withLock { endBackgroundTaskUnderlyingReceivedInvocations } }
        set { endBackgroundTaskReceivedInvocationsLock.withLock { endBackgroundTaskUnderlyingReceivedInvocations = newValue } }
    }
    var endBackgroundTaskClosure: ((UIBackgroundTaskIdentifier) -> Void)?

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTaskCallsCountLock.withLock { endBackgroundTaskUnderlyingCallsCount += 1 }
        endBackgroundTaskReceivedIdentifier = identifier
        endBackgroundTaskReceivedInvocationsLock.withLock { endBackgroundTaskUnderlyingReceivedInvocations.append(identifier) }
        endBackgroundTaskClosure?(identifier)
    }
    //MARK: - open

    private let openCallsCountLock = NSLock()
    private var openUnderlyingCallsCount = 0
    var openCallsCount: Int {
        get { openCallsCountLock.withLock { openUnderlyingCallsCount } }
        set { openCallsCountLock.withLock { openUnderlyingCallsCount = newValue } }
    }
    var openCalled: Bool {
        return openCallsCount > 0
    }
    private let openReceivedUrlLock = NSLock()
    private var openUnderlyingReceivedUrl: URL?
    var openReceivedUrl: URL? {
        get { openReceivedUrlLock.withLock { openUnderlyingReceivedUrl } }
        set { openReceivedUrlLock.withLock { openUnderlyingReceivedUrl = newValue } }
    }
    private let openReceivedInvocationsLock = NSLock()
    private var openUnderlyingReceivedInvocations: [URL] = []
    var openReceivedInvocations: [URL] {
        get { openReceivedInvocationsLock.withLock { openUnderlyingReceivedInvocations } }
        set { openReceivedInvocationsLock.withLock { openUnderlyingReceivedInvocations = newValue } }
    }
    var openClosure: ((URL) -> Void)?

    func open(_ url: URL) {
        openCallsCountLock.withLock { openUnderlyingCallsCount += 1 }
        openReceivedUrl = url
        openReceivedInvocationsLock.withLock { openUnderlyingReceivedInvocations.append(url) }
        openClosure?(url)
    }
    //MARK: - openAppSettings

    private let openAppSettingsCallsCountLock = NSLock()
    private var openAppSettingsUnderlyingCallsCount = 0
    var openAppSettingsCallsCount: Int {
        get { openAppSettingsCallsCountLock.withLock { openAppSettingsUnderlyingCallsCount } }
        set { openAppSettingsCallsCountLock.withLock { openAppSettingsUnderlyingCallsCount = newValue } }
    }
    var openAppSettingsCalled: Bool {
        return openAppSettingsCallsCount > 0
    }
    var openAppSettingsClosure: (() -> Void)?

    func openAppSettings() {
        openAppSettingsCallsCountLock.withLock { openAppSettingsUnderlyingCallsCount += 1 }
        openAppSettingsClosure?()
    }
    //MARK: - setIdleTimerDisabled

    private let setIdleTimerDisabledCallsCountLock = NSLock()
    private var setIdleTimerDisabledUnderlyingCallsCount = 0
    var setIdleTimerDisabledCallsCount: Int {
        get { setIdleTimerDisabledCallsCountLock.withLock { setIdleTimerDisabledUnderlyingCallsCount } }
        set { setIdleTimerDisabledCallsCountLock.withLock { setIdleTimerDisabledUnderlyingCallsCount = newValue } }
    }
    var setIdleTimerDisabledCalled: Bool {
        return setIdleTimerDisabledCallsCount > 0
    }
    private let setIdleTimerDisabledReceivedDisabledLock = NSLock()
    private var setIdleTimerDisabledUnderlyingReceivedDisabled: Bool?
    var setIdleTimerDisabledReceivedDisabled: Bool? {
        get { setIdleTimerDisabledReceivedDisabledLock.withLock { setIdleTimerDisabledUnderlyingReceivedDisabled } }
        set { setIdleTimerDisabledReceivedDisabledLock.withLock { setIdleTimerDisabledUnderlyingReceivedDisabled = newValue } }
    }
    private let setIdleTimerDisabledReceivedInvocationsLock = NSLock()
    private var setIdleTimerDisabledUnderlyingReceivedInvocations: [Bool] = []
    var setIdleTimerDisabledReceivedInvocations: [Bool] {
        get { setIdleTimerDisabledReceivedInvocationsLock.withLock { setIdleTimerDisabledUnderlyingReceivedInvocations } }
        set { setIdleTimerDisabledReceivedInvocationsLock.withLock { setIdleTimerDisabledUnderlyingReceivedInvocations = newValue } }
    }
    var setIdleTimerDisabledClosure: ((Bool) -> Void)?

    func setIdleTimerDisabled(_ disabled: Bool) {
        setIdleTimerDisabledCallsCountLock.withLock { setIdleTimerDisabledUnderlyingCallsCount += 1 }
        setIdleTimerDisabledReceivedDisabled = disabled
        setIdleTimerDisabledReceivedInvocationsLock.withLock { setIdleTimerDisabledUnderlyingReceivedInvocations.append(disabled) }
        setIdleTimerDisabledClosure?(disabled)
    }
    //MARK: - requestAuthorizationIfNeeded

    private let requestAuthorizationIfNeededCallsCountLock = NSLock()
    private var requestAuthorizationIfNeededUnderlyingCallsCount = 0
    var requestAuthorizationIfNeededCallsCount: Int {
        get { requestAuthorizationIfNeededCallsCountLock.withLock { requestAuthorizationIfNeededUnderlyingCallsCount } }
        set { requestAuthorizationIfNeededCallsCountLock.withLock { requestAuthorizationIfNeededUnderlyingCallsCount = newValue } }
    }
    var requestAuthorizationIfNeededCalled: Bool {
        return requestAuthorizationIfNeededCallsCount > 0
    }

    private let requestAuthorizationIfNeededReturnValueLock = NSLock()
    private var requestAuthorizationIfNeededUnderlyingReturnValue: Bool!
    var requestAuthorizationIfNeededReturnValue: Bool! {
        get { requestAuthorizationIfNeededReturnValueLock.withLock { requestAuthorizationIfNeededUnderlyingReturnValue } }
        set { requestAuthorizationIfNeededReturnValueLock.withLock { requestAuthorizationIfNeededUnderlyingReturnValue = newValue } }
    }
    var requestAuthorizationIfNeededClosure: (() async -> Bool)?

    func requestAuthorizationIfNeeded() async -> Bool {
        requestAuthorizationIfNeededCallsCountLock.withLock { requestAuthorizationIfNeededUnderlyingCallsCount += 1 }
        if let requestAuthorizationIfNeededClosure = requestAuthorizationIfNeededClosure {
            return await requestAuthorizationIfNeededClosure()
        } else {
            return requestAuthorizationIfNeededReturnValue
        }
    }
}
class AudioConverterMock: AudioConverterProtocol, @unchecked Sendable {

    //MARK: - convertToOpusOgg

    var convertToOpusOggSourceURLDestinationURLThrowableError: Error?
    private let convertToOpusOggSourceURLDestinationURLCallsCountLock = NSLock()
    private var convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount = 0
    var convertToOpusOggSourceURLDestinationURLCallsCount: Int {
        get { convertToOpusOggSourceURLDestinationURLCallsCountLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount } }
        set { convertToOpusOggSourceURLDestinationURLCallsCountLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount = newValue } }
    }
    var convertToOpusOggSourceURLDestinationURLCalled: Bool {
        return convertToOpusOggSourceURLDestinationURLCallsCount > 0
    }
    private let convertToOpusOggSourceURLDestinationURLReceivedArgumentsLock = NSLock()
    private var convertToOpusOggSourceURLDestinationURLUnderlyingReceivedArguments: (sourceURL: URL, destinationURL: URL)?
    var convertToOpusOggSourceURLDestinationURLReceivedArguments: (sourceURL: URL, destinationURL: URL)? {
        get { convertToOpusOggSourceURLDestinationURLReceivedArgumentsLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingReceivedArguments } }
        set { convertToOpusOggSourceURLDestinationURLReceivedArgumentsLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingReceivedArguments = newValue } }
    }
    private let convertToOpusOggSourceURLDestinationURLReceivedInvocationsLock = NSLock()
    private var convertToOpusOggSourceURLDestinationURLUnderlyingReceivedInvocations: [(sourceURL: URL, destinationURL: URL)] = []
    var convertToOpusOggSourceURLDestinationURLReceivedInvocations: [(sourceURL: URL, destinationURL: URL)] {
        get { convertToOpusOggSourceURLDestinationURLReceivedInvocationsLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingReceivedInvocations } }
        set { convertToOpusOggSourceURLDestinationURLReceivedInvocationsLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingReceivedInvocations = newValue } }
    }
    var convertToOpusOggSourceURLDestinationURLClosure: ((URL, URL) throws -> Void)?

    func convertToOpusOgg(sourceURL: URL, destinationURL: URL) throws {
        if let error = convertToOpusOggSourceURLDestinationURLThrowableError {
            throw error
        }
        convertToOpusOggSourceURLDestinationURLCallsCountLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingCallsCount += 1 }
        convertToOpusOggSourceURLDestinationURLReceivedArguments = (sourceURL: sourceURL, destinationURL: destinationURL)
        convertToOpusOggSourceURLDestinationURLReceivedInvocationsLock.withLock { convertToOpusOggSourceURLDestinationURLUnderlyingReceivedInvocations.append((sourceURL: sourceURL, destinationURL: destinationURL)) }
        try convertToOpusOggSourceURLDestinationURLClosure?(sourceURL, destinationURL)
    }
    //MARK: - convertToMPEG4AAC

    var convertToMPEG4AACSourceURLDestinationURLThrowableError: Error?
    private let convertToMPEG4AACSourceURLDestinationURLCallsCountLock = NSLock()
    private var convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount = 0
    var convertToMPEG4AACSourceURLDestinationURLCallsCount: Int {
        get { convertToMPEG4AACSourceURLDestinationURLCallsCountLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount } }
        set { convertToMPEG4AACSourceURLDestinationURLCallsCountLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount = newValue } }
    }
    var convertToMPEG4AACSourceURLDestinationURLCalled: Bool {
        return convertToMPEG4AACSourceURLDestinationURLCallsCount > 0
    }
    private let convertToMPEG4AACSourceURLDestinationURLReceivedArgumentsLock = NSLock()
    private var convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedArguments: (sourceURL: URL, destinationURL: URL)?
    var convertToMPEG4AACSourceURLDestinationURLReceivedArguments: (sourceURL: URL, destinationURL: URL)? {
        get { convertToMPEG4AACSourceURLDestinationURLReceivedArgumentsLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedArguments } }
        set { convertToMPEG4AACSourceURLDestinationURLReceivedArgumentsLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedArguments = newValue } }
    }
    private let convertToMPEG4AACSourceURLDestinationURLReceivedInvocationsLock = NSLock()
    private var convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedInvocations: [(sourceURL: URL, destinationURL: URL)] = []
    var convertToMPEG4AACSourceURLDestinationURLReceivedInvocations: [(sourceURL: URL, destinationURL: URL)] {
        get { convertToMPEG4AACSourceURLDestinationURLReceivedInvocationsLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedInvocations } }
        set { convertToMPEG4AACSourceURLDestinationURLReceivedInvocationsLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedInvocations = newValue } }
    }
    var convertToMPEG4AACSourceURLDestinationURLClosure: ((URL, URL) throws -> Void)?

    func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL) throws {
        if let error = convertToMPEG4AACSourceURLDestinationURLThrowableError {
            throw error
        }
        convertToMPEG4AACSourceURLDestinationURLCallsCountLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingCallsCount += 1 }
        convertToMPEG4AACSourceURLDestinationURLReceivedArguments = (sourceURL: sourceURL, destinationURL: destinationURL)
        convertToMPEG4AACSourceURLDestinationURLReceivedInvocationsLock.withLock { convertToMPEG4AACSourceURLDestinationURLUnderlyingReceivedInvocations.append((sourceURL: sourceURL, destinationURL: destinationURL)) }
        try convertToMPEG4AACSourceURLDestinationURLClosure?(sourceURL, destinationURL)
    }
}
class AudioPlayerMock: AudioPlayerProtocol, @unchecked Sendable {
    var sourceURL: URL?
    var duration: TimeInterval {
        get { return underlyingDuration }
        set(value) { underlyingDuration = value }
    }
    var underlyingDuration: TimeInterval!
    var currentTime: TimeInterval {
        get { return underlyingCurrentTime }
        set(value) { underlyingCurrentTime = value }
    }
    var underlyingCurrentTime: TimeInterval!
    var playbackURL: URL?
    var state: MediaPlayerState {
        get { return underlyingState }
        set(value) { underlyingState = value }
    }
    var underlyingState: MediaPlayerState!
    var playbackSpeed: Float {
        get { return underlyingPlaybackSpeed }
        set(value) { underlyingPlaybackSpeed = value }
    }
    var underlyingPlaybackSpeed: Float!
    var actions: AnyPublisher<AudioPlayerAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<AudioPlayerAction, Never>!

    //MARK: - load

    private let loadSourceURLPlaybackURLAutoplayCallsCountLock = NSLock()
    private var loadSourceURLPlaybackURLAutoplayUnderlyingCallsCount = 0
    var loadSourceURLPlaybackURLAutoplayCallsCount: Int {
        get { loadSourceURLPlaybackURLAutoplayCallsCountLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingCallsCount } }
        set { loadSourceURLPlaybackURLAutoplayCallsCountLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingCallsCount = newValue } }
    }
    var loadSourceURLPlaybackURLAutoplayCalled: Bool {
        return loadSourceURLPlaybackURLAutoplayCallsCount > 0
    }
    private let loadSourceURLPlaybackURLAutoplayReceivedArgumentsLock = NSLock()
    private var loadSourceURLPlaybackURLAutoplayUnderlyingReceivedArguments: (sourceURL: URL, playbackURL: URL, autoplay: Bool)?
    var loadSourceURLPlaybackURLAutoplayReceivedArguments: (sourceURL: URL, playbackURL: URL, autoplay: Bool)? {
        get { loadSourceURLPlaybackURLAutoplayReceivedArgumentsLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingReceivedArguments } }
        set { loadSourceURLPlaybackURLAutoplayReceivedArgumentsLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingReceivedArguments = newValue } }
    }
    private let loadSourceURLPlaybackURLAutoplayReceivedInvocationsLock = NSLock()
    private var loadSourceURLPlaybackURLAutoplayUnderlyingReceivedInvocations: [(sourceURL: URL, playbackURL: URL, autoplay: Bool)] = []
    var loadSourceURLPlaybackURLAutoplayReceivedInvocations: [(sourceURL: URL, playbackURL: URL, autoplay: Bool)] {
        get { loadSourceURLPlaybackURLAutoplayReceivedInvocationsLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingReceivedInvocations } }
        set { loadSourceURLPlaybackURLAutoplayReceivedInvocationsLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingReceivedInvocations = newValue } }
    }
    var loadSourceURLPlaybackURLAutoplayClosure: ((URL, URL, Bool) -> Void)?

    func load(sourceURL: URL, playbackURL: URL, autoplay: Bool) {
        loadSourceURLPlaybackURLAutoplayCallsCountLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingCallsCount += 1 }
        loadSourceURLPlaybackURLAutoplayReceivedArguments = (sourceURL: sourceURL, playbackURL: playbackURL, autoplay: autoplay)
        loadSourceURLPlaybackURLAutoplayReceivedInvocationsLock.withLock { loadSourceURLPlaybackURLAutoplayUnderlyingReceivedInvocations.append((sourceURL: sourceURL, playbackURL: playbackURL, autoplay: autoplay)) }
        loadSourceURLPlaybackURLAutoplayClosure?(sourceURL, playbackURL, autoplay)
    }
    //MARK: - reset

    private let resetCallsCountLock = NSLock()
    private var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get { resetCallsCountLock.withLock { resetUnderlyingCallsCount } }
        set { resetCallsCountLock.withLock { resetUnderlyingCallsCount = newValue } }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCountLock.withLock { resetUnderlyingCallsCount += 1 }
        resetClosure?()
    }
    //MARK: - play

    private let playCallsCountLock = NSLock()
    private var playUnderlyingCallsCount = 0
    var playCallsCount: Int {
        get { playCallsCountLock.withLock { playUnderlyingCallsCount } }
        set { playCallsCountLock.withLock { playUnderlyingCallsCount = newValue } }
    }
    var playCalled: Bool {
        return playCallsCount > 0
    }
    var playClosure: (() -> Void)?

    func play() {
        playCallsCountLock.withLock { playUnderlyingCallsCount += 1 }
        playClosure?()
    }
    //MARK: - pause

    private let pauseCallsCountLock = NSLock()
    private var pauseUnderlyingCallsCount = 0
    var pauseCallsCount: Int {
        get { pauseCallsCountLock.withLock { pauseUnderlyingCallsCount } }
        set { pauseCallsCountLock.withLock { pauseUnderlyingCallsCount = newValue } }
    }
    var pauseCalled: Bool {
        return pauseCallsCount > 0
    }
    var pauseClosure: (() -> Void)?

    func pause() {
        pauseCallsCountLock.withLock { pauseUnderlyingCallsCount += 1 }
        pauseClosure?()
    }
    //MARK: - stop

    private let stopCallsCountLock = NSLock()
    private var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get { stopCallsCountLock.withLock { stopUnderlyingCallsCount } }
        set { stopCallsCountLock.withLock { stopUnderlyingCallsCount = newValue } }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCountLock.withLock { stopUnderlyingCallsCount += 1 }
        stopClosure?()
    }
    //MARK: - seek

    private let seekToCallsCountLock = NSLock()
    private var seekToUnderlyingCallsCount = 0
    var seekToCallsCount: Int {
        get { seekToCallsCountLock.withLock { seekToUnderlyingCallsCount } }
        set { seekToCallsCountLock.withLock { seekToUnderlyingCallsCount = newValue } }
    }
    var seekToCalled: Bool {
        return seekToCallsCount > 0
    }
    private let seekToReceivedProgressLock = NSLock()
    private var seekToUnderlyingReceivedProgress: Double?
    var seekToReceivedProgress: Double? {
        get { seekToReceivedProgressLock.withLock { seekToUnderlyingReceivedProgress } }
        set { seekToReceivedProgressLock.withLock { seekToUnderlyingReceivedProgress = newValue } }
    }
    private let seekToReceivedInvocationsLock = NSLock()
    private var seekToUnderlyingReceivedInvocations: [Double] = []
    var seekToReceivedInvocations: [Double] {
        get { seekToReceivedInvocationsLock.withLock { seekToUnderlyingReceivedInvocations } }
        set { seekToReceivedInvocationsLock.withLock { seekToUnderlyingReceivedInvocations = newValue } }
    }
    var seekToClosure: ((Double) async -> Void)?

    func seek(to progress: Double) async {
        seekToCallsCountLock.withLock { seekToUnderlyingCallsCount += 1 }
        seekToReceivedProgress = progress
        seekToReceivedInvocationsLock.withLock { seekToUnderlyingReceivedInvocations.append(progress) }
        await seekToClosure?(progress)
    }
    //MARK: - setPlaybackSpeed

    private let setPlaybackSpeedCallsCountLock = NSLock()
    private var setPlaybackSpeedUnderlyingCallsCount = 0
    var setPlaybackSpeedCallsCount: Int {
        get { setPlaybackSpeedCallsCountLock.withLock { setPlaybackSpeedUnderlyingCallsCount } }
        set { setPlaybackSpeedCallsCountLock.withLock { setPlaybackSpeedUnderlyingCallsCount = newValue } }
    }
    var setPlaybackSpeedCalled: Bool {
        return setPlaybackSpeedCallsCount > 0
    }
    private let setPlaybackSpeedReceivedSpeedLock = NSLock()
    private var setPlaybackSpeedUnderlyingReceivedSpeed: Float?
    var setPlaybackSpeedReceivedSpeed: Float? {
        get { setPlaybackSpeedReceivedSpeedLock.withLock { setPlaybackSpeedUnderlyingReceivedSpeed } }
        set { setPlaybackSpeedReceivedSpeedLock.withLock { setPlaybackSpeedUnderlyingReceivedSpeed = newValue } }
    }
    private let setPlaybackSpeedReceivedInvocationsLock = NSLock()
    private var setPlaybackSpeedUnderlyingReceivedInvocations: [Float] = []
    var setPlaybackSpeedReceivedInvocations: [Float] {
        get { setPlaybackSpeedReceivedInvocationsLock.withLock { setPlaybackSpeedUnderlyingReceivedInvocations } }
        set { setPlaybackSpeedReceivedInvocationsLock.withLock { setPlaybackSpeedUnderlyingReceivedInvocations = newValue } }
    }
    var setPlaybackSpeedClosure: ((Float) -> Void)?

    func setPlaybackSpeed(_ speed: Float) {
        setPlaybackSpeedCallsCountLock.withLock { setPlaybackSpeedUnderlyingCallsCount += 1 }
        setPlaybackSpeedReceivedSpeed = speed
        setPlaybackSpeedReceivedInvocationsLock.withLock { setPlaybackSpeedUnderlyingReceivedInvocations.append(speed) }
        setPlaybackSpeedClosure?(speed)
    }
}
class AudioRecorderMock: AudioRecorderProtocol, @unchecked Sendable {
    var actions: AnyPublisher<AudioRecorderAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<AudioRecorderAction, Never>!
    var currentTime: TimeInterval {
        get { return underlyingCurrentTime }
        set(value) { underlyingCurrentTime = value }
    }
    var underlyingCurrentTime: TimeInterval!
    var isRecording: Bool {
        get { return underlyingIsRecording }
        set(value) { underlyingIsRecording = value }
    }
    var underlyingIsRecording: Bool!
    var audioFileURL: URL?

    //MARK: - record

    private let recordAudioFileURLCallsCountLock = NSLock()
    private var recordAudioFileURLUnderlyingCallsCount = 0
    var recordAudioFileURLCallsCount: Int {
        get { recordAudioFileURLCallsCountLock.withLock { recordAudioFileURLUnderlyingCallsCount } }
        set { recordAudioFileURLCallsCountLock.withLock { recordAudioFileURLUnderlyingCallsCount = newValue } }
    }
    var recordAudioFileURLCalled: Bool {
        return recordAudioFileURLCallsCount > 0
    }
    private let recordAudioFileURLReceivedAudioFileURLLock = NSLock()
    private var recordAudioFileURLUnderlyingReceivedAudioFileURL: URL?
    var recordAudioFileURLReceivedAudioFileURL: URL? {
        get { recordAudioFileURLReceivedAudioFileURLLock.withLock { recordAudioFileURLUnderlyingReceivedAudioFileURL } }
        set { recordAudioFileURLReceivedAudioFileURLLock.withLock { recordAudioFileURLUnderlyingReceivedAudioFileURL = newValue } }
    }
    private let recordAudioFileURLReceivedInvocationsLock = NSLock()
    private var recordAudioFileURLUnderlyingReceivedInvocations: [URL] = []
    var recordAudioFileURLReceivedInvocations: [URL] {
        get { recordAudioFileURLReceivedInvocationsLock.withLock { recordAudioFileURLUnderlyingReceivedInvocations } }
        set { recordAudioFileURLReceivedInvocationsLock.withLock { recordAudioFileURLUnderlyingReceivedInvocations = newValue } }
    }
    var recordAudioFileURLClosure: ((URL) async -> Void)?

    func record(audioFileURL: URL) async {
        recordAudioFileURLCallsCountLock.withLock { recordAudioFileURLUnderlyingCallsCount += 1 }
        recordAudioFileURLReceivedAudioFileURL = audioFileURL
        recordAudioFileURLReceivedInvocationsLock.withLock { recordAudioFileURLUnderlyingReceivedInvocations.append(audioFileURL) }
        await recordAudioFileURLClosure?(audioFileURL)
    }
    //MARK: - stopRecording

    private let stopRecordingCallsCountLock = NSLock()
    private var stopRecordingUnderlyingCallsCount = 0
    var stopRecordingCallsCount: Int {
        get { stopRecordingCallsCountLock.withLock { stopRecordingUnderlyingCallsCount } }
        set { stopRecordingCallsCountLock.withLock { stopRecordingUnderlyingCallsCount = newValue } }
    }
    var stopRecordingCalled: Bool {
        return stopRecordingCallsCount > 0
    }
    var stopRecordingClosure: (() async -> Void)?

    func stopRecording() async {
        stopRecordingCallsCountLock.withLock { stopRecordingUnderlyingCallsCount += 1 }
        await stopRecordingClosure?()
    }
    //MARK: - deleteRecording

    private let deleteRecordingCallsCountLock = NSLock()
    private var deleteRecordingUnderlyingCallsCount = 0
    var deleteRecordingCallsCount: Int {
        get { deleteRecordingCallsCountLock.withLock { deleteRecordingUnderlyingCallsCount } }
        set { deleteRecordingCallsCountLock.withLock { deleteRecordingUnderlyingCallsCount = newValue } }
    }
    var deleteRecordingCalled: Bool {
        return deleteRecordingCallsCount > 0
    }
    var deleteRecordingClosure: (() async -> Void)?

    func deleteRecording() async {
        deleteRecordingCallsCountLock.withLock { deleteRecordingUnderlyingCallsCount += 1 }
        await deleteRecordingClosure?()
    }
    //MARK: - averagePower

    private let averagePowerCallsCountLock = NSLock()
    private var averagePowerUnderlyingCallsCount = 0
    var averagePowerCallsCount: Int {
        get { averagePowerCallsCountLock.withLock { averagePowerUnderlyingCallsCount } }
        set { averagePowerCallsCountLock.withLock { averagePowerUnderlyingCallsCount = newValue } }
    }
    var averagePowerCalled: Bool {
        return averagePowerCallsCount > 0
    }

    private let averagePowerReturnValueLock = NSLock()
    private var averagePowerUnderlyingReturnValue: Float!
    var averagePowerReturnValue: Float! {
        get { averagePowerReturnValueLock.withLock { averagePowerUnderlyingReturnValue } }
        set { averagePowerReturnValueLock.withLock { averagePowerUnderlyingReturnValue = newValue } }
    }
    var averagePowerClosure: (() -> Float)?

    func averagePower() -> Float {
        averagePowerCallsCountLock.withLock { averagePowerUnderlyingCallsCount += 1 }
        if let averagePowerClosure = averagePowerClosure {
            return averagePowerClosure()
        } else {
            return averagePowerReturnValue
        }
    }
}
class AudioSessionMock: AudioSessionProtocol, @unchecked Sendable {

    //MARK: - requestRecordPermission

    private let requestRecordPermissionCallsCountLock = NSLock()
    private var requestRecordPermissionUnderlyingCallsCount = 0
    var requestRecordPermissionCallsCount: Int {
        get { requestRecordPermissionCallsCountLock.withLock { requestRecordPermissionUnderlyingCallsCount } }
        set { requestRecordPermissionCallsCountLock.withLock { requestRecordPermissionUnderlyingCallsCount = newValue } }
    }
    var requestRecordPermissionCalled: Bool {
        return requestRecordPermissionCallsCount > 0
    }
    private let requestRecordPermissionReceivedResponseLock = NSLock()
    private var requestRecordPermissionUnderlyingReceivedResponse: ((Bool) -> Void)?
    var requestRecordPermissionReceivedResponse: ((Bool) -> Void)? {
        get { requestRecordPermissionReceivedResponseLock.withLock { requestRecordPermissionUnderlyingReceivedResponse } }
        set { requestRecordPermissionReceivedResponseLock.withLock { requestRecordPermissionUnderlyingReceivedResponse = newValue } }
    }
    private let requestRecordPermissionReceivedInvocationsLock = NSLock()
    private var requestRecordPermissionUnderlyingReceivedInvocations: [((Bool) -> Void)] = []
    var requestRecordPermissionReceivedInvocations: [((Bool) -> Void)] {
        get { requestRecordPermissionReceivedInvocationsLock.withLock { requestRecordPermissionUnderlyingReceivedInvocations } }
        set { requestRecordPermissionReceivedInvocationsLock.withLock { requestRecordPermissionUnderlyingReceivedInvocations = newValue } }
    }
    var requestRecordPermissionClosure: ((@escaping (Bool) -> Void) -> Void)?

    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        requestRecordPermissionCallsCountLock.withLock { requestRecordPermissionUnderlyingCallsCount += 1 }
        requestRecordPermissionReceivedResponse = response
        requestRecordPermissionReceivedInvocationsLock.withLock { requestRecordPermissionUnderlyingReceivedInvocations.append(response) }
        requestRecordPermissionClosure?(response)
    }
    //MARK: - setAllowHapticsAndSystemSoundsDuringRecording

    var setAllowHapticsAndSystemSoundsDuringRecordingThrowableError: Error?
    private let setAllowHapticsAndSystemSoundsDuringRecordingCallsCountLock = NSLock()
    private var setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount = 0
    var setAllowHapticsAndSystemSoundsDuringRecordingCallsCount: Int {
        get { setAllowHapticsAndSystemSoundsDuringRecordingCallsCountLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount } }
        set { setAllowHapticsAndSystemSoundsDuringRecordingCallsCountLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount = newValue } }
    }
    var setAllowHapticsAndSystemSoundsDuringRecordingCalled: Bool {
        return setAllowHapticsAndSystemSoundsDuringRecordingCallsCount > 0
    }
    private let setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValueLock = NSLock()
    private var setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInValue: Bool?
    var setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValue: Bool? {
        get { setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValueLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInValue } }
        set { setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValueLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInValue = newValue } }
    }
    private let setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocationsLock = NSLock()
    private var setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInvocations: [Bool] = []
    var setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocations: [Bool] {
        get { setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocationsLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInvocations } }
        set { setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocationsLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInvocations = newValue } }
    }
    var setAllowHapticsAndSystemSoundsDuringRecordingClosure: ((Bool) throws -> Void)?

    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {
        if let error = setAllowHapticsAndSystemSoundsDuringRecordingThrowableError {
            throw error
        }
        setAllowHapticsAndSystemSoundsDuringRecordingCallsCountLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingCallsCount += 1 }
        setAllowHapticsAndSystemSoundsDuringRecordingReceivedInValue = inValue
        setAllowHapticsAndSystemSoundsDuringRecordingReceivedInvocationsLock.withLock { setAllowHapticsAndSystemSoundsDuringRecordingUnderlyingReceivedInvocations.append(inValue) }
        try setAllowHapticsAndSystemSoundsDuringRecordingClosure?(inValue)
    }
    //MARK: - setCategory

    var setCategoryModeOptionsThrowableError: Error?
    private let setCategoryModeOptionsCallsCountLock = NSLock()
    private var setCategoryModeOptionsUnderlyingCallsCount = 0
    var setCategoryModeOptionsCallsCount: Int {
        get { setCategoryModeOptionsCallsCountLock.withLock { setCategoryModeOptionsUnderlyingCallsCount } }
        set { setCategoryModeOptionsCallsCountLock.withLock { setCategoryModeOptionsUnderlyingCallsCount = newValue } }
    }
    var setCategoryModeOptionsCalled: Bool {
        return setCategoryModeOptionsCallsCount > 0
    }
    private let setCategoryModeOptionsReceivedArgumentsLock = NSLock()
    private var setCategoryModeOptionsUnderlyingReceivedArguments: (category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)?
    var setCategoryModeOptionsReceivedArguments: (category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)? {
        get { setCategoryModeOptionsReceivedArgumentsLock.withLock { setCategoryModeOptionsUnderlyingReceivedArguments } }
        set { setCategoryModeOptionsReceivedArgumentsLock.withLock { setCategoryModeOptionsUnderlyingReceivedArguments = newValue } }
    }
    private let setCategoryModeOptionsReceivedInvocationsLock = NSLock()
    private var setCategoryModeOptionsUnderlyingReceivedInvocations: [(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)] = []
    var setCategoryModeOptionsReceivedInvocations: [(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)] {
        get { setCategoryModeOptionsReceivedInvocationsLock.withLock { setCategoryModeOptionsUnderlyingReceivedInvocations } }
        set { setCategoryModeOptionsReceivedInvocationsLock.withLock { setCategoryModeOptionsUnderlyingReceivedInvocations = newValue } }
    }
    var setCategoryModeOptionsClosure: ((AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions) throws -> Void)?

    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        if let error = setCategoryModeOptionsThrowableError {
            throw error
        }
        setCategoryModeOptionsCallsCountLock.withLock { setCategoryModeOptionsUnderlyingCallsCount += 1 }
        setCategoryModeOptionsReceivedArguments = (category: category, mode: mode, options: options)
        setCategoryModeOptionsReceivedInvocationsLock.withLock { setCategoryModeOptionsUnderlyingReceivedInvocations.append((category: category, mode: mode, options: options)) }
        try setCategoryModeOptionsClosure?(category, mode, options)
    }
    //MARK: - setActive

    var setActiveOptionsThrowableError: Error?
    private let setActiveOptionsCallsCountLock = NSLock()
    private var setActiveOptionsUnderlyingCallsCount = 0
    var setActiveOptionsCallsCount: Int {
        get { setActiveOptionsCallsCountLock.withLock { setActiveOptionsUnderlyingCallsCount } }
        set { setActiveOptionsCallsCountLock.withLock { setActiveOptionsUnderlyingCallsCount = newValue } }
    }
    var setActiveOptionsCalled: Bool {
        return setActiveOptionsCallsCount > 0
    }
    private let setActiveOptionsReceivedArgumentsLock = NSLock()
    private var setActiveOptionsUnderlyingReceivedArguments: (active: Bool, options: AVAudioSession.SetActiveOptions)?
    var setActiveOptionsReceivedArguments: (active: Bool, options: AVAudioSession.SetActiveOptions)? {
        get { setActiveOptionsReceivedArgumentsLock.withLock { setActiveOptionsUnderlyingReceivedArguments } }
        set { setActiveOptionsReceivedArgumentsLock.withLock { setActiveOptionsUnderlyingReceivedArguments = newValue } }
    }
    private let setActiveOptionsReceivedInvocationsLock = NSLock()
    private var setActiveOptionsUnderlyingReceivedInvocations: [(active: Bool, options: AVAudioSession.SetActiveOptions)] = []
    var setActiveOptionsReceivedInvocations: [(active: Bool, options: AVAudioSession.SetActiveOptions)] {
        get { setActiveOptionsReceivedInvocationsLock.withLock { setActiveOptionsUnderlyingReceivedInvocations } }
        set { setActiveOptionsReceivedInvocationsLock.withLock { setActiveOptionsUnderlyingReceivedInvocations = newValue } }
    }
    var setActiveOptionsClosure: ((Bool, AVAudioSession.SetActiveOptions) throws -> Void)?

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        if let error = setActiveOptionsThrowableError {
            throw error
        }
        setActiveOptionsCallsCountLock.withLock { setActiveOptionsUnderlyingCallsCount += 1 }
        setActiveOptionsReceivedArguments = (active: active, options: options)
        setActiveOptionsReceivedInvocationsLock.withLock { setActiveOptionsUnderlyingReceivedInvocations.append((active: active, options: options)) }
        try setActiveOptionsClosure?(active, options)
    }
}
class AuthenticationClientFactoryMock: AuthenticationClientFactoryProtocol, @unchecked Sendable {

    //MARK: - makeClient

    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksThrowableError: Error?
    private let makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCountLock = NSLock()
    private var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount = 0
    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount: Int {
        get { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCountLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount } }
        set { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCountLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount = newValue } }
    }
    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCalled: Bool {
        return makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount > 0
    }
    private let makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArgumentsLock = NSLock()
    private var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedArguments: (homeserverAddress: String, sessionDirectories: SessionDirectories, passphrase: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)?
    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArguments: (homeserverAddress: String, sessionDirectories: SessionDirectories, passphrase: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)? {
        get { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArgumentsLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedArguments } }
        set { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArgumentsLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedArguments = newValue } }
    }
    private let makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock = NSLock()
    private var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations: [(homeserverAddress: String, sessionDirectories: SessionDirectories, passphrase: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)] = []
    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedInvocations: [(homeserverAddress: String, sessionDirectories: SessionDirectories, passphrase: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)] {
        get { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations } }
        set { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations = newValue } }
    }

    private let makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReturnValueLock = NSLock()
    private var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReturnValue: ClientProtocol!
    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReturnValue: ClientProtocol! {
        get { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReturnValueLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReturnValue } }
        set { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReturnValueLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReturnValue = newValue } }
    }
    var makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksClosure: ((String, SessionDirectories, String, ClientSessionDelegate, AppSettings, AppHooks) async throws -> ClientProtocol)?

    func makeClient(homeserverAddress: String, sessionDirectories: SessionDirectories, passphrase: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks) async throws -> ClientProtocol {
        if let error = makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksThrowableError {
            throw error
        }
        makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCountLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount += 1 }
        makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArguments = (homeserverAddress: homeserverAddress, sessionDirectories: sessionDirectories, passphrase: passphrase, clientSessionDelegate: clientSessionDelegate, appSettings: appSettings, appHooks: appHooks)
        makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock.withLock { makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations.append((homeserverAddress: homeserverAddress, sessionDirectories: sessionDirectories, passphrase: passphrase, clientSessionDelegate: clientSessionDelegate, appSettings: appSettings, appHooks: appHooks)) }
        if let makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksClosure = makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksClosure {
            return try await makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksClosure(homeserverAddress, sessionDirectories, passphrase, clientSessionDelegate, appSettings, appHooks)
        } else {
            return makeClientHomeserverAddressSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReturnValue
        }
    }
    //MARK: - makeInMemoryClient

    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksThrowableError: Error?
    private let makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCallsCountLock = NSLock()
    private var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount = 0
    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCallsCount: Int {
        get { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCallsCountLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount } }
        set { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCallsCountLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount = newValue } }
    }
    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCalled: Bool {
        return makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCallsCount > 0
    }
    private let makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedArgumentsLock = NSLock()
    private var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedArguments: (homeserverAddress: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)?
    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedArguments: (homeserverAddress: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)? {
        get { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedArgumentsLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedArguments } }
        set { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedArgumentsLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedArguments = newValue } }
    }
    private let makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock = NSLock()
    private var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations: [(homeserverAddress: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)] = []
    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedInvocations: [(homeserverAddress: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks)] {
        get { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations } }
        set { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations = newValue } }
    }

    private let makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReturnValueLock = NSLock()
    private var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReturnValue: ClientProtocol!
    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReturnValue: ClientProtocol! {
        get { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReturnValueLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReturnValue } }
        set { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReturnValueLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReturnValue = newValue } }
    }
    var makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksClosure: ((String, ClientSessionDelegate, AppSettings, AppHooks) async throws -> ClientProtocol)?

    func makeInMemoryClient(homeserverAddress: String, clientSessionDelegate: ClientSessionDelegate, appSettings: AppSettings, appHooks: AppHooks) async throws -> ClientProtocol {
        if let error = makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksThrowableError {
            throw error
        }
        makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksCallsCountLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingCallsCount += 1 }
        makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedArguments = (homeserverAddress: homeserverAddress, clientSessionDelegate: clientSessionDelegate, appSettings: appSettings, appHooks: appHooks)
        makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReceivedInvocationsLock.withLock { makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksUnderlyingReceivedInvocations.append((homeserverAddress: homeserverAddress, clientSessionDelegate: clientSessionDelegate, appSettings: appSettings, appHooks: appHooks)) }
        if let makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksClosure = makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksClosure {
            return try await makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksClosure(homeserverAddress, clientSessionDelegate, appSettings, appHooks)
        } else {
            return makeInMemoryClientHomeserverAddressClientSessionDelegateAppSettingsAppHooksReturnValue
        }
    }
}
class BannedRoomProxyMock: BannedRoomProxyProtocol, @unchecked Sendable {
    var info: BaseRoomInfoProxyProtocol {
        get { return underlyingInfo }
        set(value) { underlyingInfo = value }
    }
    var underlyingInfo: BaseRoomInfoProxyProtocol!
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!

    //MARK: - forgetRoom

    private let forgetRoomCallsCountLock = NSLock()
    private var forgetRoomUnderlyingCallsCount = 0
    var forgetRoomCallsCount: Int {
        get { forgetRoomCallsCountLock.withLock { forgetRoomUnderlyingCallsCount } }
        set { forgetRoomCallsCountLock.withLock { forgetRoomUnderlyingCallsCount = newValue } }
    }
    var forgetRoomCalled: Bool {
        return forgetRoomCallsCount > 0
    }

    private let forgetRoomReturnValueLock = NSLock()
    private var forgetRoomUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var forgetRoomReturnValue: Result<Void, RoomProxyError>! {
        get { forgetRoomReturnValueLock.withLock { forgetRoomUnderlyingReturnValue } }
        set { forgetRoomReturnValueLock.withLock { forgetRoomUnderlyingReturnValue = newValue } }
    }
    var forgetRoomClosure: (() async -> Result<Void, RoomProxyError>)?

    func forgetRoom() async -> Result<Void, RoomProxyError> {
        forgetRoomCallsCountLock.withLock { forgetRoomUnderlyingCallsCount += 1 }
        if let forgetRoomClosure = forgetRoomClosure {
            return await forgetRoomClosure()
        } else {
            return forgetRoomReturnValue
        }
    }
}
class BugReportServiceMock: BugReportServiceProtocol, @unchecked Sendable {
    var isEnabled: Bool {
        get { return underlyingIsEnabled }
        set(value) { underlyingIsEnabled = value }
    }
    var underlyingIsEnabled: Bool!
    var crashedLastRun: Bool {
        get { return underlyingCrashedLastRun }
        set(value) { underlyingCrashedLastRun = value }
    }
    var underlyingCrashedLastRun: Bool!
    var lastCrashEventID: String?

    //MARK: - submitBugReport

    private let submitBugReportProgressListenerCallsCountLock = NSLock()
    private var submitBugReportProgressListenerUnderlyingCallsCount = 0
    var submitBugReportProgressListenerCallsCount: Int {
        get { submitBugReportProgressListenerCallsCountLock.withLock { submitBugReportProgressListenerUnderlyingCallsCount } }
        set { submitBugReportProgressListenerCallsCountLock.withLock { submitBugReportProgressListenerUnderlyingCallsCount = newValue } }
    }
    var submitBugReportProgressListenerCalled: Bool {
        return submitBugReportProgressListenerCallsCount > 0
    }
    private let submitBugReportProgressListenerReceivedArgumentsLock = NSLock()
    private var submitBugReportProgressListenerUnderlyingReceivedArguments: (bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)?
    var submitBugReportProgressListenerReceivedArguments: (bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)? {
        get { submitBugReportProgressListenerReceivedArgumentsLock.withLock { submitBugReportProgressListenerUnderlyingReceivedArguments } }
        set { submitBugReportProgressListenerReceivedArgumentsLock.withLock { submitBugReportProgressListenerUnderlyingReceivedArguments = newValue } }
    }
    private let submitBugReportProgressListenerReceivedInvocationsLock = NSLock()
    private var submitBugReportProgressListenerUnderlyingReceivedInvocations: [(bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)] = []
    var submitBugReportProgressListenerReceivedInvocations: [(bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>)] {
        get { submitBugReportProgressListenerReceivedInvocationsLock.withLock { submitBugReportProgressListenerUnderlyingReceivedInvocations } }
        set { submitBugReportProgressListenerReceivedInvocationsLock.withLock { submitBugReportProgressListenerUnderlyingReceivedInvocations = newValue } }
    }

    private let submitBugReportProgressListenerReturnValueLock = NSLock()
    private var submitBugReportProgressListenerUnderlyingReturnValue: Result<SubmitBugReportResponse, BugReportServiceError>!
    var submitBugReportProgressListenerReturnValue: Result<SubmitBugReportResponse, BugReportServiceError>! {
        get { submitBugReportProgressListenerReturnValueLock.withLock { submitBugReportProgressListenerUnderlyingReturnValue } }
        set { submitBugReportProgressListenerReturnValueLock.withLock { submitBugReportProgressListenerUnderlyingReturnValue = newValue } }
    }
    var submitBugReportProgressListenerClosure: ((BugReport, CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError>)?

    func submitBugReport(_ bugReport: BugReport, progressListener: CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError> {
        submitBugReportProgressListenerCallsCountLock.withLock { submitBugReportProgressListenerUnderlyingCallsCount += 1 }
        submitBugReportProgressListenerReceivedArguments = (bugReport: bugReport, progressListener: progressListener)
        submitBugReportProgressListenerReceivedInvocationsLock.withLock { submitBugReportProgressListenerUnderlyingReceivedInvocations.append((bugReport: bugReport, progressListener: progressListener)) }
        if let submitBugReportProgressListenerClosure = submitBugReportProgressListenerClosure {
            return await submitBugReportProgressListenerClosure(bugReport, progressListener)
        } else {
            return submitBugReportProgressListenerReturnValue
        }
    }
}
class CLLocationManagerMock: CLLocationManagerProtocol, @unchecked Sendable {
    weak var delegate: CLLocationManagerDelegate?
    var allowsBackgroundLocationUpdates: Bool {
        get { return underlyingAllowsBackgroundLocationUpdates }
        set(value) { underlyingAllowsBackgroundLocationUpdates = value }
    }
    var underlyingAllowsBackgroundLocationUpdates: Bool!
    var showsBackgroundLocationIndicator: Bool {
        get { return underlyingShowsBackgroundLocationIndicator }
        set(value) { underlyingShowsBackgroundLocationIndicator = value }
    }
    var underlyingShowsBackgroundLocationIndicator: Bool!
    var desiredAccuracy: CLLocationAccuracy {
        get { return underlyingDesiredAccuracy }
        set(value) { underlyingDesiredAccuracy = value }
    }
    var underlyingDesiredAccuracy: CLLocationAccuracy!
    var distanceFilter: CLLocationDistance {
        get { return underlyingDistanceFilter }
        set(value) { underlyingDistanceFilter = value }
    }
    var underlyingDistanceFilter: CLLocationDistance!
    var pausesLocationUpdatesAutomatically: Bool {
        get { return underlyingPausesLocationUpdatesAutomatically }
        set(value) { underlyingPausesLocationUpdatesAutomatically = value }
    }
    var underlyingPausesLocationUpdatesAutomatically: Bool!
    var authorizationStatus: CLAuthorizationStatus {
        get { return underlyingAuthorizationStatus }
        set(value) { underlyingAuthorizationStatus = value }
    }
    var underlyingAuthorizationStatus: CLAuthorizationStatus!
    var accuracyAuthorization: CLAccuracyAuthorization {
        get { return underlyingAccuracyAuthorization }
        set(value) { underlyingAccuracyAuthorization = value }
    }
    var underlyingAccuracyAuthorization: CLAccuracyAuthorization!

    //MARK: - requestAlwaysAuthorization

    private let requestAlwaysAuthorizationCallsCountLock = NSLock()
    private var requestAlwaysAuthorizationUnderlyingCallsCount = 0
    var requestAlwaysAuthorizationCallsCount: Int {
        get { requestAlwaysAuthorizationCallsCountLock.withLock { requestAlwaysAuthorizationUnderlyingCallsCount } }
        set { requestAlwaysAuthorizationCallsCountLock.withLock { requestAlwaysAuthorizationUnderlyingCallsCount = newValue } }
    }
    var requestAlwaysAuthorizationCalled: Bool {
        return requestAlwaysAuthorizationCallsCount > 0
    }
    var requestAlwaysAuthorizationClosure: (() -> Void)?

    func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCallsCountLock.withLock { requestAlwaysAuthorizationUnderlyingCallsCount += 1 }
        requestAlwaysAuthorizationClosure?()
    }
    //MARK: - startUpdatingLocation

    private let startUpdatingLocationCallsCountLock = NSLock()
    private var startUpdatingLocationUnderlyingCallsCount = 0
    var startUpdatingLocationCallsCount: Int {
        get { startUpdatingLocationCallsCountLock.withLock { startUpdatingLocationUnderlyingCallsCount } }
        set { startUpdatingLocationCallsCountLock.withLock { startUpdatingLocationUnderlyingCallsCount = newValue } }
    }
    var startUpdatingLocationCalled: Bool {
        return startUpdatingLocationCallsCount > 0
    }
    var startUpdatingLocationClosure: (() -> Void)?

    func startUpdatingLocation() {
        startUpdatingLocationCallsCountLock.withLock { startUpdatingLocationUnderlyingCallsCount += 1 }
        startUpdatingLocationClosure?()
    }
    //MARK: - stopUpdatingLocation

    private let stopUpdatingLocationCallsCountLock = NSLock()
    private var stopUpdatingLocationUnderlyingCallsCount = 0
    var stopUpdatingLocationCallsCount: Int {
        get { stopUpdatingLocationCallsCountLock.withLock { stopUpdatingLocationUnderlyingCallsCount } }
        set { stopUpdatingLocationCallsCountLock.withLock { stopUpdatingLocationUnderlyingCallsCount = newValue } }
    }
    var stopUpdatingLocationCalled: Bool {
        return stopUpdatingLocationCallsCount > 0
    }
    var stopUpdatingLocationClosure: (() -> Void)?

    func stopUpdatingLocation() {
        stopUpdatingLocationCallsCountLock.withLock { stopUpdatingLocationUnderlyingCallsCount += 1 }
        stopUpdatingLocationClosure?()
    }
}
class CXProviderMock: CXProviderProtocol, @unchecked Sendable {

    //MARK: - setDelegate

    private let setDelegateQueueCallsCountLock = NSLock()
    private var setDelegateQueueUnderlyingCallsCount = 0
    var setDelegateQueueCallsCount: Int {
        get { setDelegateQueueCallsCountLock.withLock { setDelegateQueueUnderlyingCallsCount } }
        set { setDelegateQueueCallsCountLock.withLock { setDelegateQueueUnderlyingCallsCount = newValue } }
    }
    var setDelegateQueueCalled: Bool {
        return setDelegateQueueCallsCount > 0
    }
    private let setDelegateQueueReceivedArgumentsLock = NSLock()
    private var setDelegateQueueUnderlyingReceivedArguments: (delegate: CXProviderDelegate?, queue: DispatchQueue?)?
    var setDelegateQueueReceivedArguments: (delegate: CXProviderDelegate?, queue: DispatchQueue?)? {
        get { setDelegateQueueReceivedArgumentsLock.withLock { setDelegateQueueUnderlyingReceivedArguments } }
        set { setDelegateQueueReceivedArgumentsLock.withLock { setDelegateQueueUnderlyingReceivedArguments = newValue } }
    }
    private let setDelegateQueueReceivedInvocationsLock = NSLock()
    private var setDelegateQueueUnderlyingReceivedInvocations: [(delegate: CXProviderDelegate?, queue: DispatchQueue?)] = []
    var setDelegateQueueReceivedInvocations: [(delegate: CXProviderDelegate?, queue: DispatchQueue?)] {
        get { setDelegateQueueReceivedInvocationsLock.withLock { setDelegateQueueUnderlyingReceivedInvocations } }
        set { setDelegateQueueReceivedInvocationsLock.withLock { setDelegateQueueUnderlyingReceivedInvocations = newValue } }
    }
    var setDelegateQueueClosure: ((CXProviderDelegate?, DispatchQueue?) -> Void)?

    func setDelegate(_ delegate: CXProviderDelegate?, queue: DispatchQueue?) {
        setDelegateQueueCallsCountLock.withLock { setDelegateQueueUnderlyingCallsCount += 1 }
        setDelegateQueueReceivedArguments = (delegate: delegate, queue: queue)
        setDelegateQueueReceivedInvocationsLock.withLock { setDelegateQueueUnderlyingReceivedInvocations.append((delegate: delegate, queue: queue)) }
        setDelegateQueueClosure?(delegate, queue)
    }
    //MARK: - reportNewIncomingCall

    private let reportNewIncomingCallWithUpdateCompletionCallsCountLock = NSLock()
    private var reportNewIncomingCallWithUpdateCompletionUnderlyingCallsCount = 0
    var reportNewIncomingCallWithUpdateCompletionCallsCount: Int {
        get { reportNewIncomingCallWithUpdateCompletionCallsCountLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingCallsCount } }
        set { reportNewIncomingCallWithUpdateCompletionCallsCountLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingCallsCount = newValue } }
    }
    var reportNewIncomingCallWithUpdateCompletionCalled: Bool {
        return reportNewIncomingCallWithUpdateCompletionCallsCount > 0
    }
    private let reportNewIncomingCallWithUpdateCompletionReceivedArgumentsLock = NSLock()
    private var reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedArguments: (uuid: UUID, update: CXCallUpdate, completion: (Error?) -> Void)?
    var reportNewIncomingCallWithUpdateCompletionReceivedArguments: (uuid: UUID, update: CXCallUpdate, completion: (Error?) -> Void)? {
        get { reportNewIncomingCallWithUpdateCompletionReceivedArgumentsLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedArguments } }
        set { reportNewIncomingCallWithUpdateCompletionReceivedArgumentsLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedArguments = newValue } }
    }
    private let reportNewIncomingCallWithUpdateCompletionReceivedInvocationsLock = NSLock()
    private var reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedInvocations: [(uuid: UUID, update: CXCallUpdate, completion: (Error?) -> Void)] = []
    var reportNewIncomingCallWithUpdateCompletionReceivedInvocations: [(uuid: UUID, update: CXCallUpdate, completion: (Error?) -> Void)] {
        get { reportNewIncomingCallWithUpdateCompletionReceivedInvocationsLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedInvocations } }
        set { reportNewIncomingCallWithUpdateCompletionReceivedInvocationsLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedInvocations = newValue } }
    }
    var reportNewIncomingCallWithUpdateCompletionClosure: ((UUID, CXCallUpdate, @Sendable @escaping (Error?) -> Void) -> Void)?

    func reportNewIncomingCall(with uuid: UUID, update: CXCallUpdate, completion: @Sendable @escaping (Error?) -> Void) {
        reportNewIncomingCallWithUpdateCompletionCallsCountLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingCallsCount += 1 }
        reportNewIncomingCallWithUpdateCompletionReceivedArguments = (uuid: uuid, update: update, completion: completion)
        reportNewIncomingCallWithUpdateCompletionReceivedInvocationsLock.withLock { reportNewIncomingCallWithUpdateCompletionUnderlyingReceivedInvocations.append((uuid: uuid, update: update, completion: completion)) }
        reportNewIncomingCallWithUpdateCompletionClosure?(uuid, update, completion)
    }
    //MARK: - reportCall

    private let reportCallWithEndedAtReasonCallsCountLock = NSLock()
    private var reportCallWithEndedAtReasonUnderlyingCallsCount = 0
    var reportCallWithEndedAtReasonCallsCount: Int {
        get { reportCallWithEndedAtReasonCallsCountLock.withLock { reportCallWithEndedAtReasonUnderlyingCallsCount } }
        set { reportCallWithEndedAtReasonCallsCountLock.withLock { reportCallWithEndedAtReasonUnderlyingCallsCount = newValue } }
    }
    var reportCallWithEndedAtReasonCalled: Bool {
        return reportCallWithEndedAtReasonCallsCount > 0
    }
    private let reportCallWithEndedAtReasonReceivedArgumentsLock = NSLock()
    private var reportCallWithEndedAtReasonUnderlyingReceivedArguments: (uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)?
    var reportCallWithEndedAtReasonReceivedArguments: (uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)? {
        get { reportCallWithEndedAtReasonReceivedArgumentsLock.withLock { reportCallWithEndedAtReasonUnderlyingReceivedArguments } }
        set { reportCallWithEndedAtReasonReceivedArgumentsLock.withLock { reportCallWithEndedAtReasonUnderlyingReceivedArguments = newValue } }
    }
    private let reportCallWithEndedAtReasonReceivedInvocationsLock = NSLock()
    private var reportCallWithEndedAtReasonUnderlyingReceivedInvocations: [(uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)] = []
    var reportCallWithEndedAtReasonReceivedInvocations: [(uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)] {
        get { reportCallWithEndedAtReasonReceivedInvocationsLock.withLock { reportCallWithEndedAtReasonUnderlyingReceivedInvocations } }
        set { reportCallWithEndedAtReasonReceivedInvocationsLock.withLock { reportCallWithEndedAtReasonUnderlyingReceivedInvocations = newValue } }
    }
    var reportCallWithEndedAtReasonClosure: ((UUID, Date?, CXCallEndedReason) -> Void)?

    func reportCall(with uuid: UUID, endedAt: Date?, reason: CXCallEndedReason) {
        reportCallWithEndedAtReasonCallsCountLock.withLock { reportCallWithEndedAtReasonUnderlyingCallsCount += 1 }
        reportCallWithEndedAtReasonReceivedArguments = (uuid: uuid, endedAt: endedAt, reason: reason)
        reportCallWithEndedAtReasonReceivedInvocationsLock.withLock { reportCallWithEndedAtReasonUnderlyingReceivedInvocations.append((uuid: uuid, endedAt: endedAt, reason: reason)) }
        reportCallWithEndedAtReasonClosure?(uuid, endedAt, reason)
    }
}
class ClassicAppManagerMock: ClassicAppManagerProtocol, @unchecked Sendable {

    //MARK: - loadAccounts

    var loadAccountsThrowableError: Error?
    private let loadAccountsCallsCountLock = NSLock()
    private var loadAccountsUnderlyingCallsCount = 0
    var loadAccountsCallsCount: Int {
        get { loadAccountsCallsCountLock.withLock { loadAccountsUnderlyingCallsCount } }
        set { loadAccountsCallsCountLock.withLock { loadAccountsUnderlyingCallsCount = newValue } }
    }
    var loadAccountsCalled: Bool {
        return loadAccountsCallsCount > 0
    }

    private let loadAccountsReturnValueLock = NSLock()
    private var loadAccountsUnderlyingReturnValue: [ClassicAppAccount]!
    var loadAccountsReturnValue: [ClassicAppAccount]! {
        get { loadAccountsReturnValueLock.withLock { loadAccountsUnderlyingReturnValue } }
        set { loadAccountsReturnValueLock.withLock { loadAccountsUnderlyingReturnValue = newValue } }
    }
    var loadAccountsClosure: (() throws -> [ClassicAppAccount])?

    func loadAccounts() throws -> [ClassicAppAccount] {
        if let error = loadAccountsThrowableError {
            throw error
        }
        loadAccountsCallsCountLock.withLock { loadAccountsUnderlyingCallsCount += 1 }
        if let loadAccountsClosure = loadAccountsClosure {
            return try loadAccountsClosure()
        } else {
            return loadAccountsReturnValue
        }
    }
    //MARK: - availableSecrets

    var availableSecretsForThrowableError: Error?
    private let availableSecretsForCallsCountLock = NSLock()
    private var availableSecretsForUnderlyingCallsCount = 0
    var availableSecretsForCallsCount: Int {
        get { availableSecretsForCallsCountLock.withLock { availableSecretsForUnderlyingCallsCount } }
        set { availableSecretsForCallsCountLock.withLock { availableSecretsForUnderlyingCallsCount = newValue } }
    }
    var availableSecretsForCalled: Bool {
        return availableSecretsForCallsCount > 0
    }
    private let availableSecretsForReceivedAccountLock = NSLock()
    private var availableSecretsForUnderlyingReceivedAccount: ClassicAppAccount?
    var availableSecretsForReceivedAccount: ClassicAppAccount? {
        get { availableSecretsForReceivedAccountLock.withLock { availableSecretsForUnderlyingReceivedAccount } }
        set { availableSecretsForReceivedAccountLock.withLock { availableSecretsForUnderlyingReceivedAccount = newValue } }
    }
    private let availableSecretsForReceivedInvocationsLock = NSLock()
    private var availableSecretsForUnderlyingReceivedInvocations: [ClassicAppAccount] = []
    var availableSecretsForReceivedInvocations: [ClassicAppAccount] {
        get { availableSecretsForReceivedInvocationsLock.withLock { availableSecretsForUnderlyingReceivedInvocations } }
        set { availableSecretsForReceivedInvocationsLock.withLock { availableSecretsForUnderlyingReceivedInvocations = newValue } }
    }

    private let availableSecretsForReturnValueLock = NSLock()
    private var availableSecretsForUnderlyingReturnValue: ClassicAppAccount.AvailableSecrets!
    var availableSecretsForReturnValue: ClassicAppAccount.AvailableSecrets! {
        get { availableSecretsForReturnValueLock.withLock { availableSecretsForUnderlyingReturnValue } }
        set { availableSecretsForReturnValueLock.withLock { availableSecretsForUnderlyingReturnValue = newValue } }
    }
    var availableSecretsForClosure: ((ClassicAppAccount) async throws -> ClassicAppAccount.AvailableSecrets)?

    func availableSecrets(for account: ClassicAppAccount) async throws -> ClassicAppAccount.AvailableSecrets {
        if let error = availableSecretsForThrowableError {
            throw error
        }
        availableSecretsForCallsCountLock.withLock { availableSecretsForUnderlyingCallsCount += 1 }
        availableSecretsForReceivedAccount = account
        availableSecretsForReceivedInvocationsLock.withLock { availableSecretsForUnderlyingReceivedInvocations.append(account) }
        if let availableSecretsForClosure = availableSecretsForClosure {
            return try await availableSecretsForClosure(account)
        } else {
            return availableSecretsForReturnValue
        }
    }
    //MARK: - secretsBundle

    var secretsBundleForThrowableError: Error?
    private let secretsBundleForCallsCountLock = NSLock()
    private var secretsBundleForUnderlyingCallsCount = 0
    var secretsBundleForCallsCount: Int {
        get { secretsBundleForCallsCountLock.withLock { secretsBundleForUnderlyingCallsCount } }
        set { secretsBundleForCallsCountLock.withLock { secretsBundleForUnderlyingCallsCount = newValue } }
    }
    var secretsBundleForCalled: Bool {
        return secretsBundleForCallsCount > 0
    }
    private let secretsBundleForReceivedAccountLock = NSLock()
    private var secretsBundleForUnderlyingReceivedAccount: ClassicAppAccount?
    var secretsBundleForReceivedAccount: ClassicAppAccount? {
        get { secretsBundleForReceivedAccountLock.withLock { secretsBundleForUnderlyingReceivedAccount } }
        set { secretsBundleForReceivedAccountLock.withLock { secretsBundleForUnderlyingReceivedAccount = newValue } }
    }
    private let secretsBundleForReceivedInvocationsLock = NSLock()
    private var secretsBundleForUnderlyingReceivedInvocations: [ClassicAppAccount] = []
    var secretsBundleForReceivedInvocations: [ClassicAppAccount] {
        get { secretsBundleForReceivedInvocationsLock.withLock { secretsBundleForUnderlyingReceivedInvocations } }
        set { secretsBundleForReceivedInvocationsLock.withLock { secretsBundleForUnderlyingReceivedInvocations = newValue } }
    }

    private let secretsBundleForReturnValueLock = NSLock()
    private var secretsBundleForUnderlyingReturnValue: SecretsBundleWithUserId!
    var secretsBundleForReturnValue: SecretsBundleWithUserId! {
        get { secretsBundleForReturnValueLock.withLock { secretsBundleForUnderlyingReturnValue } }
        set { secretsBundleForReturnValueLock.withLock { secretsBundleForUnderlyingReturnValue = newValue } }
    }
    var secretsBundleForClosure: ((ClassicAppAccount) async throws -> SecretsBundleWithUserId)?

    func secretsBundle(for account: ClassicAppAccount) async throws -> SecretsBundleWithUserId {
        if let error = secretsBundleForThrowableError {
            throw error
        }
        secretsBundleForCallsCountLock.withLock { secretsBundleForUnderlyingCallsCount += 1 }
        secretsBundleForReceivedAccount = account
        secretsBundleForReceivedInvocationsLock.withLock { secretsBundleForUnderlyingReceivedInvocations.append(account) }
        if let secretsBundleForClosure = secretsBundleForClosure {
            return try await secretsBundleForClosure(account)
        } else {
            return secretsBundleForReturnValue
        }
    }
}
class ClientProxyMock: ClientProxyProtocol, @unchecked Sendable {
    var actionsPublisher: AnyPublisher<ClientProxyAction, Never> {
        get { return underlyingActionsPublisher }
        set(value) { underlyingActionsPublisher = value }
    }
    var underlyingActionsPublisher: AnyPublisher<ClientProxyAction, Never>!
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> {
        get { return underlyingLoadingStatePublisher }
        set(value) { underlyingLoadingStatePublisher = value }
    }
    var underlyingLoadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never>!
    var verificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never> {
        get { return underlyingVerificationStatePublisher }
        set(value) { underlyingVerificationStatePublisher = value }
    }
    var underlyingVerificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never>!
    var homeserverReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        get { return underlyingHomeserverReachabilityPublisher }
        set(value) { underlyingHomeserverReachabilityPublisher = value }
    }
    var underlyingHomeserverReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never>!
    var userID: String {
        get { return underlyingUserID }
        set(value) { underlyingUserID = value }
    }
    var underlyingUserID: String!
    var deviceID: String?
    var homeserver: String {
        get { return underlyingHomeserver }
        set(value) { underlyingHomeserver = value }
    }
    var underlyingHomeserver: String!
    var canDeactivateAccount: Bool {
        get { return underlyingCanDeactivateAccount }
        set(value) { underlyingCanDeactivateAccount = value }
    }
    var underlyingCanDeactivateAccount: Bool!
    var userIDServerName: String?
    var userDisplayNamePublisher: CurrentValuePublisher<String?, Never> {
        get { return underlyingUserDisplayNamePublisher }
        set(value) { underlyingUserDisplayNamePublisher = value }
    }
    var underlyingUserDisplayNamePublisher: CurrentValuePublisher<String?, Never>!
    var userAvatarURLPublisher: CurrentValuePublisher<URL?, Never> {
        get { return underlyingUserAvatarURLPublisher }
        set(value) { underlyingUserAvatarURLPublisher = value }
    }
    var underlyingUserAvatarURLPublisher: CurrentValuePublisher<URL?, Never>!
    var ignoredUsersPublisher: CurrentValuePublisher<[String]?, Never> {
        get { return underlyingIgnoredUsersPublisher }
        set(value) { underlyingIgnoredUsersPublisher = value }
    }
    var underlyingIgnoredUsersPublisher: CurrentValuePublisher<[String]?, Never>!
    var timelineMediaVisibilityPublisher: CurrentValuePublisher<TimelineMediaVisibility, Never> {
        get { return underlyingTimelineMediaVisibilityPublisher }
        set(value) { underlyingTimelineMediaVisibilityPublisher = value }
    }
    var underlyingTimelineMediaVisibilityPublisher: CurrentValuePublisher<TimelineMediaVisibility, Never>!
    var hideInviteAvatarsPublisher: CurrentValuePublisher<Bool, Never> {
        get { return underlyingHideInviteAvatarsPublisher }
        set(value) { underlyingHideInviteAvatarsPublisher = value }
    }
    var underlyingHideInviteAvatarsPublisher: CurrentValuePublisher<Bool, Never>!
    var pusherNotificationClientIdentifier: String?
    var mediaLoader: MediaLoaderProtocol {
        get { return underlyingMediaLoader }
        set(value) { underlyingMediaLoader = value }
    }
    var underlyingMediaLoader: MediaLoaderProtocol!
    var roomSummaryProvider: RoomSummaryProviderProtocol {
        get { return underlyingRoomSummaryProvider }
        set(value) { underlyingRoomSummaryProvider = value }
    }
    var underlyingRoomSummaryProvider: RoomSummaryProviderProtocol!
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol {
        get { return underlyingAlternateRoomSummaryProvider }
        set(value) { underlyingAlternateRoomSummaryProvider = value }
    }
    var underlyingAlternateRoomSummaryProvider: RoomSummaryProviderProtocol!
    var staticRoomSummaryProvider: StaticRoomSummaryProviderProtocol {
        get { return underlyingStaticRoomSummaryProvider }
        set(value) { underlyingStaticRoomSummaryProvider = value }
    }
    var underlyingStaticRoomSummaryProvider: StaticRoomSummaryProviderProtocol!
    var roomsToAwait: Set<String> {
        get { return underlyingRoomsToAwait }
        set(value) { underlyingRoomsToAwait = value }
    }
    var underlyingRoomsToAwait: Set<String>!
    var notificationSettings: NotificationSettingsProxyProtocol {
        get { return underlyingNotificationSettings }
        set(value) { underlyingNotificationSettings = value }
    }
    var underlyingNotificationSettings: NotificationSettingsProxyProtocol!
    var secureBackupController: SecureBackupControllerProtocol {
        get { return underlyingSecureBackupController }
        set(value) { underlyingSecureBackupController = value }
    }
    var underlyingSecureBackupController: SecureBackupControllerProtocol!
    var sessionVerificationController: SessionVerificationControllerProxyProtocol?
    var spaceService: SpaceServiceProxyProtocol {
        get { return underlyingSpaceService }
        set(value) { underlyingSpaceService = value }
    }
    var underlyingSpaceService: SpaceServiceProxyProtocol!
    var capabilities: HomeserverCapabilitiesProxyProtocol {
        get { return underlyingCapabilities }
        set(value) { underlyingCapabilities = value }
    }
    var underlyingCapabilities: HomeserverCapabilitiesProxyProtocol!
    var isReportRoomSupportedCallsCount = 0
    var isReportRoomSupportedCalled: Bool {
        return isReportRoomSupportedCallsCount > 0
    }

    var isReportRoomSupported: Bool {
        get async {
            isReportRoomSupportedCallsCount += 1
            if let isReportRoomSupportedClosure = isReportRoomSupportedClosure {
                return await isReportRoomSupportedClosure()
            } else {
                return underlyingIsReportRoomSupported
            }
        }
    }
    var underlyingIsReportRoomSupported: Bool!
    var isReportRoomSupportedClosure: (() async -> Bool)?
    var isLiveKitRTCSupportedCallsCount = 0
    var isLiveKitRTCSupportedCalled: Bool {
        return isLiveKitRTCSupportedCallsCount > 0
    }

    var isLiveKitRTCSupported: Bool {
        get async {
            isLiveKitRTCSupportedCallsCount += 1
            if let isLiveKitRTCSupportedClosure = isLiveKitRTCSupportedClosure {
                return await isLiveKitRTCSupportedClosure()
            } else {
                return underlyingIsLiveKitRTCSupported
            }
        }
    }
    var underlyingIsLiveKitRTCSupported: Bool!
    var isLiveKitRTCSupportedClosure: (() async -> Bool)?
    var isLoginWithQRCodeSupportedCallsCount = 0
    var isLoginWithQRCodeSupportedCalled: Bool {
        return isLoginWithQRCodeSupportedCallsCount > 0
    }

    var isLoginWithQRCodeSupported: Bool {
        get async {
            isLoginWithQRCodeSupportedCallsCount += 1
            if let isLoginWithQRCodeSupportedClosure = isLoginWithQRCodeSupportedClosure {
                return await isLoginWithQRCodeSupportedClosure()
            } else {
                return underlyingIsLoginWithQRCodeSupported
            }
        }
    }
    var underlyingIsLoginWithQRCodeSupported: Bool!
    var isLoginWithQRCodeSupportedClosure: (() async -> Bool)?
    var maxMediaUploadSizeCallsCount = 0
    var maxMediaUploadSizeCalled: Bool {
        return maxMediaUploadSizeCallsCount > 0
    }

    var maxMediaUploadSize: Result<UInt, ClientProxyError> {
        get async {
            maxMediaUploadSizeCallsCount += 1
            if let maxMediaUploadSizeClosure = maxMediaUploadSizeClosure {
                return await maxMediaUploadSizeClosure()
            } else {
                return underlyingMaxMediaUploadSize
            }
        }
    }
    var underlyingMaxMediaUploadSize: Result<UInt, ClientProxyError>!
    var maxMediaUploadSizeClosure: (() async -> Result<UInt, ClientProxyError>)?
    var liveLocationOwnInfoUpdatesPublisher: AnyPublisher<LiveLocationOwnInfoUpdate, Never> {
        get { return underlyingLiveLocationOwnInfoUpdatesPublisher }
        set(value) { underlyingLiveLocationOwnInfoUpdatesPublisher = value }
    }
    var underlyingLiveLocationOwnInfoUpdatesPublisher: AnyPublisher<LiveLocationOwnInfoUpdate, Never>!

    //MARK: - isOnlyDeviceLeft

    private let isOnlyDeviceLeftCallsCountLock = NSLock()
    private var isOnlyDeviceLeftUnderlyingCallsCount = 0
    var isOnlyDeviceLeftCallsCount: Int {
        get { isOnlyDeviceLeftCallsCountLock.withLock { isOnlyDeviceLeftUnderlyingCallsCount } }
        set { isOnlyDeviceLeftCallsCountLock.withLock { isOnlyDeviceLeftUnderlyingCallsCount = newValue } }
    }
    var isOnlyDeviceLeftCalled: Bool {
        return isOnlyDeviceLeftCallsCount > 0
    }

    private let isOnlyDeviceLeftReturnValueLock = NSLock()
    private var isOnlyDeviceLeftUnderlyingReturnValue: Result<Bool, ClientProxyError>!
    var isOnlyDeviceLeftReturnValue: Result<Bool, ClientProxyError>! {
        get { isOnlyDeviceLeftReturnValueLock.withLock { isOnlyDeviceLeftUnderlyingReturnValue } }
        set { isOnlyDeviceLeftReturnValueLock.withLock { isOnlyDeviceLeftUnderlyingReturnValue = newValue } }
    }
    var isOnlyDeviceLeftClosure: (() async -> Result<Bool, ClientProxyError>)?

    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError> {
        isOnlyDeviceLeftCallsCountLock.withLock { isOnlyDeviceLeftUnderlyingCallsCount += 1 }
        if let isOnlyDeviceLeftClosure = isOnlyDeviceLeftClosure {
            return await isOnlyDeviceLeftClosure()
        } else {
            return isOnlyDeviceLeftReturnValue
        }
    }
    //MARK: - hasDevicesToVerifyAgainst

    private let hasDevicesToVerifyAgainstCallsCountLock = NSLock()
    private var hasDevicesToVerifyAgainstUnderlyingCallsCount = 0
    var hasDevicesToVerifyAgainstCallsCount: Int {
        get { hasDevicesToVerifyAgainstCallsCountLock.withLock { hasDevicesToVerifyAgainstUnderlyingCallsCount } }
        set { hasDevicesToVerifyAgainstCallsCountLock.withLock { hasDevicesToVerifyAgainstUnderlyingCallsCount = newValue } }
    }
    var hasDevicesToVerifyAgainstCalled: Bool {
        return hasDevicesToVerifyAgainstCallsCount > 0
    }

    private let hasDevicesToVerifyAgainstReturnValueLock = NSLock()
    private var hasDevicesToVerifyAgainstUnderlyingReturnValue: Result<Bool, ClientProxyError>!
    var hasDevicesToVerifyAgainstReturnValue: Result<Bool, ClientProxyError>! {
        get { hasDevicesToVerifyAgainstReturnValueLock.withLock { hasDevicesToVerifyAgainstUnderlyingReturnValue } }
        set { hasDevicesToVerifyAgainstReturnValueLock.withLock { hasDevicesToVerifyAgainstUnderlyingReturnValue = newValue } }
    }
    var hasDevicesToVerifyAgainstClosure: (() async -> Result<Bool, ClientProxyError>)?

    func hasDevicesToVerifyAgainst() async -> Result<Bool, ClientProxyError> {
        hasDevicesToVerifyAgainstCallsCountLock.withLock { hasDevicesToVerifyAgainstUnderlyingCallsCount += 1 }
        if let hasDevicesToVerifyAgainstClosure = hasDevicesToVerifyAgainstClosure {
            return await hasDevicesToVerifyAgainstClosure()
        } else {
            return hasDevicesToVerifyAgainstReturnValue
        }
    }
    //MARK: - resumeServices

    private let resumeServicesCallsCountLock = NSLock()
    private var resumeServicesUnderlyingCallsCount = 0
    var resumeServicesCallsCount: Int {
        get { resumeServicesCallsCountLock.withLock { resumeServicesUnderlyingCallsCount } }
        set { resumeServicesCallsCountLock.withLock { resumeServicesUnderlyingCallsCount = newValue } }
    }
    var resumeServicesCalled: Bool {
        return resumeServicesCallsCount > 0
    }
    var resumeServicesClosure: (() async -> Void)?

    func resumeServices() async {
        resumeServicesCallsCountLock.withLock { resumeServicesUnderlyingCallsCount += 1 }
        await resumeServicesClosure?()
    }
    //MARK: - pauseServices

    private let pauseServicesCallsCountLock = NSLock()
    private var pauseServicesUnderlyingCallsCount = 0
    var pauseServicesCallsCount: Int {
        get { pauseServicesCallsCountLock.withLock { pauseServicesUnderlyingCallsCount } }
        set { pauseServicesCallsCountLock.withLock { pauseServicesUnderlyingCallsCount = newValue } }
    }
    var pauseServicesCalled: Bool {
        return pauseServicesCallsCount > 0
    }
    var pauseServicesClosure: (() async -> Void)?

    func pauseServices() async {
        pauseServicesCallsCountLock.withLock { pauseServicesUnderlyingCallsCount += 1 }
        await pauseServicesClosure?()
    }
    //MARK: - expireSyncSessions

    private let expireSyncSessionsCallsCountLock = NSLock()
    private var expireSyncSessionsUnderlyingCallsCount = 0
    var expireSyncSessionsCallsCount: Int {
        get { expireSyncSessionsCallsCountLock.withLock { expireSyncSessionsUnderlyingCallsCount } }
        set { expireSyncSessionsCallsCountLock.withLock { expireSyncSessionsUnderlyingCallsCount = newValue } }
    }
    var expireSyncSessionsCalled: Bool {
        return expireSyncSessionsCallsCount > 0
    }
    var expireSyncSessionsClosure: (() async -> Void)?

    func expireSyncSessions() async {
        expireSyncSessionsCallsCountLock.withLock { expireSyncSessionsUnderlyingCallsCount += 1 }
        await expireSyncSessionsClosure?()
    }
    //MARK: - accountURL

    private let accountURLActionCallsCountLock = NSLock()
    private var accountURLActionUnderlyingCallsCount = 0
    var accountURLActionCallsCount: Int {
        get { accountURLActionCallsCountLock.withLock { accountURLActionUnderlyingCallsCount } }
        set { accountURLActionCallsCountLock.withLock { accountURLActionUnderlyingCallsCount = newValue } }
    }
    var accountURLActionCalled: Bool {
        return accountURLActionCallsCount > 0
    }
    private let accountURLActionReceivedActionLock = NSLock()
    private var accountURLActionUnderlyingReceivedAction: AccountManagementAction?
    var accountURLActionReceivedAction: AccountManagementAction? {
        get { accountURLActionReceivedActionLock.withLock { accountURLActionUnderlyingReceivedAction } }
        set { accountURLActionReceivedActionLock.withLock { accountURLActionUnderlyingReceivedAction = newValue } }
    }
    private let accountURLActionReceivedInvocationsLock = NSLock()
    private var accountURLActionUnderlyingReceivedInvocations: [AccountManagementAction] = []
    var accountURLActionReceivedInvocations: [AccountManagementAction] {
        get { accountURLActionReceivedInvocationsLock.withLock { accountURLActionUnderlyingReceivedInvocations } }
        set { accountURLActionReceivedInvocationsLock.withLock { accountURLActionUnderlyingReceivedInvocations = newValue } }
    }

    private let accountURLActionReturnValueLock = NSLock()
    private var accountURLActionUnderlyingReturnValue: URL?
    var accountURLActionReturnValue: URL? {
        get { accountURLActionReturnValueLock.withLock { accountURLActionUnderlyingReturnValue } }
        set { accountURLActionReturnValueLock.withLock { accountURLActionUnderlyingReturnValue = newValue } }
    }
    var accountURLActionClosure: ((AccountManagementAction) async -> URL?)?

    func accountURL(action: AccountManagementAction) async -> URL? {
        accountURLActionCallsCountLock.withLock { accountURLActionUnderlyingCallsCount += 1 }
        accountURLActionReceivedAction = action
        accountURLActionReceivedInvocationsLock.withLock { accountURLActionUnderlyingReceivedInvocations.append(action) }
        if let accountURLActionClosure = accountURLActionClosure {
            return await accountURLActionClosure(action)
        } else {
            return accountURLActionReturnValue
        }
    }
    //MARK: - directRoomForUserID

    private let directRoomForUserIDCallsCountLock = NSLock()
    private var directRoomForUserIDUnderlyingCallsCount = 0
    var directRoomForUserIDCallsCount: Int {
        get { directRoomForUserIDCallsCountLock.withLock { directRoomForUserIDUnderlyingCallsCount } }
        set { directRoomForUserIDCallsCountLock.withLock { directRoomForUserIDUnderlyingCallsCount = newValue } }
    }
    var directRoomForUserIDCalled: Bool {
        return directRoomForUserIDCallsCount > 0
    }
    private let directRoomForUserIDReceivedUserIDLock = NSLock()
    private var directRoomForUserIDUnderlyingReceivedUserID: String?
    var directRoomForUserIDReceivedUserID: String? {
        get { directRoomForUserIDReceivedUserIDLock.withLock { directRoomForUserIDUnderlyingReceivedUserID } }
        set { directRoomForUserIDReceivedUserIDLock.withLock { directRoomForUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let directRoomForUserIDReceivedInvocationsLock = NSLock()
    private var directRoomForUserIDUnderlyingReceivedInvocations: [String] = []
    var directRoomForUserIDReceivedInvocations: [String] {
        get { directRoomForUserIDReceivedInvocationsLock.withLock { directRoomForUserIDUnderlyingReceivedInvocations } }
        set { directRoomForUserIDReceivedInvocationsLock.withLock { directRoomForUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let directRoomForUserIDReturnValueLock = NSLock()
    private var directRoomForUserIDUnderlyingReturnValue: Result<String?, ClientProxyError>!
    var directRoomForUserIDReturnValue: Result<String?, ClientProxyError>! {
        get { directRoomForUserIDReturnValueLock.withLock { directRoomForUserIDUnderlyingReturnValue } }
        set { directRoomForUserIDReturnValueLock.withLock { directRoomForUserIDUnderlyingReturnValue = newValue } }
    }
    var directRoomForUserIDClosure: ((String) -> Result<String?, ClientProxyError>)?

    func directRoomForUserID(_ userID: String) -> Result<String?, ClientProxyError> {
        directRoomForUserIDCallsCountLock.withLock { directRoomForUserIDUnderlyingCallsCount += 1 }
        directRoomForUserIDReceivedUserID = userID
        directRoomForUserIDReceivedInvocationsLock.withLock { directRoomForUserIDUnderlyingReceivedInvocations.append(userID) }
        if let directRoomForUserIDClosure = directRoomForUserIDClosure {
            return directRoomForUserIDClosure(userID)
        } else {
            return directRoomForUserIDReturnValue
        }
    }
    //MARK: - createDirectRoom

    private let createDirectRoomWithExpectedRoomNameCallsCountLock = NSLock()
    private var createDirectRoomWithExpectedRoomNameUnderlyingCallsCount = 0
    var createDirectRoomWithExpectedRoomNameCallsCount: Int {
        get { createDirectRoomWithExpectedRoomNameCallsCountLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingCallsCount } }
        set { createDirectRoomWithExpectedRoomNameCallsCountLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingCallsCount = newValue } }
    }
    var createDirectRoomWithExpectedRoomNameCalled: Bool {
        return createDirectRoomWithExpectedRoomNameCallsCount > 0
    }
    private let createDirectRoomWithExpectedRoomNameReceivedArgumentsLock = NSLock()
    private var createDirectRoomWithExpectedRoomNameUnderlyingReceivedArguments: (userID: String, expectedRoomName: String?)?
    var createDirectRoomWithExpectedRoomNameReceivedArguments: (userID: String, expectedRoomName: String?)? {
        get { createDirectRoomWithExpectedRoomNameReceivedArgumentsLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReceivedArguments } }
        set { createDirectRoomWithExpectedRoomNameReceivedArgumentsLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReceivedArguments = newValue } }
    }
    private let createDirectRoomWithExpectedRoomNameReceivedInvocationsLock = NSLock()
    private var createDirectRoomWithExpectedRoomNameUnderlyingReceivedInvocations: [(userID: String, expectedRoomName: String?)] = []
    var createDirectRoomWithExpectedRoomNameReceivedInvocations: [(userID: String, expectedRoomName: String?)] {
        get { createDirectRoomWithExpectedRoomNameReceivedInvocationsLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReceivedInvocations } }
        set { createDirectRoomWithExpectedRoomNameReceivedInvocationsLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReceivedInvocations = newValue } }
    }

    private let createDirectRoomWithExpectedRoomNameReturnValueLock = NSLock()
    private var createDirectRoomWithExpectedRoomNameUnderlyingReturnValue: Result<String, ClientProxyError>!
    var createDirectRoomWithExpectedRoomNameReturnValue: Result<String, ClientProxyError>! {
        get { createDirectRoomWithExpectedRoomNameReturnValueLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReturnValue } }
        set { createDirectRoomWithExpectedRoomNameReturnValueLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReturnValue = newValue } }
    }
    var createDirectRoomWithExpectedRoomNameClosure: ((String, String?) async -> Result<String, ClientProxyError>)?

    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError> {
        createDirectRoomWithExpectedRoomNameCallsCountLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingCallsCount += 1 }
        createDirectRoomWithExpectedRoomNameReceivedArguments = (userID: userID, expectedRoomName: expectedRoomName)
        createDirectRoomWithExpectedRoomNameReceivedInvocationsLock.withLock { createDirectRoomWithExpectedRoomNameUnderlyingReceivedInvocations.append((userID: userID, expectedRoomName: expectedRoomName)) }
        if let createDirectRoomWithExpectedRoomNameClosure = createDirectRoomWithExpectedRoomNameClosure {
            return await createDirectRoomWithExpectedRoomNameClosure(userID, expectedRoomName)
        } else {
            return createDirectRoomWithExpectedRoomNameReturnValue
        }
    }
    //MARK: - createRoom

    private let createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCallsCountLock = NSLock()
    private var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingCallsCount = 0
    var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCallsCount: Int {
        get { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCallsCountLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingCallsCount } }
        set { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCallsCountLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingCallsCount = newValue } }
    }
    var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCalled: Bool {
        return createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCallsCount > 0
    }
    private let createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArgumentsLock = NSLock()
    private var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedArguments: (name: String?, topic: String?, accessType: CreateRoomAccessType, isSpace: Bool, userIDs: [String], avatarURL: URL?, aliasLocalPart: String?)?
    var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments: (name: String?, topic: String?, accessType: CreateRoomAccessType, isSpace: Bool, userIDs: [String], avatarURL: URL?, aliasLocalPart: String?)? {
        get { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArgumentsLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedArguments } }
        set { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArgumentsLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedArguments = newValue } }
    }
    private let createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedInvocationsLock = NSLock()
    private var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedInvocations: [(name: String?, topic: String?, accessType: CreateRoomAccessType, isSpace: Bool, userIDs: [String], avatarURL: URL?, aliasLocalPart: String?)] = []
    var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedInvocations: [(name: String?, topic: String?, accessType: CreateRoomAccessType, isSpace: Bool, userIDs: [String], avatarURL: URL?, aliasLocalPart: String?)] {
        get { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedInvocationsLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedInvocations } }
        set { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedInvocationsLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedInvocations = newValue } }
    }

    private let createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValueLock = NSLock()
    private var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReturnValue: Result<String, ClientProxyError>!
    var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue: Result<String, ClientProxyError>! {
        get { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValueLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReturnValue } }
        set { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValueLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReturnValue = newValue } }
    }
    var createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartClosure: ((String?, String?, CreateRoomAccessType, Bool, [String], URL?, String?) async -> Result<String, ClientProxyError>)?

    func createRoom(name: String?, topic: String?, accessType: CreateRoomAccessType, isSpace: Bool, userIDs: [String], avatarURL: URL?, aliasLocalPart: String?) async -> Result<String, ClientProxyError> {
        createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartCallsCountLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingCallsCount += 1 }
        createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedArguments = (name: name, topic: topic, accessType: accessType, isSpace: isSpace, userIDs: userIDs, avatarURL: avatarURL, aliasLocalPart: aliasLocalPart)
        createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReceivedInvocationsLock.withLock { createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartUnderlyingReceivedInvocations.append((name: name, topic: topic, accessType: accessType, isSpace: isSpace, userIDs: userIDs, avatarURL: avatarURL, aliasLocalPart: aliasLocalPart)) }
        if let createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartClosure = createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartClosure {
            return await createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartClosure(name, topic, accessType, isSpace, userIDs, avatarURL, aliasLocalPart)
        } else {
            return createRoomNameTopicAccessTypeIsSpaceUserIDsAvatarURLAliasLocalPartReturnValue
        }
    }
    //MARK: - joinRoom

    private let joinRoomViaCallsCountLock = NSLock()
    private var joinRoomViaUnderlyingCallsCount = 0
    var joinRoomViaCallsCount: Int {
        get { joinRoomViaCallsCountLock.withLock { joinRoomViaUnderlyingCallsCount } }
        set { joinRoomViaCallsCountLock.withLock { joinRoomViaUnderlyingCallsCount = newValue } }
    }
    var joinRoomViaCalled: Bool {
        return joinRoomViaCallsCount > 0
    }
    private let joinRoomViaReceivedArgumentsLock = NSLock()
    private var joinRoomViaUnderlyingReceivedArguments: (roomID: String, via: [String])?
    var joinRoomViaReceivedArguments: (roomID: String, via: [String])? {
        get { joinRoomViaReceivedArgumentsLock.withLock { joinRoomViaUnderlyingReceivedArguments } }
        set { joinRoomViaReceivedArgumentsLock.withLock { joinRoomViaUnderlyingReceivedArguments = newValue } }
    }
    private let joinRoomViaReceivedInvocationsLock = NSLock()
    private var joinRoomViaUnderlyingReceivedInvocations: [(roomID: String, via: [String])] = []
    var joinRoomViaReceivedInvocations: [(roomID: String, via: [String])] {
        get { joinRoomViaReceivedInvocationsLock.withLock { joinRoomViaUnderlyingReceivedInvocations } }
        set { joinRoomViaReceivedInvocationsLock.withLock { joinRoomViaUnderlyingReceivedInvocations = newValue } }
    }

    private let joinRoomViaReturnValueLock = NSLock()
    private var joinRoomViaUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var joinRoomViaReturnValue: Result<Void, ClientProxyError>! {
        get { joinRoomViaReturnValueLock.withLock { joinRoomViaUnderlyingReturnValue } }
        set { joinRoomViaReturnValueLock.withLock { joinRoomViaUnderlyingReturnValue = newValue } }
    }
    var joinRoomViaClosure: ((String, [String]) async -> Result<Void, ClientProxyError>)?

    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError> {
        joinRoomViaCallsCountLock.withLock { joinRoomViaUnderlyingCallsCount += 1 }
        joinRoomViaReceivedArguments = (roomID: roomID, via: via)
        joinRoomViaReceivedInvocationsLock.withLock { joinRoomViaUnderlyingReceivedInvocations.append((roomID: roomID, via: via)) }
        if let joinRoomViaClosure = joinRoomViaClosure {
            return await joinRoomViaClosure(roomID, via)
        } else {
            return joinRoomViaReturnValue
        }
    }
    //MARK: - joinRoomAlias

    private let joinRoomAliasCallsCountLock = NSLock()
    private var joinRoomAliasUnderlyingCallsCount = 0
    var joinRoomAliasCallsCount: Int {
        get { joinRoomAliasCallsCountLock.withLock { joinRoomAliasUnderlyingCallsCount } }
        set { joinRoomAliasCallsCountLock.withLock { joinRoomAliasUnderlyingCallsCount = newValue } }
    }
    var joinRoomAliasCalled: Bool {
        return joinRoomAliasCallsCount > 0
    }
    private let joinRoomAliasReceivedRoomAliasLock = NSLock()
    private var joinRoomAliasUnderlyingReceivedRoomAlias: String?
    var joinRoomAliasReceivedRoomAlias: String? {
        get { joinRoomAliasReceivedRoomAliasLock.withLock { joinRoomAliasUnderlyingReceivedRoomAlias } }
        set { joinRoomAliasReceivedRoomAliasLock.withLock { joinRoomAliasUnderlyingReceivedRoomAlias = newValue } }
    }
    private let joinRoomAliasReceivedInvocationsLock = NSLock()
    private var joinRoomAliasUnderlyingReceivedInvocations: [String] = []
    var joinRoomAliasReceivedInvocations: [String] {
        get { joinRoomAliasReceivedInvocationsLock.withLock { joinRoomAliasUnderlyingReceivedInvocations } }
        set { joinRoomAliasReceivedInvocationsLock.withLock { joinRoomAliasUnderlyingReceivedInvocations = newValue } }
    }

    private let joinRoomAliasReturnValueLock = NSLock()
    private var joinRoomAliasUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var joinRoomAliasReturnValue: Result<Void, ClientProxyError>! {
        get { joinRoomAliasReturnValueLock.withLock { joinRoomAliasUnderlyingReturnValue } }
        set { joinRoomAliasReturnValueLock.withLock { joinRoomAliasUnderlyingReturnValue = newValue } }
    }
    var joinRoomAliasClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError> {
        joinRoomAliasCallsCountLock.withLock { joinRoomAliasUnderlyingCallsCount += 1 }
        joinRoomAliasReceivedRoomAlias = roomAlias
        joinRoomAliasReceivedInvocationsLock.withLock { joinRoomAliasUnderlyingReceivedInvocations.append(roomAlias) }
        if let joinRoomAliasClosure = joinRoomAliasClosure {
            return await joinRoomAliasClosure(roomAlias)
        } else {
            return joinRoomAliasReturnValue
        }
    }
    //MARK: - knockRoom

    private let knockRoomViaMessageCallsCountLock = NSLock()
    private var knockRoomViaMessageUnderlyingCallsCount = 0
    var knockRoomViaMessageCallsCount: Int {
        get { knockRoomViaMessageCallsCountLock.withLock { knockRoomViaMessageUnderlyingCallsCount } }
        set { knockRoomViaMessageCallsCountLock.withLock { knockRoomViaMessageUnderlyingCallsCount = newValue } }
    }
    var knockRoomViaMessageCalled: Bool {
        return knockRoomViaMessageCallsCount > 0
    }
    private let knockRoomViaMessageReceivedArgumentsLock = NSLock()
    private var knockRoomViaMessageUnderlyingReceivedArguments: (roomID: String, via: [String], message: String?)?
    var knockRoomViaMessageReceivedArguments: (roomID: String, via: [String], message: String?)? {
        get { knockRoomViaMessageReceivedArgumentsLock.withLock { knockRoomViaMessageUnderlyingReceivedArguments } }
        set { knockRoomViaMessageReceivedArgumentsLock.withLock { knockRoomViaMessageUnderlyingReceivedArguments = newValue } }
    }
    private let knockRoomViaMessageReceivedInvocationsLock = NSLock()
    private var knockRoomViaMessageUnderlyingReceivedInvocations: [(roomID: String, via: [String], message: String?)] = []
    var knockRoomViaMessageReceivedInvocations: [(roomID: String, via: [String], message: String?)] {
        get { knockRoomViaMessageReceivedInvocationsLock.withLock { knockRoomViaMessageUnderlyingReceivedInvocations } }
        set { knockRoomViaMessageReceivedInvocationsLock.withLock { knockRoomViaMessageUnderlyingReceivedInvocations = newValue } }
    }

    private let knockRoomViaMessageReturnValueLock = NSLock()
    private var knockRoomViaMessageUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var knockRoomViaMessageReturnValue: Result<Void, ClientProxyError>! {
        get { knockRoomViaMessageReturnValueLock.withLock { knockRoomViaMessageUnderlyingReturnValue } }
        set { knockRoomViaMessageReturnValueLock.withLock { knockRoomViaMessageUnderlyingReturnValue = newValue } }
    }
    var knockRoomViaMessageClosure: ((String, [String], String?) async -> Result<Void, ClientProxyError>)?

    func knockRoom(_ roomID: String, via: [String], message: String?) async -> Result<Void, ClientProxyError> {
        knockRoomViaMessageCallsCountLock.withLock { knockRoomViaMessageUnderlyingCallsCount += 1 }
        knockRoomViaMessageReceivedArguments = (roomID: roomID, via: via, message: message)
        knockRoomViaMessageReceivedInvocationsLock.withLock { knockRoomViaMessageUnderlyingReceivedInvocations.append((roomID: roomID, via: via, message: message)) }
        if let knockRoomViaMessageClosure = knockRoomViaMessageClosure {
            return await knockRoomViaMessageClosure(roomID, via, message)
        } else {
            return knockRoomViaMessageReturnValue
        }
    }
    //MARK: - knockRoomAlias

    private let knockRoomAliasMessageCallsCountLock = NSLock()
    private var knockRoomAliasMessageUnderlyingCallsCount = 0
    var knockRoomAliasMessageCallsCount: Int {
        get { knockRoomAliasMessageCallsCountLock.withLock { knockRoomAliasMessageUnderlyingCallsCount } }
        set { knockRoomAliasMessageCallsCountLock.withLock { knockRoomAliasMessageUnderlyingCallsCount = newValue } }
    }
    var knockRoomAliasMessageCalled: Bool {
        return knockRoomAliasMessageCallsCount > 0
    }
    private let knockRoomAliasMessageReceivedArgumentsLock = NSLock()
    private var knockRoomAliasMessageUnderlyingReceivedArguments: (roomAlias: String, message: String?)?
    var knockRoomAliasMessageReceivedArguments: (roomAlias: String, message: String?)? {
        get { knockRoomAliasMessageReceivedArgumentsLock.withLock { knockRoomAliasMessageUnderlyingReceivedArguments } }
        set { knockRoomAliasMessageReceivedArgumentsLock.withLock { knockRoomAliasMessageUnderlyingReceivedArguments = newValue } }
    }
    private let knockRoomAliasMessageReceivedInvocationsLock = NSLock()
    private var knockRoomAliasMessageUnderlyingReceivedInvocations: [(roomAlias: String, message: String?)] = []
    var knockRoomAliasMessageReceivedInvocations: [(roomAlias: String, message: String?)] {
        get { knockRoomAliasMessageReceivedInvocationsLock.withLock { knockRoomAliasMessageUnderlyingReceivedInvocations } }
        set { knockRoomAliasMessageReceivedInvocationsLock.withLock { knockRoomAliasMessageUnderlyingReceivedInvocations = newValue } }
    }

    private let knockRoomAliasMessageReturnValueLock = NSLock()
    private var knockRoomAliasMessageUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var knockRoomAliasMessageReturnValue: Result<Void, ClientProxyError>! {
        get { knockRoomAliasMessageReturnValueLock.withLock { knockRoomAliasMessageUnderlyingReturnValue } }
        set { knockRoomAliasMessageReturnValueLock.withLock { knockRoomAliasMessageUnderlyingReturnValue = newValue } }
    }
    var knockRoomAliasMessageClosure: ((String, String?) async -> Result<Void, ClientProxyError>)?

    func knockRoomAlias(_ roomAlias: String, message: String?) async -> Result<Void, ClientProxyError> {
        knockRoomAliasMessageCallsCountLock.withLock { knockRoomAliasMessageUnderlyingCallsCount += 1 }
        knockRoomAliasMessageReceivedArguments = (roomAlias: roomAlias, message: message)
        knockRoomAliasMessageReceivedInvocationsLock.withLock { knockRoomAliasMessageUnderlyingReceivedInvocations.append((roomAlias: roomAlias, message: message)) }
        if let knockRoomAliasMessageClosure = knockRoomAliasMessageClosure {
            return await knockRoomAliasMessageClosure(roomAlias, message)
        } else {
            return knockRoomAliasMessageReturnValue
        }
    }
    //MARK: - canJoinRoom

    private let canJoinRoomWithCallsCountLock = NSLock()
    private var canJoinRoomWithUnderlyingCallsCount = 0
    var canJoinRoomWithCallsCount: Int {
        get { canJoinRoomWithCallsCountLock.withLock { canJoinRoomWithUnderlyingCallsCount } }
        set { canJoinRoomWithCallsCountLock.withLock { canJoinRoomWithUnderlyingCallsCount = newValue } }
    }
    var canJoinRoomWithCalled: Bool {
        return canJoinRoomWithCallsCount > 0
    }
    private let canJoinRoomWithReceivedRulesLock = NSLock()
    private var canJoinRoomWithUnderlyingReceivedRules: [AllowRule]?
    var canJoinRoomWithReceivedRules: [AllowRule]? {
        get { canJoinRoomWithReceivedRulesLock.withLock { canJoinRoomWithUnderlyingReceivedRules } }
        set { canJoinRoomWithReceivedRulesLock.withLock { canJoinRoomWithUnderlyingReceivedRules = newValue } }
    }
    private let canJoinRoomWithReceivedInvocationsLock = NSLock()
    private var canJoinRoomWithUnderlyingReceivedInvocations: [[AllowRule]] = []
    var canJoinRoomWithReceivedInvocations: [[AllowRule]] {
        get { canJoinRoomWithReceivedInvocationsLock.withLock { canJoinRoomWithUnderlyingReceivedInvocations } }
        set { canJoinRoomWithReceivedInvocationsLock.withLock { canJoinRoomWithUnderlyingReceivedInvocations = newValue } }
    }

    private let canJoinRoomWithReturnValueLock = NSLock()
    private var canJoinRoomWithUnderlyingReturnValue: Bool!
    var canJoinRoomWithReturnValue: Bool! {
        get { canJoinRoomWithReturnValueLock.withLock { canJoinRoomWithUnderlyingReturnValue } }
        set { canJoinRoomWithReturnValueLock.withLock { canJoinRoomWithUnderlyingReturnValue = newValue } }
    }
    var canJoinRoomWithClosure: (([AllowRule]) -> Bool)?

    func canJoinRoom(with rules: [AllowRule]) -> Bool {
        canJoinRoomWithCallsCountLock.withLock { canJoinRoomWithUnderlyingCallsCount += 1 }
        canJoinRoomWithReceivedRules = rules
        canJoinRoomWithReceivedInvocationsLock.withLock { canJoinRoomWithUnderlyingReceivedInvocations.append(rules) }
        if let canJoinRoomWithClosure = canJoinRoomWithClosure {
            return canJoinRoomWithClosure(rules)
        } else {
            return canJoinRoomWithReturnValue
        }
    }
    //MARK: - uploadMedia

    private let uploadMediaCallsCountLock = NSLock()
    private var uploadMediaUnderlyingCallsCount = 0
    var uploadMediaCallsCount: Int {
        get { uploadMediaCallsCountLock.withLock { uploadMediaUnderlyingCallsCount } }
        set { uploadMediaCallsCountLock.withLock { uploadMediaUnderlyingCallsCount = newValue } }
    }
    var uploadMediaCalled: Bool {
        return uploadMediaCallsCount > 0
    }
    private let uploadMediaReceivedMediaLock = NSLock()
    private var uploadMediaUnderlyingReceivedMedia: MediaInfo?
    var uploadMediaReceivedMedia: MediaInfo? {
        get { uploadMediaReceivedMediaLock.withLock { uploadMediaUnderlyingReceivedMedia } }
        set { uploadMediaReceivedMediaLock.withLock { uploadMediaUnderlyingReceivedMedia = newValue } }
    }
    private let uploadMediaReceivedInvocationsLock = NSLock()
    private var uploadMediaUnderlyingReceivedInvocations: [MediaInfo] = []
    var uploadMediaReceivedInvocations: [MediaInfo] {
        get { uploadMediaReceivedInvocationsLock.withLock { uploadMediaUnderlyingReceivedInvocations } }
        set { uploadMediaReceivedInvocationsLock.withLock { uploadMediaUnderlyingReceivedInvocations = newValue } }
    }

    private let uploadMediaReturnValueLock = NSLock()
    private var uploadMediaUnderlyingReturnValue: Result<String, ClientProxyError>!
    var uploadMediaReturnValue: Result<String, ClientProxyError>! {
        get { uploadMediaReturnValueLock.withLock { uploadMediaUnderlyingReturnValue } }
        set { uploadMediaReturnValueLock.withLock { uploadMediaUnderlyingReturnValue = newValue } }
    }
    var uploadMediaClosure: ((MediaInfo) async -> Result<String, ClientProxyError>)?

    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        uploadMediaCallsCountLock.withLock { uploadMediaUnderlyingCallsCount += 1 }
        uploadMediaReceivedMedia = media
        uploadMediaReceivedInvocationsLock.withLock { uploadMediaUnderlyingReceivedInvocations.append(media) }
        if let uploadMediaClosure = uploadMediaClosure {
            return await uploadMediaClosure(media)
        } else {
            return uploadMediaReturnValue
        }
    }
    //MARK: - roomForIdentifier

    private let roomForIdentifierCallsCountLock = NSLock()
    private var roomForIdentifierUnderlyingCallsCount = 0
    var roomForIdentifierCallsCount: Int {
        get { roomForIdentifierCallsCountLock.withLock { roomForIdentifierUnderlyingCallsCount } }
        set { roomForIdentifierCallsCountLock.withLock { roomForIdentifierUnderlyingCallsCount = newValue } }
    }
    var roomForIdentifierCalled: Bool {
        return roomForIdentifierCallsCount > 0
    }
    private let roomForIdentifierReceivedIdentifierLock = NSLock()
    private var roomForIdentifierUnderlyingReceivedIdentifier: String?
    var roomForIdentifierReceivedIdentifier: String? {
        get { roomForIdentifierReceivedIdentifierLock.withLock { roomForIdentifierUnderlyingReceivedIdentifier } }
        set { roomForIdentifierReceivedIdentifierLock.withLock { roomForIdentifierUnderlyingReceivedIdentifier = newValue } }
    }
    private let roomForIdentifierReceivedInvocationsLock = NSLock()
    private var roomForIdentifierUnderlyingReceivedInvocations: [String] = []
    var roomForIdentifierReceivedInvocations: [String] {
        get { roomForIdentifierReceivedInvocationsLock.withLock { roomForIdentifierUnderlyingReceivedInvocations } }
        set { roomForIdentifierReceivedInvocationsLock.withLock { roomForIdentifierUnderlyingReceivedInvocations = newValue } }
    }

    private let roomForIdentifierReturnValueLock = NSLock()
    private var roomForIdentifierUnderlyingReturnValue: RoomProxyType?
    var roomForIdentifierReturnValue: RoomProxyType? {
        get { roomForIdentifierReturnValueLock.withLock { roomForIdentifierUnderlyingReturnValue } }
        set { roomForIdentifierReturnValueLock.withLock { roomForIdentifierUnderlyingReturnValue = newValue } }
    }
    var roomForIdentifierClosure: ((String) async -> RoomProxyType?)?

    func roomForIdentifier(_ identifier: String) async -> RoomProxyType? {
        roomForIdentifierCallsCountLock.withLock { roomForIdentifierUnderlyingCallsCount += 1 }
        roomForIdentifierReceivedIdentifier = identifier
        roomForIdentifierReceivedInvocationsLock.withLock { roomForIdentifierUnderlyingReceivedInvocations.append(identifier) }
        if let roomForIdentifierClosure = roomForIdentifierClosure {
            return await roomForIdentifierClosure(identifier)
        } else {
            return roomForIdentifierReturnValue
        }
    }
    //MARK: - roomPreviewForIdentifier

    private let roomPreviewForIdentifierViaCallsCountLock = NSLock()
    private var roomPreviewForIdentifierViaUnderlyingCallsCount = 0
    var roomPreviewForIdentifierViaCallsCount: Int {
        get { roomPreviewForIdentifierViaCallsCountLock.withLock { roomPreviewForIdentifierViaUnderlyingCallsCount } }
        set { roomPreviewForIdentifierViaCallsCountLock.withLock { roomPreviewForIdentifierViaUnderlyingCallsCount = newValue } }
    }
    var roomPreviewForIdentifierViaCalled: Bool {
        return roomPreviewForIdentifierViaCallsCount > 0
    }
    private let roomPreviewForIdentifierViaReceivedArgumentsLock = NSLock()
    private var roomPreviewForIdentifierViaUnderlyingReceivedArguments: (identifier: String, via: [String])?
    var roomPreviewForIdentifierViaReceivedArguments: (identifier: String, via: [String])? {
        get { roomPreviewForIdentifierViaReceivedArgumentsLock.withLock { roomPreviewForIdentifierViaUnderlyingReceivedArguments } }
        set { roomPreviewForIdentifierViaReceivedArgumentsLock.withLock { roomPreviewForIdentifierViaUnderlyingReceivedArguments = newValue } }
    }
    private let roomPreviewForIdentifierViaReceivedInvocationsLock = NSLock()
    private var roomPreviewForIdentifierViaUnderlyingReceivedInvocations: [(identifier: String, via: [String])] = []
    var roomPreviewForIdentifierViaReceivedInvocations: [(identifier: String, via: [String])] {
        get { roomPreviewForIdentifierViaReceivedInvocationsLock.withLock { roomPreviewForIdentifierViaUnderlyingReceivedInvocations } }
        set { roomPreviewForIdentifierViaReceivedInvocationsLock.withLock { roomPreviewForIdentifierViaUnderlyingReceivedInvocations = newValue } }
    }

    private let roomPreviewForIdentifierViaReturnValueLock = NSLock()
    private var roomPreviewForIdentifierViaUnderlyingReturnValue: Result<RoomPreviewProxyProtocol, ClientProxyError>!
    var roomPreviewForIdentifierViaReturnValue: Result<RoomPreviewProxyProtocol, ClientProxyError>! {
        get { roomPreviewForIdentifierViaReturnValueLock.withLock { roomPreviewForIdentifierViaUnderlyingReturnValue } }
        set { roomPreviewForIdentifierViaReturnValueLock.withLock { roomPreviewForIdentifierViaUnderlyingReturnValue = newValue } }
    }
    var roomPreviewForIdentifierViaClosure: ((String, [String]) async -> Result<RoomPreviewProxyProtocol, ClientProxyError>)?

    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewProxyProtocol, ClientProxyError> {
        roomPreviewForIdentifierViaCallsCountLock.withLock { roomPreviewForIdentifierViaUnderlyingCallsCount += 1 }
        roomPreviewForIdentifierViaReceivedArguments = (identifier: identifier, via: via)
        roomPreviewForIdentifierViaReceivedInvocationsLock.withLock { roomPreviewForIdentifierViaUnderlyingReceivedInvocations.append((identifier: identifier, via: via)) }
        if let roomPreviewForIdentifierViaClosure = roomPreviewForIdentifierViaClosure {
            return await roomPreviewForIdentifierViaClosure(identifier, via)
        } else {
            return roomPreviewForIdentifierViaReturnValue
        }
    }
    //MARK: - roomSummaryForIdentifier

    private let roomSummaryForIdentifierCallsCountLock = NSLock()
    private var roomSummaryForIdentifierUnderlyingCallsCount = 0
    var roomSummaryForIdentifierCallsCount: Int {
        get { roomSummaryForIdentifierCallsCountLock.withLock { roomSummaryForIdentifierUnderlyingCallsCount } }
        set { roomSummaryForIdentifierCallsCountLock.withLock { roomSummaryForIdentifierUnderlyingCallsCount = newValue } }
    }
    var roomSummaryForIdentifierCalled: Bool {
        return roomSummaryForIdentifierCallsCount > 0
    }
    private let roomSummaryForIdentifierReceivedIdentifierLock = NSLock()
    private var roomSummaryForIdentifierUnderlyingReceivedIdentifier: String?
    var roomSummaryForIdentifierReceivedIdentifier: String? {
        get { roomSummaryForIdentifierReceivedIdentifierLock.withLock { roomSummaryForIdentifierUnderlyingReceivedIdentifier } }
        set { roomSummaryForIdentifierReceivedIdentifierLock.withLock { roomSummaryForIdentifierUnderlyingReceivedIdentifier = newValue } }
    }
    private let roomSummaryForIdentifierReceivedInvocationsLock = NSLock()
    private var roomSummaryForIdentifierUnderlyingReceivedInvocations: [String] = []
    var roomSummaryForIdentifierReceivedInvocations: [String] {
        get { roomSummaryForIdentifierReceivedInvocationsLock.withLock { roomSummaryForIdentifierUnderlyingReceivedInvocations } }
        set { roomSummaryForIdentifierReceivedInvocationsLock.withLock { roomSummaryForIdentifierUnderlyingReceivedInvocations = newValue } }
    }

    private let roomSummaryForIdentifierReturnValueLock = NSLock()
    private var roomSummaryForIdentifierUnderlyingReturnValue: RoomSummary?
    var roomSummaryForIdentifierReturnValue: RoomSummary? {
        get { roomSummaryForIdentifierReturnValueLock.withLock { roomSummaryForIdentifierUnderlyingReturnValue } }
        set { roomSummaryForIdentifierReturnValueLock.withLock { roomSummaryForIdentifierUnderlyingReturnValue = newValue } }
    }
    var roomSummaryForIdentifierClosure: ((String) -> RoomSummary?)?

    func roomSummaryForIdentifier(_ identifier: String) -> RoomSummary? {
        roomSummaryForIdentifierCallsCountLock.withLock { roomSummaryForIdentifierUnderlyingCallsCount += 1 }
        roomSummaryForIdentifierReceivedIdentifier = identifier
        roomSummaryForIdentifierReceivedInvocationsLock.withLock { roomSummaryForIdentifierUnderlyingReceivedInvocations.append(identifier) }
        if let roomSummaryForIdentifierClosure = roomSummaryForIdentifierClosure {
            return roomSummaryForIdentifierClosure(identifier)
        } else {
            return roomSummaryForIdentifierReturnValue
        }
    }
    //MARK: - roomSummaryForAlias

    private let roomSummaryForAliasCallsCountLock = NSLock()
    private var roomSummaryForAliasUnderlyingCallsCount = 0
    var roomSummaryForAliasCallsCount: Int {
        get { roomSummaryForAliasCallsCountLock.withLock { roomSummaryForAliasUnderlyingCallsCount } }
        set { roomSummaryForAliasCallsCountLock.withLock { roomSummaryForAliasUnderlyingCallsCount = newValue } }
    }
    var roomSummaryForAliasCalled: Bool {
        return roomSummaryForAliasCallsCount > 0
    }
    private let roomSummaryForAliasReceivedAliasLock = NSLock()
    private var roomSummaryForAliasUnderlyingReceivedAlias: String?
    var roomSummaryForAliasReceivedAlias: String? {
        get { roomSummaryForAliasReceivedAliasLock.withLock { roomSummaryForAliasUnderlyingReceivedAlias } }
        set { roomSummaryForAliasReceivedAliasLock.withLock { roomSummaryForAliasUnderlyingReceivedAlias = newValue } }
    }
    private let roomSummaryForAliasReceivedInvocationsLock = NSLock()
    private var roomSummaryForAliasUnderlyingReceivedInvocations: [String] = []
    var roomSummaryForAliasReceivedInvocations: [String] {
        get { roomSummaryForAliasReceivedInvocationsLock.withLock { roomSummaryForAliasUnderlyingReceivedInvocations } }
        set { roomSummaryForAliasReceivedInvocationsLock.withLock { roomSummaryForAliasUnderlyingReceivedInvocations = newValue } }
    }

    private let roomSummaryForAliasReturnValueLock = NSLock()
    private var roomSummaryForAliasUnderlyingReturnValue: RoomSummary?
    var roomSummaryForAliasReturnValue: RoomSummary? {
        get { roomSummaryForAliasReturnValueLock.withLock { roomSummaryForAliasUnderlyingReturnValue } }
        set { roomSummaryForAliasReturnValueLock.withLock { roomSummaryForAliasUnderlyingReturnValue = newValue } }
    }
    var roomSummaryForAliasClosure: ((String) -> RoomSummary?)?

    func roomSummaryForAlias(_ alias: String) -> RoomSummary? {
        roomSummaryForAliasCallsCountLock.withLock { roomSummaryForAliasUnderlyingCallsCount += 1 }
        roomSummaryForAliasReceivedAlias = alias
        roomSummaryForAliasReceivedInvocationsLock.withLock { roomSummaryForAliasUnderlyingReceivedInvocations.append(alias) }
        if let roomSummaryForAliasClosure = roomSummaryForAliasClosure {
            return roomSummaryForAliasClosure(alias)
        } else {
            return roomSummaryForAliasReturnValue
        }
    }
    //MARK: - reportRoomForIdentifier

    private let reportRoomForIdentifierReasonCallsCountLock = NSLock()
    private var reportRoomForIdentifierReasonUnderlyingCallsCount = 0
    var reportRoomForIdentifierReasonCallsCount: Int {
        get { reportRoomForIdentifierReasonCallsCountLock.withLock { reportRoomForIdentifierReasonUnderlyingCallsCount } }
        set { reportRoomForIdentifierReasonCallsCountLock.withLock { reportRoomForIdentifierReasonUnderlyingCallsCount = newValue } }
    }
    var reportRoomForIdentifierReasonCalled: Bool {
        return reportRoomForIdentifierReasonCallsCount > 0
    }
    private let reportRoomForIdentifierReasonReceivedArgumentsLock = NSLock()
    private var reportRoomForIdentifierReasonUnderlyingReceivedArguments: (identifier: String, reason: String)?
    var reportRoomForIdentifierReasonReceivedArguments: (identifier: String, reason: String)? {
        get { reportRoomForIdentifierReasonReceivedArgumentsLock.withLock { reportRoomForIdentifierReasonUnderlyingReceivedArguments } }
        set { reportRoomForIdentifierReasonReceivedArgumentsLock.withLock { reportRoomForIdentifierReasonUnderlyingReceivedArguments = newValue } }
    }
    private let reportRoomForIdentifierReasonReceivedInvocationsLock = NSLock()
    private var reportRoomForIdentifierReasonUnderlyingReceivedInvocations: [(identifier: String, reason: String)] = []
    var reportRoomForIdentifierReasonReceivedInvocations: [(identifier: String, reason: String)] {
        get { reportRoomForIdentifierReasonReceivedInvocationsLock.withLock { reportRoomForIdentifierReasonUnderlyingReceivedInvocations } }
        set { reportRoomForIdentifierReasonReceivedInvocationsLock.withLock { reportRoomForIdentifierReasonUnderlyingReceivedInvocations = newValue } }
    }

    private let reportRoomForIdentifierReasonReturnValueLock = NSLock()
    private var reportRoomForIdentifierReasonUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var reportRoomForIdentifierReasonReturnValue: Result<Void, ClientProxyError>! {
        get { reportRoomForIdentifierReasonReturnValueLock.withLock { reportRoomForIdentifierReasonUnderlyingReturnValue } }
        set { reportRoomForIdentifierReasonReturnValueLock.withLock { reportRoomForIdentifierReasonUnderlyingReturnValue = newValue } }
    }
    var reportRoomForIdentifierReasonClosure: ((String, String) async -> Result<Void, ClientProxyError>)?

    func reportRoomForIdentifier(_ identifier: String, reason: String) async -> Result<Void, ClientProxyError> {
        reportRoomForIdentifierReasonCallsCountLock.withLock { reportRoomForIdentifierReasonUnderlyingCallsCount += 1 }
        reportRoomForIdentifierReasonReceivedArguments = (identifier: identifier, reason: reason)
        reportRoomForIdentifierReasonReceivedInvocationsLock.withLock { reportRoomForIdentifierReasonUnderlyingReceivedInvocations.append((identifier: identifier, reason: reason)) }
        if let reportRoomForIdentifierReasonClosure = reportRoomForIdentifierReasonClosure {
            return await reportRoomForIdentifierReasonClosure(identifier, reason)
        } else {
            return reportRoomForIdentifierReasonReturnValue
        }
    }
    //MARK: - loadUserDisplayName

    private let loadUserDisplayNameCallsCountLock = NSLock()
    private var loadUserDisplayNameUnderlyingCallsCount = 0
    var loadUserDisplayNameCallsCount: Int {
        get { loadUserDisplayNameCallsCountLock.withLock { loadUserDisplayNameUnderlyingCallsCount } }
        set { loadUserDisplayNameCallsCountLock.withLock { loadUserDisplayNameUnderlyingCallsCount = newValue } }
    }
    var loadUserDisplayNameCalled: Bool {
        return loadUserDisplayNameCallsCount > 0
    }

    private let loadUserDisplayNameReturnValueLock = NSLock()
    private var loadUserDisplayNameUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var loadUserDisplayNameReturnValue: Result<Void, ClientProxyError>! {
        get { loadUserDisplayNameReturnValueLock.withLock { loadUserDisplayNameUnderlyingReturnValue } }
        set { loadUserDisplayNameReturnValueLock.withLock { loadUserDisplayNameUnderlyingReturnValue = newValue } }
    }
    var loadUserDisplayNameClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        loadUserDisplayNameCallsCountLock.withLock { loadUserDisplayNameUnderlyingCallsCount += 1 }
        if let loadUserDisplayNameClosure = loadUserDisplayNameClosure {
            return await loadUserDisplayNameClosure()
        } else {
            return loadUserDisplayNameReturnValue
        }
    }
    //MARK: - setUserDisplayName

    private let setUserDisplayNameCallsCountLock = NSLock()
    private var setUserDisplayNameUnderlyingCallsCount = 0
    var setUserDisplayNameCallsCount: Int {
        get { setUserDisplayNameCallsCountLock.withLock { setUserDisplayNameUnderlyingCallsCount } }
        set { setUserDisplayNameCallsCountLock.withLock { setUserDisplayNameUnderlyingCallsCount = newValue } }
    }
    var setUserDisplayNameCalled: Bool {
        return setUserDisplayNameCallsCount > 0
    }
    private let setUserDisplayNameReceivedNameLock = NSLock()
    private var setUserDisplayNameUnderlyingReceivedName: String?
    var setUserDisplayNameReceivedName: String? {
        get { setUserDisplayNameReceivedNameLock.withLock { setUserDisplayNameUnderlyingReceivedName } }
        set { setUserDisplayNameReceivedNameLock.withLock { setUserDisplayNameUnderlyingReceivedName = newValue } }
    }
    private let setUserDisplayNameReceivedInvocationsLock = NSLock()
    private var setUserDisplayNameUnderlyingReceivedInvocations: [String] = []
    var setUserDisplayNameReceivedInvocations: [String] {
        get { setUserDisplayNameReceivedInvocationsLock.withLock { setUserDisplayNameUnderlyingReceivedInvocations } }
        set { setUserDisplayNameReceivedInvocationsLock.withLock { setUserDisplayNameUnderlyingReceivedInvocations = newValue } }
    }

    private let setUserDisplayNameReturnValueLock = NSLock()
    private var setUserDisplayNameUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var setUserDisplayNameReturnValue: Result<Void, ClientProxyError>! {
        get { setUserDisplayNameReturnValueLock.withLock { setUserDisplayNameUnderlyingReturnValue } }
        set { setUserDisplayNameReturnValueLock.withLock { setUserDisplayNameUnderlyingReturnValue = newValue } }
    }
    var setUserDisplayNameClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError> {
        setUserDisplayNameCallsCountLock.withLock { setUserDisplayNameUnderlyingCallsCount += 1 }
        setUserDisplayNameReceivedName = name
        setUserDisplayNameReceivedInvocationsLock.withLock { setUserDisplayNameUnderlyingReceivedInvocations.append(name) }
        if let setUserDisplayNameClosure = setUserDisplayNameClosure {
            return await setUserDisplayNameClosure(name)
        } else {
            return setUserDisplayNameReturnValue
        }
    }
    //MARK: - loadUserAvatarURL

    private let loadUserAvatarURLCallsCountLock = NSLock()
    private var loadUserAvatarURLUnderlyingCallsCount = 0
    var loadUserAvatarURLCallsCount: Int {
        get { loadUserAvatarURLCallsCountLock.withLock { loadUserAvatarURLUnderlyingCallsCount } }
        set { loadUserAvatarURLCallsCountLock.withLock { loadUserAvatarURLUnderlyingCallsCount = newValue } }
    }
    var loadUserAvatarURLCalled: Bool {
        return loadUserAvatarURLCallsCount > 0
    }

    private let loadUserAvatarURLReturnValueLock = NSLock()
    private var loadUserAvatarURLUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var loadUserAvatarURLReturnValue: Result<Void, ClientProxyError>! {
        get { loadUserAvatarURLReturnValueLock.withLock { loadUserAvatarURLUnderlyingReturnValue } }
        set { loadUserAvatarURLReturnValueLock.withLock { loadUserAvatarURLUnderlyingReturnValue = newValue } }
    }
    var loadUserAvatarURLClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func loadUserAvatarURL() async -> Result<Void, ClientProxyError> {
        loadUserAvatarURLCallsCountLock.withLock { loadUserAvatarURLUnderlyingCallsCount += 1 }
        if let loadUserAvatarURLClosure = loadUserAvatarURLClosure {
            return await loadUserAvatarURLClosure()
        } else {
            return loadUserAvatarURLReturnValue
        }
    }
    //MARK: - setUserAvatar

    private let setUserAvatarMediaCallsCountLock = NSLock()
    private var setUserAvatarMediaUnderlyingCallsCount = 0
    var setUserAvatarMediaCallsCount: Int {
        get { setUserAvatarMediaCallsCountLock.withLock { setUserAvatarMediaUnderlyingCallsCount } }
        set { setUserAvatarMediaCallsCountLock.withLock { setUserAvatarMediaUnderlyingCallsCount = newValue } }
    }
    var setUserAvatarMediaCalled: Bool {
        return setUserAvatarMediaCallsCount > 0
    }
    private let setUserAvatarMediaReceivedMediaLock = NSLock()
    private var setUserAvatarMediaUnderlyingReceivedMedia: MediaInfo?
    var setUserAvatarMediaReceivedMedia: MediaInfo? {
        get { setUserAvatarMediaReceivedMediaLock.withLock { setUserAvatarMediaUnderlyingReceivedMedia } }
        set { setUserAvatarMediaReceivedMediaLock.withLock { setUserAvatarMediaUnderlyingReceivedMedia = newValue } }
    }
    private let setUserAvatarMediaReceivedInvocationsLock = NSLock()
    private var setUserAvatarMediaUnderlyingReceivedInvocations: [MediaInfo] = []
    var setUserAvatarMediaReceivedInvocations: [MediaInfo] {
        get { setUserAvatarMediaReceivedInvocationsLock.withLock { setUserAvatarMediaUnderlyingReceivedInvocations } }
        set { setUserAvatarMediaReceivedInvocationsLock.withLock { setUserAvatarMediaUnderlyingReceivedInvocations = newValue } }
    }

    private let setUserAvatarMediaReturnValueLock = NSLock()
    private var setUserAvatarMediaUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var setUserAvatarMediaReturnValue: Result<Void, ClientProxyError>! {
        get { setUserAvatarMediaReturnValueLock.withLock { setUserAvatarMediaUnderlyingReturnValue } }
        set { setUserAvatarMediaReturnValueLock.withLock { setUserAvatarMediaUnderlyingReturnValue = newValue } }
    }
    var setUserAvatarMediaClosure: ((MediaInfo) async -> Result<Void, ClientProxyError>)?

    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        setUserAvatarMediaCallsCountLock.withLock { setUserAvatarMediaUnderlyingCallsCount += 1 }
        setUserAvatarMediaReceivedMedia = media
        setUserAvatarMediaReceivedInvocationsLock.withLock { setUserAvatarMediaUnderlyingReceivedInvocations.append(media) }
        if let setUserAvatarMediaClosure = setUserAvatarMediaClosure {
            return await setUserAvatarMediaClosure(media)
        } else {
            return setUserAvatarMediaReturnValue
        }
    }
    //MARK: - removeUserAvatar

    private let removeUserAvatarCallsCountLock = NSLock()
    private var removeUserAvatarUnderlyingCallsCount = 0
    var removeUserAvatarCallsCount: Int {
        get { removeUserAvatarCallsCountLock.withLock { removeUserAvatarUnderlyingCallsCount } }
        set { removeUserAvatarCallsCountLock.withLock { removeUserAvatarUnderlyingCallsCount = newValue } }
    }
    var removeUserAvatarCalled: Bool {
        return removeUserAvatarCallsCount > 0
    }

    private let removeUserAvatarReturnValueLock = NSLock()
    private var removeUserAvatarUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var removeUserAvatarReturnValue: Result<Void, ClientProxyError>! {
        get { removeUserAvatarReturnValueLock.withLock { removeUserAvatarUnderlyingReturnValue } }
        set { removeUserAvatarReturnValueLock.withLock { removeUserAvatarUnderlyingReturnValue = newValue } }
    }
    var removeUserAvatarClosure: (() async -> Result<Void, ClientProxyError>)?

    func removeUserAvatar() async -> Result<Void, ClientProxyError> {
        removeUserAvatarCallsCountLock.withLock { removeUserAvatarUnderlyingCallsCount += 1 }
        if let removeUserAvatarClosure = removeUserAvatarClosure {
            return await removeUserAvatarClosure()
        } else {
            return removeUserAvatarReturnValue
        }
    }
    //MARK: - linkNewDeviceService

    private let linkNewDeviceServiceCallsCountLock = NSLock()
    private var linkNewDeviceServiceUnderlyingCallsCount = 0
    var linkNewDeviceServiceCallsCount: Int {
        get { linkNewDeviceServiceCallsCountLock.withLock { linkNewDeviceServiceUnderlyingCallsCount } }
        set { linkNewDeviceServiceCallsCountLock.withLock { linkNewDeviceServiceUnderlyingCallsCount = newValue } }
    }
    var linkNewDeviceServiceCalled: Bool {
        return linkNewDeviceServiceCallsCount > 0
    }

    private let linkNewDeviceServiceReturnValueLock = NSLock()
    private var linkNewDeviceServiceUnderlyingReturnValue: LinkNewDeviceServiceProtocol!
    var linkNewDeviceServiceReturnValue: LinkNewDeviceServiceProtocol! {
        get { linkNewDeviceServiceReturnValueLock.withLock { linkNewDeviceServiceUnderlyingReturnValue } }
        set { linkNewDeviceServiceReturnValueLock.withLock { linkNewDeviceServiceUnderlyingReturnValue = newValue } }
    }
    var linkNewDeviceServiceClosure: (() -> LinkNewDeviceServiceProtocol)?

    func linkNewDeviceService() -> LinkNewDeviceServiceProtocol {
        linkNewDeviceServiceCallsCountLock.withLock { linkNewDeviceServiceUnderlyingCallsCount += 1 }
        if let linkNewDeviceServiceClosure = linkNewDeviceServiceClosure {
            return linkNewDeviceServiceClosure()
        } else {
            return linkNewDeviceServiceReturnValue
        }
    }
    //MARK: - deactivateAccount

    private let deactivateAccountPasswordEraseDataCallsCountLock = NSLock()
    private var deactivateAccountPasswordEraseDataUnderlyingCallsCount = 0
    var deactivateAccountPasswordEraseDataCallsCount: Int {
        get { deactivateAccountPasswordEraseDataCallsCountLock.withLock { deactivateAccountPasswordEraseDataUnderlyingCallsCount } }
        set { deactivateAccountPasswordEraseDataCallsCountLock.withLock { deactivateAccountPasswordEraseDataUnderlyingCallsCount = newValue } }
    }
    var deactivateAccountPasswordEraseDataCalled: Bool {
        return deactivateAccountPasswordEraseDataCallsCount > 0
    }
    private let deactivateAccountPasswordEraseDataReceivedArgumentsLock = NSLock()
    private var deactivateAccountPasswordEraseDataUnderlyingReceivedArguments: (password: String?, eraseData: Bool)?
    var deactivateAccountPasswordEraseDataReceivedArguments: (password: String?, eraseData: Bool)? {
        get { deactivateAccountPasswordEraseDataReceivedArgumentsLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReceivedArguments } }
        set { deactivateAccountPasswordEraseDataReceivedArgumentsLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReceivedArguments = newValue } }
    }
    private let deactivateAccountPasswordEraseDataReceivedInvocationsLock = NSLock()
    private var deactivateAccountPasswordEraseDataUnderlyingReceivedInvocations: [(password: String?, eraseData: Bool)] = []
    var deactivateAccountPasswordEraseDataReceivedInvocations: [(password: String?, eraseData: Bool)] {
        get { deactivateAccountPasswordEraseDataReceivedInvocationsLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReceivedInvocations } }
        set { deactivateAccountPasswordEraseDataReceivedInvocationsLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReceivedInvocations = newValue } }
    }

    private let deactivateAccountPasswordEraseDataReturnValueLock = NSLock()
    private var deactivateAccountPasswordEraseDataUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var deactivateAccountPasswordEraseDataReturnValue: Result<Void, ClientProxyError>! {
        get { deactivateAccountPasswordEraseDataReturnValueLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReturnValue } }
        set { deactivateAccountPasswordEraseDataReturnValueLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReturnValue = newValue } }
    }
    var deactivateAccountPasswordEraseDataClosure: ((String?, Bool) async -> Result<Void, ClientProxyError>)?

    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError> {
        deactivateAccountPasswordEraseDataCallsCountLock.withLock { deactivateAccountPasswordEraseDataUnderlyingCallsCount += 1 }
        deactivateAccountPasswordEraseDataReceivedArguments = (password: password, eraseData: eraseData)
        deactivateAccountPasswordEraseDataReceivedInvocationsLock.withLock { deactivateAccountPasswordEraseDataUnderlyingReceivedInvocations.append((password: password, eraseData: eraseData)) }
        if let deactivateAccountPasswordEraseDataClosure = deactivateAccountPasswordEraseDataClosure {
            return await deactivateAccountPasswordEraseDataClosure(password, eraseData)
        } else {
            return deactivateAccountPasswordEraseDataReturnValue
        }
    }
    //MARK: - logout

    private let logoutCallsCountLock = NSLock()
    private var logoutUnderlyingCallsCount = 0
    var logoutCallsCount: Int {
        get { logoutCallsCountLock.withLock { logoutUnderlyingCallsCount } }
        set { logoutCallsCountLock.withLock { logoutUnderlyingCallsCount = newValue } }
    }
    var logoutCalled: Bool {
        return logoutCallsCount > 0
    }
    var logoutClosure: (() async -> Void)?

    func logout() async {
        logoutCallsCountLock.withLock { logoutUnderlyingCallsCount += 1 }
        await logoutClosure?()
    }
    //MARK: - setPusher

    var setPusherWithThrowableError: Error?
    private let setPusherWithCallsCountLock = NSLock()
    private var setPusherWithUnderlyingCallsCount = 0
    var setPusherWithCallsCount: Int {
        get { setPusherWithCallsCountLock.withLock { setPusherWithUnderlyingCallsCount } }
        set { setPusherWithCallsCountLock.withLock { setPusherWithUnderlyingCallsCount = newValue } }
    }
    var setPusherWithCalled: Bool {
        return setPusherWithCallsCount > 0
    }
    private let setPusherWithReceivedConfigurationLock = NSLock()
    private var setPusherWithUnderlyingReceivedConfiguration: PusherConfiguration?
    var setPusherWithReceivedConfiguration: PusherConfiguration? {
        get { setPusherWithReceivedConfigurationLock.withLock { setPusherWithUnderlyingReceivedConfiguration } }
        set { setPusherWithReceivedConfigurationLock.withLock { setPusherWithUnderlyingReceivedConfiguration = newValue } }
    }
    private let setPusherWithReceivedInvocationsLock = NSLock()
    private var setPusherWithUnderlyingReceivedInvocations: [PusherConfiguration] = []
    var setPusherWithReceivedInvocations: [PusherConfiguration] {
        get { setPusherWithReceivedInvocationsLock.withLock { setPusherWithUnderlyingReceivedInvocations } }
        set { setPusherWithReceivedInvocationsLock.withLock { setPusherWithUnderlyingReceivedInvocations = newValue } }
    }
    var setPusherWithClosure: ((PusherConfiguration) async throws -> Void)?

    func setPusher(with configuration: PusherConfiguration) async throws {
        if let error = setPusherWithThrowableError {
            throw error
        }
        setPusherWithCallsCountLock.withLock { setPusherWithUnderlyingCallsCount += 1 }
        setPusherWithReceivedConfiguration = configuration
        setPusherWithReceivedInvocationsLock.withLock { setPusherWithUnderlyingReceivedInvocations.append(configuration) }
        try await setPusherWithClosure?(configuration)
    }
    //MARK: - searchUsers

    private let searchUsersSearchTermLimitCallsCountLock = NSLock()
    private var searchUsersSearchTermLimitUnderlyingCallsCount = 0
    var searchUsersSearchTermLimitCallsCount: Int {
        get { searchUsersSearchTermLimitCallsCountLock.withLock { searchUsersSearchTermLimitUnderlyingCallsCount } }
        set { searchUsersSearchTermLimitCallsCountLock.withLock { searchUsersSearchTermLimitUnderlyingCallsCount = newValue } }
    }
    var searchUsersSearchTermLimitCalled: Bool {
        return searchUsersSearchTermLimitCallsCount > 0
    }
    private let searchUsersSearchTermLimitReceivedArgumentsLock = NSLock()
    private var searchUsersSearchTermLimitUnderlyingReceivedArguments: (searchTerm: String, limit: UInt)?
    var searchUsersSearchTermLimitReceivedArguments: (searchTerm: String, limit: UInt)? {
        get { searchUsersSearchTermLimitReceivedArgumentsLock.withLock { searchUsersSearchTermLimitUnderlyingReceivedArguments } }
        set { searchUsersSearchTermLimitReceivedArgumentsLock.withLock { searchUsersSearchTermLimitUnderlyingReceivedArguments = newValue } }
    }
    private let searchUsersSearchTermLimitReceivedInvocationsLock = NSLock()
    private var searchUsersSearchTermLimitUnderlyingReceivedInvocations: [(searchTerm: String, limit: UInt)] = []
    var searchUsersSearchTermLimitReceivedInvocations: [(searchTerm: String, limit: UInt)] {
        get { searchUsersSearchTermLimitReceivedInvocationsLock.withLock { searchUsersSearchTermLimitUnderlyingReceivedInvocations } }
        set { searchUsersSearchTermLimitReceivedInvocationsLock.withLock { searchUsersSearchTermLimitUnderlyingReceivedInvocations = newValue } }
    }

    private let searchUsersSearchTermLimitReturnValueLock = NSLock()
    private var searchUsersSearchTermLimitUnderlyingReturnValue: Result<SearchUsersResultsProxy, ClientProxyError>!
    var searchUsersSearchTermLimitReturnValue: Result<SearchUsersResultsProxy, ClientProxyError>! {
        get { searchUsersSearchTermLimitReturnValueLock.withLock { searchUsersSearchTermLimitUnderlyingReturnValue } }
        set { searchUsersSearchTermLimitReturnValueLock.withLock { searchUsersSearchTermLimitUnderlyingReturnValue = newValue } }
    }
    var searchUsersSearchTermLimitClosure: ((String, UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>)?

    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError> {
        searchUsersSearchTermLimitCallsCountLock.withLock { searchUsersSearchTermLimitUnderlyingCallsCount += 1 }
        searchUsersSearchTermLimitReceivedArguments = (searchTerm: searchTerm, limit: limit)
        searchUsersSearchTermLimitReceivedInvocationsLock.withLock { searchUsersSearchTermLimitUnderlyingReceivedInvocations.append((searchTerm: searchTerm, limit: limit)) }
        if let searchUsersSearchTermLimitClosure = searchUsersSearchTermLimitClosure {
            return await searchUsersSearchTermLimitClosure(searchTerm, limit)
        } else {
            return searchUsersSearchTermLimitReturnValue
        }
    }
    //MARK: - profile

    private let profileForCallsCountLock = NSLock()
    private var profileForUnderlyingCallsCount = 0
    var profileForCallsCount: Int {
        get { profileForCallsCountLock.withLock { profileForUnderlyingCallsCount } }
        set { profileForCallsCountLock.withLock { profileForUnderlyingCallsCount = newValue } }
    }
    var profileForCalled: Bool {
        return profileForCallsCount > 0
    }
    private let profileForReceivedUserIDLock = NSLock()
    private var profileForUnderlyingReceivedUserID: String?
    var profileForReceivedUserID: String? {
        get { profileForReceivedUserIDLock.withLock { profileForUnderlyingReceivedUserID } }
        set { profileForReceivedUserIDLock.withLock { profileForUnderlyingReceivedUserID = newValue } }
    }
    private let profileForReceivedInvocationsLock = NSLock()
    private var profileForUnderlyingReceivedInvocations: [String] = []
    var profileForReceivedInvocations: [String] {
        get { profileForReceivedInvocationsLock.withLock { profileForUnderlyingReceivedInvocations } }
        set { profileForReceivedInvocationsLock.withLock { profileForUnderlyingReceivedInvocations = newValue } }
    }

    private let profileForReturnValueLock = NSLock()
    private var profileForUnderlyingReturnValue: Result<UserProfileProxy, ClientProxyError>!
    var profileForReturnValue: Result<UserProfileProxy, ClientProxyError>! {
        get { profileForReturnValueLock.withLock { profileForUnderlyingReturnValue } }
        set { profileForReturnValueLock.withLock { profileForUnderlyingReturnValue = newValue } }
    }
    var profileForClosure: ((String) async -> Result<UserProfileProxy, ClientProxyError>)?

    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        profileForCallsCountLock.withLock { profileForUnderlyingCallsCount += 1 }
        profileForReceivedUserID = userID
        profileForReceivedInvocationsLock.withLock { profileForUnderlyingReceivedInvocations.append(userID) }
        if let profileForClosure = profileForClosure {
            return await profileForClosure(userID)
        } else {
            return profileForReturnValue
        }
    }
    //MARK: - roomDirectorySearchProxy

    private let roomDirectorySearchProxyCallsCountLock = NSLock()
    private var roomDirectorySearchProxyUnderlyingCallsCount = 0
    var roomDirectorySearchProxyCallsCount: Int {
        get { roomDirectorySearchProxyCallsCountLock.withLock { roomDirectorySearchProxyUnderlyingCallsCount } }
        set { roomDirectorySearchProxyCallsCountLock.withLock { roomDirectorySearchProxyUnderlyingCallsCount = newValue } }
    }
    var roomDirectorySearchProxyCalled: Bool {
        return roomDirectorySearchProxyCallsCount > 0
    }

    private let roomDirectorySearchProxyReturnValueLock = NSLock()
    private var roomDirectorySearchProxyUnderlyingReturnValue: RoomDirectorySearchProxyProtocol!
    var roomDirectorySearchProxyReturnValue: RoomDirectorySearchProxyProtocol! {
        get { roomDirectorySearchProxyReturnValueLock.withLock { roomDirectorySearchProxyUnderlyingReturnValue } }
        set { roomDirectorySearchProxyReturnValueLock.withLock { roomDirectorySearchProxyUnderlyingReturnValue = newValue } }
    }
    var roomDirectorySearchProxyClosure: (() -> RoomDirectorySearchProxyProtocol)?

    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol {
        roomDirectorySearchProxyCallsCountLock.withLock { roomDirectorySearchProxyUnderlyingCallsCount += 1 }
        if let roomDirectorySearchProxyClosure = roomDirectorySearchProxyClosure {
            return roomDirectorySearchProxyClosure()
        } else {
            return roomDirectorySearchProxyReturnValue
        }
    }
    //MARK: - resolveRoomAlias

    private let resolveRoomAliasCallsCountLock = NSLock()
    private var resolveRoomAliasUnderlyingCallsCount = 0
    var resolveRoomAliasCallsCount: Int {
        get { resolveRoomAliasCallsCountLock.withLock { resolveRoomAliasUnderlyingCallsCount } }
        set { resolveRoomAliasCallsCountLock.withLock { resolveRoomAliasUnderlyingCallsCount = newValue } }
    }
    var resolveRoomAliasCalled: Bool {
        return resolveRoomAliasCallsCount > 0
    }
    private let resolveRoomAliasReceivedAliasLock = NSLock()
    private var resolveRoomAliasUnderlyingReceivedAlias: String?
    var resolveRoomAliasReceivedAlias: String? {
        get { resolveRoomAliasReceivedAliasLock.withLock { resolveRoomAliasUnderlyingReceivedAlias } }
        set { resolveRoomAliasReceivedAliasLock.withLock { resolveRoomAliasUnderlyingReceivedAlias = newValue } }
    }
    private let resolveRoomAliasReceivedInvocationsLock = NSLock()
    private var resolveRoomAliasUnderlyingReceivedInvocations: [String] = []
    var resolveRoomAliasReceivedInvocations: [String] {
        get { resolveRoomAliasReceivedInvocationsLock.withLock { resolveRoomAliasUnderlyingReceivedInvocations } }
        set { resolveRoomAliasReceivedInvocationsLock.withLock { resolveRoomAliasUnderlyingReceivedInvocations = newValue } }
    }

    private let resolveRoomAliasReturnValueLock = NSLock()
    private var resolveRoomAliasUnderlyingReturnValue: Result<ResolvedRoomAlias, ClientProxyError>!
    var resolveRoomAliasReturnValue: Result<ResolvedRoomAlias, ClientProxyError>! {
        get { resolveRoomAliasReturnValueLock.withLock { resolveRoomAliasUnderlyingReturnValue } }
        set { resolveRoomAliasReturnValueLock.withLock { resolveRoomAliasUnderlyingReturnValue = newValue } }
    }
    var resolveRoomAliasClosure: ((String) async -> Result<ResolvedRoomAlias, ClientProxyError>)?

    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError> {
        resolveRoomAliasCallsCountLock.withLock { resolveRoomAliasUnderlyingCallsCount += 1 }
        resolveRoomAliasReceivedAlias = alias
        resolveRoomAliasReceivedInvocationsLock.withLock { resolveRoomAliasUnderlyingReceivedInvocations.append(alias) }
        if let resolveRoomAliasClosure = resolveRoomAliasClosure {
            return await resolveRoomAliasClosure(alias)
        } else {
            return resolveRoomAliasReturnValue
        }
    }
    //MARK: - isAliasAvailable

    private let isAliasAvailableCallsCountLock = NSLock()
    private var isAliasAvailableUnderlyingCallsCount = 0
    var isAliasAvailableCallsCount: Int {
        get { isAliasAvailableCallsCountLock.withLock { isAliasAvailableUnderlyingCallsCount } }
        set { isAliasAvailableCallsCountLock.withLock { isAliasAvailableUnderlyingCallsCount = newValue } }
    }
    var isAliasAvailableCalled: Bool {
        return isAliasAvailableCallsCount > 0
    }
    private let isAliasAvailableReceivedAliasLock = NSLock()
    private var isAliasAvailableUnderlyingReceivedAlias: String?
    var isAliasAvailableReceivedAlias: String? {
        get { isAliasAvailableReceivedAliasLock.withLock { isAliasAvailableUnderlyingReceivedAlias } }
        set { isAliasAvailableReceivedAliasLock.withLock { isAliasAvailableUnderlyingReceivedAlias = newValue } }
    }
    private let isAliasAvailableReceivedInvocationsLock = NSLock()
    private var isAliasAvailableUnderlyingReceivedInvocations: [String] = []
    var isAliasAvailableReceivedInvocations: [String] {
        get { isAliasAvailableReceivedInvocationsLock.withLock { isAliasAvailableUnderlyingReceivedInvocations } }
        set { isAliasAvailableReceivedInvocationsLock.withLock { isAliasAvailableUnderlyingReceivedInvocations = newValue } }
    }

    private let isAliasAvailableReturnValueLock = NSLock()
    private var isAliasAvailableUnderlyingReturnValue: Result<Bool, ClientProxyError>!
    var isAliasAvailableReturnValue: Result<Bool, ClientProxyError>! {
        get { isAliasAvailableReturnValueLock.withLock { isAliasAvailableUnderlyingReturnValue } }
        set { isAliasAvailableReturnValueLock.withLock { isAliasAvailableUnderlyingReturnValue = newValue } }
    }
    var isAliasAvailableClosure: ((String) async -> Result<Bool, ClientProxyError>)?

    func isAliasAvailable(_ alias: String) async -> Result<Bool, ClientProxyError> {
        isAliasAvailableCallsCountLock.withLock { isAliasAvailableUnderlyingCallsCount += 1 }
        isAliasAvailableReceivedAlias = alias
        isAliasAvailableReceivedInvocationsLock.withLock { isAliasAvailableUnderlyingReceivedInvocations.append(alias) }
        if let isAliasAvailableClosure = isAliasAvailableClosure {
            return await isAliasAvailableClosure(alias)
        } else {
            return isAliasAvailableReturnValue
        }
    }
    //MARK: - clearCaches

    private let clearCachesCallsCountLock = NSLock()
    private var clearCachesUnderlyingCallsCount = 0
    var clearCachesCallsCount: Int {
        get { clearCachesCallsCountLock.withLock { clearCachesUnderlyingCallsCount } }
        set { clearCachesCallsCountLock.withLock { clearCachesUnderlyingCallsCount = newValue } }
    }
    var clearCachesCalled: Bool {
        return clearCachesCallsCount > 0
    }

    private let clearCachesReturnValueLock = NSLock()
    private var clearCachesUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var clearCachesReturnValue: Result<Void, ClientProxyError>! {
        get { clearCachesReturnValueLock.withLock { clearCachesUnderlyingReturnValue } }
        set { clearCachesReturnValueLock.withLock { clearCachesUnderlyingReturnValue = newValue } }
    }
    var clearCachesClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func clearCaches() async -> Result<Void, ClientProxyError> {
        clearCachesCallsCountLock.withLock { clearCachesUnderlyingCallsCount += 1 }
        if let clearCachesClosure = clearCachesClosure {
            return await clearCachesClosure()
        } else {
            return clearCachesReturnValue
        }
    }
    //MARK: - optimizeStores

    private let optimizeStoresCallsCountLock = NSLock()
    private var optimizeStoresUnderlyingCallsCount = 0
    var optimizeStoresCallsCount: Int {
        get { optimizeStoresCallsCountLock.withLock { optimizeStoresUnderlyingCallsCount } }
        set { optimizeStoresCallsCountLock.withLock { optimizeStoresUnderlyingCallsCount = newValue } }
    }
    var optimizeStoresCalled: Bool {
        return optimizeStoresCallsCount > 0
    }

    private let optimizeStoresReturnValueLock = NSLock()
    private var optimizeStoresUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var optimizeStoresReturnValue: Result<Void, ClientProxyError>! {
        get { optimizeStoresReturnValueLock.withLock { optimizeStoresUnderlyingReturnValue } }
        set { optimizeStoresReturnValueLock.withLock { optimizeStoresUnderlyingReturnValue = newValue } }
    }
    var optimizeStoresClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func optimizeStores() async -> Result<Void, ClientProxyError> {
        optimizeStoresCallsCountLock.withLock { optimizeStoresUnderlyingCallsCount += 1 }
        if let optimizeStoresClosure = optimizeStoresClosure {
            return await optimizeStoresClosure()
        } else {
            return optimizeStoresReturnValue
        }
    }
    //MARK: - markAllRoomsAsRead

    private let markAllRoomsAsReadCallsCountLock = NSLock()
    private var markAllRoomsAsReadUnderlyingCallsCount = 0
    var markAllRoomsAsReadCallsCount: Int {
        get { markAllRoomsAsReadCallsCountLock.withLock { markAllRoomsAsReadUnderlyingCallsCount } }
        set { markAllRoomsAsReadCallsCountLock.withLock { markAllRoomsAsReadUnderlyingCallsCount = newValue } }
    }
    var markAllRoomsAsReadCalled: Bool {
        return markAllRoomsAsReadCallsCount > 0
    }

    private let markAllRoomsAsReadReturnValueLock = NSLock()
    private var markAllRoomsAsReadUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var markAllRoomsAsReadReturnValue: Result<Void, ClientProxyError>! {
        get { markAllRoomsAsReadReturnValueLock.withLock { markAllRoomsAsReadUnderlyingReturnValue } }
        set { markAllRoomsAsReadReturnValueLock.withLock { markAllRoomsAsReadUnderlyingReturnValue = newValue } }
    }
    var markAllRoomsAsReadClosure: (() async -> Result<Void, ClientProxyError>)?

    @discardableResult
    func markAllRoomsAsRead() async -> Result<Void, ClientProxyError> {
        markAllRoomsAsReadCallsCountLock.withLock { markAllRoomsAsReadUnderlyingCallsCount += 1 }
        if let markAllRoomsAsReadClosure = markAllRoomsAsReadClosure {
            return await markAllRoomsAsReadClosure()
        } else {
            return markAllRoomsAsReadReturnValue
        }
    }
    //MARK: - storeSizes

    private let storeSizesCallsCountLock = NSLock()
    private var storeSizesUnderlyingCallsCount = 0
    var storeSizesCallsCount: Int {
        get { storeSizesCallsCountLock.withLock { storeSizesUnderlyingCallsCount } }
        set { storeSizesCallsCountLock.withLock { storeSizesUnderlyingCallsCount = newValue } }
    }
    var storeSizesCalled: Bool {
        return storeSizesCallsCount > 0
    }

    private let storeSizesReturnValueLock = NSLock()
    private var storeSizesUnderlyingReturnValue: Result<StoreSizes, ClientProxyError>!
    var storeSizesReturnValue: Result<StoreSizes, ClientProxyError>! {
        get { storeSizesReturnValueLock.withLock { storeSizesUnderlyingReturnValue } }
        set { storeSizesReturnValueLock.withLock { storeSizesUnderlyingReturnValue = newValue } }
    }
    var storeSizesClosure: (() async -> Result<StoreSizes, ClientProxyError>)?

    func storeSizes() async -> Result<StoreSizes, ClientProxyError> {
        storeSizesCallsCountLock.withLock { storeSizesUnderlyingCallsCount += 1 }
        if let storeSizesClosure = storeSizesClosure {
            return await storeSizesClosure()
        } else {
            return storeSizesReturnValue
        }
    }
    //MARK: - fetchMediaPreviewConfiguration

    private let fetchMediaPreviewConfigurationCallsCountLock = NSLock()
    private var fetchMediaPreviewConfigurationUnderlyingCallsCount = 0
    var fetchMediaPreviewConfigurationCallsCount: Int {
        get { fetchMediaPreviewConfigurationCallsCountLock.withLock { fetchMediaPreviewConfigurationUnderlyingCallsCount } }
        set { fetchMediaPreviewConfigurationCallsCountLock.withLock { fetchMediaPreviewConfigurationUnderlyingCallsCount = newValue } }
    }
    var fetchMediaPreviewConfigurationCalled: Bool {
        return fetchMediaPreviewConfigurationCallsCount > 0
    }

    private let fetchMediaPreviewConfigurationReturnValueLock = NSLock()
    private var fetchMediaPreviewConfigurationUnderlyingReturnValue: Result<MediaPreviewConfig?, ClientProxyError>!
    var fetchMediaPreviewConfigurationReturnValue: Result<MediaPreviewConfig?, ClientProxyError>! {
        get { fetchMediaPreviewConfigurationReturnValueLock.withLock { fetchMediaPreviewConfigurationUnderlyingReturnValue } }
        set { fetchMediaPreviewConfigurationReturnValueLock.withLock { fetchMediaPreviewConfigurationUnderlyingReturnValue = newValue } }
    }
    var fetchMediaPreviewConfigurationClosure: (() async -> Result<MediaPreviewConfig?, ClientProxyError>)?

    func fetchMediaPreviewConfiguration() async -> Result<MediaPreviewConfig?, ClientProxyError> {
        fetchMediaPreviewConfigurationCallsCountLock.withLock { fetchMediaPreviewConfigurationUnderlyingCallsCount += 1 }
        if let fetchMediaPreviewConfigurationClosure = fetchMediaPreviewConfigurationClosure {
            return await fetchMediaPreviewConfigurationClosure()
        } else {
            return fetchMediaPreviewConfigurationReturnValue
        }
    }
    //MARK: - ignoreUser

    private let ignoreUserCallsCountLock = NSLock()
    private var ignoreUserUnderlyingCallsCount = 0
    var ignoreUserCallsCount: Int {
        get { ignoreUserCallsCountLock.withLock { ignoreUserUnderlyingCallsCount } }
        set { ignoreUserCallsCountLock.withLock { ignoreUserUnderlyingCallsCount = newValue } }
    }
    var ignoreUserCalled: Bool {
        return ignoreUserCallsCount > 0
    }
    private let ignoreUserReceivedUserIDLock = NSLock()
    private var ignoreUserUnderlyingReceivedUserID: String?
    var ignoreUserReceivedUserID: String? {
        get { ignoreUserReceivedUserIDLock.withLock { ignoreUserUnderlyingReceivedUserID } }
        set { ignoreUserReceivedUserIDLock.withLock { ignoreUserUnderlyingReceivedUserID = newValue } }
    }
    private let ignoreUserReceivedInvocationsLock = NSLock()
    private var ignoreUserUnderlyingReceivedInvocations: [String] = []
    var ignoreUserReceivedInvocations: [String] {
        get { ignoreUserReceivedInvocationsLock.withLock { ignoreUserUnderlyingReceivedInvocations } }
        set { ignoreUserReceivedInvocationsLock.withLock { ignoreUserUnderlyingReceivedInvocations = newValue } }
    }

    private let ignoreUserReturnValueLock = NSLock()
    private var ignoreUserUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var ignoreUserReturnValue: Result<Void, ClientProxyError>! {
        get { ignoreUserReturnValueLock.withLock { ignoreUserUnderlyingReturnValue } }
        set { ignoreUserReturnValueLock.withLock { ignoreUserUnderlyingReturnValue = newValue } }
    }
    var ignoreUserClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        ignoreUserCallsCountLock.withLock { ignoreUserUnderlyingCallsCount += 1 }
        ignoreUserReceivedUserID = userID
        ignoreUserReceivedInvocationsLock.withLock { ignoreUserUnderlyingReceivedInvocations.append(userID) }
        if let ignoreUserClosure = ignoreUserClosure {
            return await ignoreUserClosure(userID)
        } else {
            return ignoreUserReturnValue
        }
    }
    //MARK: - unignoreUser

    private let unignoreUserCallsCountLock = NSLock()
    private var unignoreUserUnderlyingCallsCount = 0
    var unignoreUserCallsCount: Int {
        get { unignoreUserCallsCountLock.withLock { unignoreUserUnderlyingCallsCount } }
        set { unignoreUserCallsCountLock.withLock { unignoreUserUnderlyingCallsCount = newValue } }
    }
    var unignoreUserCalled: Bool {
        return unignoreUserCallsCount > 0
    }
    private let unignoreUserReceivedUserIDLock = NSLock()
    private var unignoreUserUnderlyingReceivedUserID: String?
    var unignoreUserReceivedUserID: String? {
        get { unignoreUserReceivedUserIDLock.withLock { unignoreUserUnderlyingReceivedUserID } }
        set { unignoreUserReceivedUserIDLock.withLock { unignoreUserUnderlyingReceivedUserID = newValue } }
    }
    private let unignoreUserReceivedInvocationsLock = NSLock()
    private var unignoreUserUnderlyingReceivedInvocations: [String] = []
    var unignoreUserReceivedInvocations: [String] {
        get { unignoreUserReceivedInvocationsLock.withLock { unignoreUserUnderlyingReceivedInvocations } }
        set { unignoreUserReceivedInvocationsLock.withLock { unignoreUserUnderlyingReceivedInvocations = newValue } }
    }

    private let unignoreUserReturnValueLock = NSLock()
    private var unignoreUserUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var unignoreUserReturnValue: Result<Void, ClientProxyError>! {
        get { unignoreUserReturnValueLock.withLock { unignoreUserUnderlyingReturnValue } }
        set { unignoreUserReturnValueLock.withLock { unignoreUserUnderlyingReturnValue = newValue } }
    }
    var unignoreUserClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        unignoreUserCallsCountLock.withLock { unignoreUserUnderlyingCallsCount += 1 }
        unignoreUserReceivedUserID = userID
        unignoreUserReceivedInvocationsLock.withLock { unignoreUserUnderlyingReceivedInvocations.append(userID) }
        if let unignoreUserClosure = unignoreUserClosure {
            return await unignoreUserClosure(userID)
        } else {
            return unignoreUserReturnValue
        }
    }
    //MARK: - trackRecentlyVisitedRoom

    private let trackRecentlyVisitedRoomCallsCountLock = NSLock()
    private var trackRecentlyVisitedRoomUnderlyingCallsCount = 0
    var trackRecentlyVisitedRoomCallsCount: Int {
        get { trackRecentlyVisitedRoomCallsCountLock.withLock { trackRecentlyVisitedRoomUnderlyingCallsCount } }
        set { trackRecentlyVisitedRoomCallsCountLock.withLock { trackRecentlyVisitedRoomUnderlyingCallsCount = newValue } }
    }
    var trackRecentlyVisitedRoomCalled: Bool {
        return trackRecentlyVisitedRoomCallsCount > 0
    }
    private let trackRecentlyVisitedRoomReceivedRoomIDLock = NSLock()
    private var trackRecentlyVisitedRoomUnderlyingReceivedRoomID: String?
    var trackRecentlyVisitedRoomReceivedRoomID: String? {
        get { trackRecentlyVisitedRoomReceivedRoomIDLock.withLock { trackRecentlyVisitedRoomUnderlyingReceivedRoomID } }
        set { trackRecentlyVisitedRoomReceivedRoomIDLock.withLock { trackRecentlyVisitedRoomUnderlyingReceivedRoomID = newValue } }
    }
    private let trackRecentlyVisitedRoomReceivedInvocationsLock = NSLock()
    private var trackRecentlyVisitedRoomUnderlyingReceivedInvocations: [String] = []
    var trackRecentlyVisitedRoomReceivedInvocations: [String] {
        get { trackRecentlyVisitedRoomReceivedInvocationsLock.withLock { trackRecentlyVisitedRoomUnderlyingReceivedInvocations } }
        set { trackRecentlyVisitedRoomReceivedInvocationsLock.withLock { trackRecentlyVisitedRoomUnderlyingReceivedInvocations = newValue } }
    }

    private let trackRecentlyVisitedRoomReturnValueLock = NSLock()
    private var trackRecentlyVisitedRoomUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var trackRecentlyVisitedRoomReturnValue: Result<Void, ClientProxyError>! {
        get { trackRecentlyVisitedRoomReturnValueLock.withLock { trackRecentlyVisitedRoomUnderlyingReturnValue } }
        set { trackRecentlyVisitedRoomReturnValueLock.withLock { trackRecentlyVisitedRoomUnderlyingReturnValue = newValue } }
    }
    var trackRecentlyVisitedRoomClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func trackRecentlyVisitedRoom(_ roomID: String) async -> Result<Void, ClientProxyError> {
        trackRecentlyVisitedRoomCallsCountLock.withLock { trackRecentlyVisitedRoomUnderlyingCallsCount += 1 }
        trackRecentlyVisitedRoomReceivedRoomID = roomID
        trackRecentlyVisitedRoomReceivedInvocationsLock.withLock { trackRecentlyVisitedRoomUnderlyingReceivedInvocations.append(roomID) }
        if let trackRecentlyVisitedRoomClosure = trackRecentlyVisitedRoomClosure {
            return await trackRecentlyVisitedRoomClosure(roomID)
        } else {
            return trackRecentlyVisitedRoomReturnValue
        }
    }
    //MARK: - recentlyVisitedRooms

    private let recentlyVisitedRoomsFilterCallsCountLock = NSLock()
    private var recentlyVisitedRoomsFilterUnderlyingCallsCount = 0
    var recentlyVisitedRoomsFilterCallsCount: Int {
        get { recentlyVisitedRoomsFilterCallsCountLock.withLock { recentlyVisitedRoomsFilterUnderlyingCallsCount } }
        set { recentlyVisitedRoomsFilterCallsCountLock.withLock { recentlyVisitedRoomsFilterUnderlyingCallsCount = newValue } }
    }
    var recentlyVisitedRoomsFilterCalled: Bool {
        return recentlyVisitedRoomsFilterCallsCount > 0
    }

    private let recentlyVisitedRoomsFilterReturnValueLock = NSLock()
    private var recentlyVisitedRoomsFilterUnderlyingReturnValue: [JoinedRoomProxyProtocol]!
    var recentlyVisitedRoomsFilterReturnValue: [JoinedRoomProxyProtocol]! {
        get { recentlyVisitedRoomsFilterReturnValueLock.withLock { recentlyVisitedRoomsFilterUnderlyingReturnValue } }
        set { recentlyVisitedRoomsFilterReturnValueLock.withLock { recentlyVisitedRoomsFilterUnderlyingReturnValue = newValue } }
    }
    var recentlyVisitedRoomsFilterClosure: (((JoinedRoomProxyProtocol) -> Bool) async -> [JoinedRoomProxyProtocol])?

    func recentlyVisitedRooms(filter: (JoinedRoomProxyProtocol) -> Bool) async -> [JoinedRoomProxyProtocol] {
        recentlyVisitedRoomsFilterCallsCountLock.withLock { recentlyVisitedRoomsFilterUnderlyingCallsCount += 1 }
        if let recentlyVisitedRoomsFilterClosure = recentlyVisitedRoomsFilterClosure {
            return await recentlyVisitedRoomsFilterClosure(filter)
        } else {
            return recentlyVisitedRoomsFilterReturnValue
        }
    }
    //MARK: - recentConversationCounterparts

    private let recentConversationCounterpartsCallsCountLock = NSLock()
    private var recentConversationCounterpartsUnderlyingCallsCount = 0
    var recentConversationCounterpartsCallsCount: Int {
        get { recentConversationCounterpartsCallsCountLock.withLock { recentConversationCounterpartsUnderlyingCallsCount } }
        set { recentConversationCounterpartsCallsCountLock.withLock { recentConversationCounterpartsUnderlyingCallsCount = newValue } }
    }
    var recentConversationCounterpartsCalled: Bool {
        return recentConversationCounterpartsCallsCount > 0
    }

    private let recentConversationCounterpartsReturnValueLock = NSLock()
    private var recentConversationCounterpartsUnderlyingReturnValue: [UserProfileProxy]!
    var recentConversationCounterpartsReturnValue: [UserProfileProxy]! {
        get { recentConversationCounterpartsReturnValueLock.withLock { recentConversationCounterpartsUnderlyingReturnValue } }
        set { recentConversationCounterpartsReturnValueLock.withLock { recentConversationCounterpartsUnderlyingReturnValue = newValue } }
    }
    var recentConversationCounterpartsClosure: (() async -> [UserProfileProxy])?

    func recentConversationCounterparts() async -> [UserProfileProxy] {
        recentConversationCounterpartsCallsCountLock.withLock { recentConversationCounterpartsUnderlyingCallsCount += 1 }
        if let recentConversationCounterpartsClosure = recentConversationCounterpartsClosure {
            return await recentConversationCounterpartsClosure()
        } else {
            return recentConversationCounterpartsReturnValue
        }
    }
    //MARK: - ed25519Base64

    private let ed25519Base64CallsCountLock = NSLock()
    private var ed25519Base64UnderlyingCallsCount = 0
    var ed25519Base64CallsCount: Int {
        get { ed25519Base64CallsCountLock.withLock { ed25519Base64UnderlyingCallsCount } }
        set { ed25519Base64CallsCountLock.withLock { ed25519Base64UnderlyingCallsCount = newValue } }
    }
    var ed25519Base64Called: Bool {
        return ed25519Base64CallsCount > 0
    }

    private let ed25519Base64ReturnValueLock = NSLock()
    private var ed25519Base64UnderlyingReturnValue: String?
    var ed25519Base64ReturnValue: String? {
        get { ed25519Base64ReturnValueLock.withLock { ed25519Base64UnderlyingReturnValue } }
        set { ed25519Base64ReturnValueLock.withLock { ed25519Base64UnderlyingReturnValue = newValue } }
    }
    var ed25519Base64Closure: (() async -> String?)?

    func ed25519Base64() async -> String? {
        ed25519Base64CallsCountLock.withLock { ed25519Base64UnderlyingCallsCount += 1 }
        if let ed25519Base64Closure = ed25519Base64Closure {
            return await ed25519Base64Closure()
        } else {
            return ed25519Base64ReturnValue
        }
    }
    //MARK: - curve25519Base64

    private let curve25519Base64CallsCountLock = NSLock()
    private var curve25519Base64UnderlyingCallsCount = 0
    var curve25519Base64CallsCount: Int {
        get { curve25519Base64CallsCountLock.withLock { curve25519Base64UnderlyingCallsCount } }
        set { curve25519Base64CallsCountLock.withLock { curve25519Base64UnderlyingCallsCount = newValue } }
    }
    var curve25519Base64Called: Bool {
        return curve25519Base64CallsCount > 0
    }

    private let curve25519Base64ReturnValueLock = NSLock()
    private var curve25519Base64UnderlyingReturnValue: String?
    var curve25519Base64ReturnValue: String? {
        get { curve25519Base64ReturnValueLock.withLock { curve25519Base64UnderlyingReturnValue } }
        set { curve25519Base64ReturnValueLock.withLock { curve25519Base64UnderlyingReturnValue = newValue } }
    }
    var curve25519Base64Closure: (() async -> String?)?

    func curve25519Base64() async -> String? {
        curve25519Base64CallsCountLock.withLock { curve25519Base64UnderlyingCallsCount += 1 }
        if let curve25519Base64Closure = curve25519Base64Closure {
            return await curve25519Base64Closure()
        } else {
            return curve25519Base64ReturnValue
        }
    }
    //MARK: - pinUserIdentity

    private let pinUserIdentityCallsCountLock = NSLock()
    private var pinUserIdentityUnderlyingCallsCount = 0
    var pinUserIdentityCallsCount: Int {
        get { pinUserIdentityCallsCountLock.withLock { pinUserIdentityUnderlyingCallsCount } }
        set { pinUserIdentityCallsCountLock.withLock { pinUserIdentityUnderlyingCallsCount = newValue } }
    }
    var pinUserIdentityCalled: Bool {
        return pinUserIdentityCallsCount > 0
    }
    private let pinUserIdentityReceivedUserIDLock = NSLock()
    private var pinUserIdentityUnderlyingReceivedUserID: String?
    var pinUserIdentityReceivedUserID: String? {
        get { pinUserIdentityReceivedUserIDLock.withLock { pinUserIdentityUnderlyingReceivedUserID } }
        set { pinUserIdentityReceivedUserIDLock.withLock { pinUserIdentityUnderlyingReceivedUserID = newValue } }
    }
    private let pinUserIdentityReceivedInvocationsLock = NSLock()
    private var pinUserIdentityUnderlyingReceivedInvocations: [String] = []
    var pinUserIdentityReceivedInvocations: [String] {
        get { pinUserIdentityReceivedInvocationsLock.withLock { pinUserIdentityUnderlyingReceivedInvocations } }
        set { pinUserIdentityReceivedInvocationsLock.withLock { pinUserIdentityUnderlyingReceivedInvocations = newValue } }
    }

    private let pinUserIdentityReturnValueLock = NSLock()
    private var pinUserIdentityUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var pinUserIdentityReturnValue: Result<Void, ClientProxyError>! {
        get { pinUserIdentityReturnValueLock.withLock { pinUserIdentityUnderlyingReturnValue } }
        set { pinUserIdentityReturnValueLock.withLock { pinUserIdentityUnderlyingReturnValue = newValue } }
    }
    var pinUserIdentityClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func pinUserIdentity(_ userID: String) async -> Result<Void, ClientProxyError> {
        pinUserIdentityCallsCountLock.withLock { pinUserIdentityUnderlyingCallsCount += 1 }
        pinUserIdentityReceivedUserID = userID
        pinUserIdentityReceivedInvocationsLock.withLock { pinUserIdentityUnderlyingReceivedInvocations.append(userID) }
        if let pinUserIdentityClosure = pinUserIdentityClosure {
            return await pinUserIdentityClosure(userID)
        } else {
            return pinUserIdentityReturnValue
        }
    }
    //MARK: - withdrawUserIdentityVerification

    private let withdrawUserIdentityVerificationCallsCountLock = NSLock()
    private var withdrawUserIdentityVerificationUnderlyingCallsCount = 0
    var withdrawUserIdentityVerificationCallsCount: Int {
        get { withdrawUserIdentityVerificationCallsCountLock.withLock { withdrawUserIdentityVerificationUnderlyingCallsCount } }
        set { withdrawUserIdentityVerificationCallsCountLock.withLock { withdrawUserIdentityVerificationUnderlyingCallsCount = newValue } }
    }
    var withdrawUserIdentityVerificationCalled: Bool {
        return withdrawUserIdentityVerificationCallsCount > 0
    }
    private let withdrawUserIdentityVerificationReceivedUserIDLock = NSLock()
    private var withdrawUserIdentityVerificationUnderlyingReceivedUserID: String?
    var withdrawUserIdentityVerificationReceivedUserID: String? {
        get { withdrawUserIdentityVerificationReceivedUserIDLock.withLock { withdrawUserIdentityVerificationUnderlyingReceivedUserID } }
        set { withdrawUserIdentityVerificationReceivedUserIDLock.withLock { withdrawUserIdentityVerificationUnderlyingReceivedUserID = newValue } }
    }
    private let withdrawUserIdentityVerificationReceivedInvocationsLock = NSLock()
    private var withdrawUserIdentityVerificationUnderlyingReceivedInvocations: [String] = []
    var withdrawUserIdentityVerificationReceivedInvocations: [String] {
        get { withdrawUserIdentityVerificationReceivedInvocationsLock.withLock { withdrawUserIdentityVerificationUnderlyingReceivedInvocations } }
        set { withdrawUserIdentityVerificationReceivedInvocationsLock.withLock { withdrawUserIdentityVerificationUnderlyingReceivedInvocations = newValue } }
    }

    private let withdrawUserIdentityVerificationReturnValueLock = NSLock()
    private var withdrawUserIdentityVerificationUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var withdrawUserIdentityVerificationReturnValue: Result<Void, ClientProxyError>! {
        get { withdrawUserIdentityVerificationReturnValueLock.withLock { withdrawUserIdentityVerificationUnderlyingReturnValue } }
        set { withdrawUserIdentityVerificationReturnValueLock.withLock { withdrawUserIdentityVerificationUnderlyingReturnValue = newValue } }
    }
    var withdrawUserIdentityVerificationClosure: ((String) async -> Result<Void, ClientProxyError>)?

    func withdrawUserIdentityVerification(_ userID: String) async -> Result<Void, ClientProxyError> {
        withdrawUserIdentityVerificationCallsCountLock.withLock { withdrawUserIdentityVerificationUnderlyingCallsCount += 1 }
        withdrawUserIdentityVerificationReceivedUserID = userID
        withdrawUserIdentityVerificationReceivedInvocationsLock.withLock { withdrawUserIdentityVerificationUnderlyingReceivedInvocations.append(userID) }
        if let withdrawUserIdentityVerificationClosure = withdrawUserIdentityVerificationClosure {
            return await withdrawUserIdentityVerificationClosure(userID)
        } else {
            return withdrawUserIdentityVerificationReturnValue
        }
    }
    //MARK: - resetIdentity

    private let resetIdentityCallsCountLock = NSLock()
    private var resetIdentityUnderlyingCallsCount = 0
    var resetIdentityCallsCount: Int {
        get { resetIdentityCallsCountLock.withLock { resetIdentityUnderlyingCallsCount } }
        set { resetIdentityCallsCountLock.withLock { resetIdentityUnderlyingCallsCount = newValue } }
    }
    var resetIdentityCalled: Bool {
        return resetIdentityCallsCount > 0
    }

    private let resetIdentityReturnValueLock = NSLock()
    private var resetIdentityUnderlyingReturnValue: Result<IdentityResetHandle?, ClientProxyError>!
    var resetIdentityReturnValue: Result<IdentityResetHandle?, ClientProxyError>! {
        get { resetIdentityReturnValueLock.withLock { resetIdentityUnderlyingReturnValue } }
        set { resetIdentityReturnValueLock.withLock { resetIdentityUnderlyingReturnValue = newValue } }
    }
    var resetIdentityClosure: (() async -> Result<IdentityResetHandle?, ClientProxyError>)?

    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError> {
        resetIdentityCallsCountLock.withLock { resetIdentityUnderlyingCallsCount += 1 }
        if let resetIdentityClosure = resetIdentityClosure {
            return await resetIdentityClosure()
        } else {
            return resetIdentityReturnValue
        }
    }
    //MARK: - userIdentity

    private let userIdentityForFallBackToServerCallsCountLock = NSLock()
    private var userIdentityForFallBackToServerUnderlyingCallsCount = 0
    var userIdentityForFallBackToServerCallsCount: Int {
        get { userIdentityForFallBackToServerCallsCountLock.withLock { userIdentityForFallBackToServerUnderlyingCallsCount } }
        set { userIdentityForFallBackToServerCallsCountLock.withLock { userIdentityForFallBackToServerUnderlyingCallsCount = newValue } }
    }
    var userIdentityForFallBackToServerCalled: Bool {
        return userIdentityForFallBackToServerCallsCount > 0
    }
    private let userIdentityForFallBackToServerReceivedArgumentsLock = NSLock()
    private var userIdentityForFallBackToServerUnderlyingReceivedArguments: (userID: String, fallBackToServer: Bool)?
    var userIdentityForFallBackToServerReceivedArguments: (userID: String, fallBackToServer: Bool)? {
        get { userIdentityForFallBackToServerReceivedArgumentsLock.withLock { userIdentityForFallBackToServerUnderlyingReceivedArguments } }
        set { userIdentityForFallBackToServerReceivedArgumentsLock.withLock { userIdentityForFallBackToServerUnderlyingReceivedArguments = newValue } }
    }
    private let userIdentityForFallBackToServerReceivedInvocationsLock = NSLock()
    private var userIdentityForFallBackToServerUnderlyingReceivedInvocations: [(userID: String, fallBackToServer: Bool)] = []
    var userIdentityForFallBackToServerReceivedInvocations: [(userID: String, fallBackToServer: Bool)] {
        get { userIdentityForFallBackToServerReceivedInvocationsLock.withLock { userIdentityForFallBackToServerUnderlyingReceivedInvocations } }
        set { userIdentityForFallBackToServerReceivedInvocationsLock.withLock { userIdentityForFallBackToServerUnderlyingReceivedInvocations = newValue } }
    }

    private let userIdentityForFallBackToServerReturnValueLock = NSLock()
    private var userIdentityForFallBackToServerUnderlyingReturnValue: Result<UserIdentityProxyProtocol?, ClientProxyError>!
    var userIdentityForFallBackToServerReturnValue: Result<UserIdentityProxyProtocol?, ClientProxyError>! {
        get { userIdentityForFallBackToServerReturnValueLock.withLock { userIdentityForFallBackToServerUnderlyingReturnValue } }
        set { userIdentityForFallBackToServerReturnValueLock.withLock { userIdentityForFallBackToServerUnderlyingReturnValue = newValue } }
    }
    var userIdentityForFallBackToServerClosure: ((String, Bool) async -> Result<UserIdentityProxyProtocol?, ClientProxyError>)?

    func userIdentity(for userID: String, fallBackToServer: Bool) async -> Result<UserIdentityProxyProtocol?, ClientProxyError> {
        userIdentityForFallBackToServerCallsCountLock.withLock { userIdentityForFallBackToServerUnderlyingCallsCount += 1 }
        userIdentityForFallBackToServerReceivedArguments = (userID: userID, fallBackToServer: fallBackToServer)
        userIdentityForFallBackToServerReceivedInvocationsLock.withLock { userIdentityForFallBackToServerUnderlyingReceivedInvocations.append((userID: userID, fallBackToServer: fallBackToServer)) }
        if let userIdentityForFallBackToServerClosure = userIdentityForFallBackToServerClosure {
            return await userIdentityForFallBackToServerClosure(userID, fallBackToServer)
        } else {
            return userIdentityForFallBackToServerReturnValue
        }
    }
    //MARK: - setTimelineMediaVisibility

    private let setTimelineMediaVisibilityCallsCountLock = NSLock()
    private var setTimelineMediaVisibilityUnderlyingCallsCount = 0
    var setTimelineMediaVisibilityCallsCount: Int {
        get { setTimelineMediaVisibilityCallsCountLock.withLock { setTimelineMediaVisibilityUnderlyingCallsCount } }
        set { setTimelineMediaVisibilityCallsCountLock.withLock { setTimelineMediaVisibilityUnderlyingCallsCount = newValue } }
    }
    var setTimelineMediaVisibilityCalled: Bool {
        return setTimelineMediaVisibilityCallsCount > 0
    }
    private let setTimelineMediaVisibilityReceivedValueLock = NSLock()
    private var setTimelineMediaVisibilityUnderlyingReceivedValue: TimelineMediaVisibility?
    var setTimelineMediaVisibilityReceivedValue: TimelineMediaVisibility? {
        get { setTimelineMediaVisibilityReceivedValueLock.withLock { setTimelineMediaVisibilityUnderlyingReceivedValue } }
        set { setTimelineMediaVisibilityReceivedValueLock.withLock { setTimelineMediaVisibilityUnderlyingReceivedValue = newValue } }
    }
    private let setTimelineMediaVisibilityReceivedInvocationsLock = NSLock()
    private var setTimelineMediaVisibilityUnderlyingReceivedInvocations: [TimelineMediaVisibility] = []
    var setTimelineMediaVisibilityReceivedInvocations: [TimelineMediaVisibility] {
        get { setTimelineMediaVisibilityReceivedInvocationsLock.withLock { setTimelineMediaVisibilityUnderlyingReceivedInvocations } }
        set { setTimelineMediaVisibilityReceivedInvocationsLock.withLock { setTimelineMediaVisibilityUnderlyingReceivedInvocations = newValue } }
    }

    private let setTimelineMediaVisibilityReturnValueLock = NSLock()
    private var setTimelineMediaVisibilityUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var setTimelineMediaVisibilityReturnValue: Result<Void, ClientProxyError>! {
        get { setTimelineMediaVisibilityReturnValueLock.withLock { setTimelineMediaVisibilityUnderlyingReturnValue } }
        set { setTimelineMediaVisibilityReturnValueLock.withLock { setTimelineMediaVisibilityUnderlyingReturnValue = newValue } }
    }
    var setTimelineMediaVisibilityClosure: ((TimelineMediaVisibility) async -> Result<Void, ClientProxyError>)?

    func setTimelineMediaVisibility(_ value: TimelineMediaVisibility) async -> Result<Void, ClientProxyError> {
        setTimelineMediaVisibilityCallsCountLock.withLock { setTimelineMediaVisibilityUnderlyingCallsCount += 1 }
        setTimelineMediaVisibilityReceivedValue = value
        setTimelineMediaVisibilityReceivedInvocationsLock.withLock { setTimelineMediaVisibilityUnderlyingReceivedInvocations.append(value) }
        if let setTimelineMediaVisibilityClosure = setTimelineMediaVisibilityClosure {
            return await setTimelineMediaVisibilityClosure(value)
        } else {
            return setTimelineMediaVisibilityReturnValue
        }
    }
    //MARK: - setHideInviteAvatars

    private let setHideInviteAvatarsCallsCountLock = NSLock()
    private var setHideInviteAvatarsUnderlyingCallsCount = 0
    var setHideInviteAvatarsCallsCount: Int {
        get { setHideInviteAvatarsCallsCountLock.withLock { setHideInviteAvatarsUnderlyingCallsCount } }
        set { setHideInviteAvatarsCallsCountLock.withLock { setHideInviteAvatarsUnderlyingCallsCount = newValue } }
    }
    var setHideInviteAvatarsCalled: Bool {
        return setHideInviteAvatarsCallsCount > 0
    }
    private let setHideInviteAvatarsReceivedValueLock = NSLock()
    private var setHideInviteAvatarsUnderlyingReceivedValue: Bool?
    var setHideInviteAvatarsReceivedValue: Bool? {
        get { setHideInviteAvatarsReceivedValueLock.withLock { setHideInviteAvatarsUnderlyingReceivedValue } }
        set { setHideInviteAvatarsReceivedValueLock.withLock { setHideInviteAvatarsUnderlyingReceivedValue = newValue } }
    }
    private let setHideInviteAvatarsReceivedInvocationsLock = NSLock()
    private var setHideInviteAvatarsUnderlyingReceivedInvocations: [Bool] = []
    var setHideInviteAvatarsReceivedInvocations: [Bool] {
        get { setHideInviteAvatarsReceivedInvocationsLock.withLock { setHideInviteAvatarsUnderlyingReceivedInvocations } }
        set { setHideInviteAvatarsReceivedInvocationsLock.withLock { setHideInviteAvatarsUnderlyingReceivedInvocations = newValue } }
    }

    private let setHideInviteAvatarsReturnValueLock = NSLock()
    private var setHideInviteAvatarsUnderlyingReturnValue: Result<Void, ClientProxyError>!
    var setHideInviteAvatarsReturnValue: Result<Void, ClientProxyError>! {
        get { setHideInviteAvatarsReturnValueLock.withLock { setHideInviteAvatarsUnderlyingReturnValue } }
        set { setHideInviteAvatarsReturnValueLock.withLock { setHideInviteAvatarsUnderlyingReturnValue = newValue } }
    }
    var setHideInviteAvatarsClosure: ((Bool) async -> Result<Void, ClientProxyError>)?

    func setHideInviteAvatars(_ value: Bool) async -> Result<Void, ClientProxyError> {
        setHideInviteAvatarsCallsCountLock.withLock { setHideInviteAvatarsUnderlyingCallsCount += 1 }
        setHideInviteAvatarsReceivedValue = value
        setHideInviteAvatarsReceivedInvocationsLock.withLock { setHideInviteAvatarsUnderlyingReceivedInvocations.append(value) }
        if let setHideInviteAvatarsClosure = setHideInviteAvatarsClosure {
            return await setHideInviteAvatarsClosure(value)
        } else {
            return setHideInviteAvatarsReturnValue
        }
    }
}
class CompletionSuggestionServiceMock: CompletionSuggestionServiceProtocol, @unchecked Sendable {
    var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> {
        get { return underlyingSuggestionsPublisher }
        set(value) { underlyingSuggestionsPublisher = value }
    }
    var underlyingSuggestionsPublisher: AnyPublisher<[SuggestionItem], Never>!

    //MARK: - processTextMessage

    private let processTextMessageSelectedRangeCallsCountLock = NSLock()
    private var processTextMessageSelectedRangeUnderlyingCallsCount = 0
    var processTextMessageSelectedRangeCallsCount: Int {
        get { processTextMessageSelectedRangeCallsCountLock.withLock { processTextMessageSelectedRangeUnderlyingCallsCount } }
        set { processTextMessageSelectedRangeCallsCountLock.withLock { processTextMessageSelectedRangeUnderlyingCallsCount = newValue } }
    }
    var processTextMessageSelectedRangeCalled: Bool {
        return processTextMessageSelectedRangeCallsCount > 0
    }
    private let processTextMessageSelectedRangeReceivedArgumentsLock = NSLock()
    private var processTextMessageSelectedRangeUnderlyingReceivedArguments: (textMessage: String, selectedRange: NSRange)?
    var processTextMessageSelectedRangeReceivedArguments: (textMessage: String, selectedRange: NSRange)? {
        get { processTextMessageSelectedRangeReceivedArgumentsLock.withLock { processTextMessageSelectedRangeUnderlyingReceivedArguments } }
        set { processTextMessageSelectedRangeReceivedArgumentsLock.withLock { processTextMessageSelectedRangeUnderlyingReceivedArguments = newValue } }
    }
    private let processTextMessageSelectedRangeReceivedInvocationsLock = NSLock()
    private var processTextMessageSelectedRangeUnderlyingReceivedInvocations: [(textMessage: String, selectedRange: NSRange)] = []
    var processTextMessageSelectedRangeReceivedInvocations: [(textMessage: String, selectedRange: NSRange)] {
        get { processTextMessageSelectedRangeReceivedInvocationsLock.withLock { processTextMessageSelectedRangeUnderlyingReceivedInvocations } }
        set { processTextMessageSelectedRangeReceivedInvocationsLock.withLock { processTextMessageSelectedRangeUnderlyingReceivedInvocations = newValue } }
    }
    var processTextMessageSelectedRangeClosure: ((String, NSRange) -> Void)?

    func processTextMessage(_ textMessage: String, selectedRange: NSRange) {
        processTextMessageSelectedRangeCallsCountLock.withLock { processTextMessageSelectedRangeUnderlyingCallsCount += 1 }
        processTextMessageSelectedRangeReceivedArguments = (textMessage: textMessage, selectedRange: selectedRange)
        processTextMessageSelectedRangeReceivedInvocationsLock.withLock { processTextMessageSelectedRangeUnderlyingReceivedInvocations.append((textMessage: textMessage, selectedRange: selectedRange)) }
        processTextMessageSelectedRangeClosure?(textMessage, selectedRange)
    }
    //MARK: - setSuggestionTrigger

    private let setSuggestionTriggerCallsCountLock = NSLock()
    private var setSuggestionTriggerUnderlyingCallsCount = 0
    var setSuggestionTriggerCallsCount: Int {
        get { setSuggestionTriggerCallsCountLock.withLock { setSuggestionTriggerUnderlyingCallsCount } }
        set { setSuggestionTriggerCallsCountLock.withLock { setSuggestionTriggerUnderlyingCallsCount = newValue } }
    }
    var setSuggestionTriggerCalled: Bool {
        return setSuggestionTriggerCallsCount > 0
    }
    private let setSuggestionTriggerReceivedSuggestionTriggerLock = NSLock()
    private var setSuggestionTriggerUnderlyingReceivedSuggestionTrigger: SuggestionTrigger?
    var setSuggestionTriggerReceivedSuggestionTrigger: SuggestionTrigger? {
        get { setSuggestionTriggerReceivedSuggestionTriggerLock.withLock { setSuggestionTriggerUnderlyingReceivedSuggestionTrigger } }
        set { setSuggestionTriggerReceivedSuggestionTriggerLock.withLock { setSuggestionTriggerUnderlyingReceivedSuggestionTrigger = newValue } }
    }
    private let setSuggestionTriggerReceivedInvocationsLock = NSLock()
    private var setSuggestionTriggerUnderlyingReceivedInvocations: [SuggestionTrigger?] = []
    var setSuggestionTriggerReceivedInvocations: [SuggestionTrigger?] {
        get { setSuggestionTriggerReceivedInvocationsLock.withLock { setSuggestionTriggerUnderlyingReceivedInvocations } }
        set { setSuggestionTriggerReceivedInvocationsLock.withLock { setSuggestionTriggerUnderlyingReceivedInvocations = newValue } }
    }
    var setSuggestionTriggerClosure: ((SuggestionTrigger?) -> Void)?

    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        setSuggestionTriggerCallsCountLock.withLock { setSuggestionTriggerUnderlyingCallsCount += 1 }
        setSuggestionTriggerReceivedSuggestionTrigger = suggestionTrigger
        setSuggestionTriggerReceivedInvocationsLock.withLock { setSuggestionTriggerUnderlyingReceivedInvocations.append(suggestionTrigger) }
        setSuggestionTriggerClosure?(suggestionTrigger)
    }
}
class ComposerDraftServiceMock: ComposerDraftServiceProtocol, @unchecked Sendable {

    //MARK: - saveDraft

    private let saveDraftCallsCountLock = NSLock()
    private var saveDraftUnderlyingCallsCount = 0
    var saveDraftCallsCount: Int {
        get { saveDraftCallsCountLock.withLock { saveDraftUnderlyingCallsCount } }
        set { saveDraftCallsCountLock.withLock { saveDraftUnderlyingCallsCount = newValue } }
    }
    var saveDraftCalled: Bool {
        return saveDraftCallsCount > 0
    }
    private let saveDraftReceivedDraftLock = NSLock()
    private var saveDraftUnderlyingReceivedDraft: ComposerDraftProxy?
    var saveDraftReceivedDraft: ComposerDraftProxy? {
        get { saveDraftReceivedDraftLock.withLock { saveDraftUnderlyingReceivedDraft } }
        set { saveDraftReceivedDraftLock.withLock { saveDraftUnderlyingReceivedDraft = newValue } }
    }
    private let saveDraftReceivedInvocationsLock = NSLock()
    private var saveDraftUnderlyingReceivedInvocations: [ComposerDraftProxy] = []
    var saveDraftReceivedInvocations: [ComposerDraftProxy] {
        get { saveDraftReceivedInvocationsLock.withLock { saveDraftUnderlyingReceivedInvocations } }
        set { saveDraftReceivedInvocationsLock.withLock { saveDraftUnderlyingReceivedInvocations = newValue } }
    }

    private let saveDraftReturnValueLock = NSLock()
    private var saveDraftUnderlyingReturnValue: Result<Void, ComposerDraftServiceError>!
    var saveDraftReturnValue: Result<Void, ComposerDraftServiceError>! {
        get { saveDraftReturnValueLock.withLock { saveDraftUnderlyingReturnValue } }
        set { saveDraftReturnValueLock.withLock { saveDraftUnderlyingReturnValue = newValue } }
    }
    var saveDraftClosure: ((ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError>)?

    func saveDraft(_ draft: ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError> {
        saveDraftCallsCountLock.withLock { saveDraftUnderlyingCallsCount += 1 }
        saveDraftReceivedDraft = draft
        saveDraftReceivedInvocationsLock.withLock { saveDraftUnderlyingReceivedInvocations.append(draft) }
        if let saveDraftClosure = saveDraftClosure {
            return await saveDraftClosure(draft)
        } else {
            return saveDraftReturnValue
        }
    }
    //MARK: - saveVolatileDraft

    private let saveVolatileDraftCallsCountLock = NSLock()
    private var saveVolatileDraftUnderlyingCallsCount = 0
    var saveVolatileDraftCallsCount: Int {
        get { saveVolatileDraftCallsCountLock.withLock { saveVolatileDraftUnderlyingCallsCount } }
        set { saveVolatileDraftCallsCountLock.withLock { saveVolatileDraftUnderlyingCallsCount = newValue } }
    }
    var saveVolatileDraftCalled: Bool {
        return saveVolatileDraftCallsCount > 0
    }
    private let saveVolatileDraftReceivedDraftLock = NSLock()
    private var saveVolatileDraftUnderlyingReceivedDraft: ComposerDraftProxy?
    var saveVolatileDraftReceivedDraft: ComposerDraftProxy? {
        get { saveVolatileDraftReceivedDraftLock.withLock { saveVolatileDraftUnderlyingReceivedDraft } }
        set { saveVolatileDraftReceivedDraftLock.withLock { saveVolatileDraftUnderlyingReceivedDraft = newValue } }
    }
    private let saveVolatileDraftReceivedInvocationsLock = NSLock()
    private var saveVolatileDraftUnderlyingReceivedInvocations: [ComposerDraftProxy] = []
    var saveVolatileDraftReceivedInvocations: [ComposerDraftProxy] {
        get { saveVolatileDraftReceivedInvocationsLock.withLock { saveVolatileDraftUnderlyingReceivedInvocations } }
        set { saveVolatileDraftReceivedInvocationsLock.withLock { saveVolatileDraftUnderlyingReceivedInvocations = newValue } }
    }
    var saveVolatileDraftClosure: ((ComposerDraftProxy) -> Void)?

    func saveVolatileDraft(_ draft: ComposerDraftProxy) {
        saveVolatileDraftCallsCountLock.withLock { saveVolatileDraftUnderlyingCallsCount += 1 }
        saveVolatileDraftReceivedDraft = draft
        saveVolatileDraftReceivedInvocationsLock.withLock { saveVolatileDraftUnderlyingReceivedInvocations.append(draft) }
        saveVolatileDraftClosure?(draft)
    }
    //MARK: - loadDraft

    private let loadDraftCallsCountLock = NSLock()
    private var loadDraftUnderlyingCallsCount = 0
    var loadDraftCallsCount: Int {
        get { loadDraftCallsCountLock.withLock { loadDraftUnderlyingCallsCount } }
        set { loadDraftCallsCountLock.withLock { loadDraftUnderlyingCallsCount = newValue } }
    }
    var loadDraftCalled: Bool {
        return loadDraftCallsCount > 0
    }

    private let loadDraftReturnValueLock = NSLock()
    private var loadDraftUnderlyingReturnValue: Result<ComposerDraftProxy?, ComposerDraftServiceError>!
    var loadDraftReturnValue: Result<ComposerDraftProxy?, ComposerDraftServiceError>! {
        get { loadDraftReturnValueLock.withLock { loadDraftUnderlyingReturnValue } }
        set { loadDraftReturnValueLock.withLock { loadDraftUnderlyingReturnValue = newValue } }
    }
    var loadDraftClosure: (() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError>)?

    func loadDraft() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError> {
        loadDraftCallsCountLock.withLock { loadDraftUnderlyingCallsCount += 1 }
        if let loadDraftClosure = loadDraftClosure {
            return await loadDraftClosure()
        } else {
            return loadDraftReturnValue
        }
    }
    //MARK: - loadVolatileDraft

    private let loadVolatileDraftCallsCountLock = NSLock()
    private var loadVolatileDraftUnderlyingCallsCount = 0
    var loadVolatileDraftCallsCount: Int {
        get { loadVolatileDraftCallsCountLock.withLock { loadVolatileDraftUnderlyingCallsCount } }
        set { loadVolatileDraftCallsCountLock.withLock { loadVolatileDraftUnderlyingCallsCount = newValue } }
    }
    var loadVolatileDraftCalled: Bool {
        return loadVolatileDraftCallsCount > 0
    }

    private let loadVolatileDraftReturnValueLock = NSLock()
    private var loadVolatileDraftUnderlyingReturnValue: ComposerDraftProxy?
    var loadVolatileDraftReturnValue: ComposerDraftProxy? {
        get { loadVolatileDraftReturnValueLock.withLock { loadVolatileDraftUnderlyingReturnValue } }
        set { loadVolatileDraftReturnValueLock.withLock { loadVolatileDraftUnderlyingReturnValue = newValue } }
    }
    var loadVolatileDraftClosure: (() -> ComposerDraftProxy?)?

    func loadVolatileDraft() -> ComposerDraftProxy? {
        loadVolatileDraftCallsCountLock.withLock { loadVolatileDraftUnderlyingCallsCount += 1 }
        if let loadVolatileDraftClosure = loadVolatileDraftClosure {
            return loadVolatileDraftClosure()
        } else {
            return loadVolatileDraftReturnValue
        }
    }
    //MARK: - clearDraft

    private let clearDraftCallsCountLock = NSLock()
    private var clearDraftUnderlyingCallsCount = 0
    var clearDraftCallsCount: Int {
        get { clearDraftCallsCountLock.withLock { clearDraftUnderlyingCallsCount } }
        set { clearDraftCallsCountLock.withLock { clearDraftUnderlyingCallsCount = newValue } }
    }
    var clearDraftCalled: Bool {
        return clearDraftCallsCount > 0
    }

    private let clearDraftReturnValueLock = NSLock()
    private var clearDraftUnderlyingReturnValue: Result<Void, ComposerDraftServiceError>!
    var clearDraftReturnValue: Result<Void, ComposerDraftServiceError>! {
        get { clearDraftReturnValueLock.withLock { clearDraftUnderlyingReturnValue } }
        set { clearDraftReturnValueLock.withLock { clearDraftUnderlyingReturnValue = newValue } }
    }
    var clearDraftClosure: (() async -> Result<Void, ComposerDraftServiceError>)?

    func clearDraft() async -> Result<Void, ComposerDraftServiceError> {
        clearDraftCallsCountLock.withLock { clearDraftUnderlyingCallsCount += 1 }
        if let clearDraftClosure = clearDraftClosure {
            return await clearDraftClosure()
        } else {
            return clearDraftReturnValue
        }
    }
    //MARK: - clearVolatileDraft

    private let clearVolatileDraftCallsCountLock = NSLock()
    private var clearVolatileDraftUnderlyingCallsCount = 0
    var clearVolatileDraftCallsCount: Int {
        get { clearVolatileDraftCallsCountLock.withLock { clearVolatileDraftUnderlyingCallsCount } }
        set { clearVolatileDraftCallsCountLock.withLock { clearVolatileDraftUnderlyingCallsCount = newValue } }
    }
    var clearVolatileDraftCalled: Bool {
        return clearVolatileDraftCallsCount > 0
    }
    var clearVolatileDraftClosure: (() -> Void)?

    func clearVolatileDraft() {
        clearVolatileDraftCallsCountLock.withLock { clearVolatileDraftUnderlyingCallsCount += 1 }
        clearVolatileDraftClosure?()
    }
    //MARK: - getReply

    private let getReplyEventIDCallsCountLock = NSLock()
    private var getReplyEventIDUnderlyingCallsCount = 0
    var getReplyEventIDCallsCount: Int {
        get { getReplyEventIDCallsCountLock.withLock { getReplyEventIDUnderlyingCallsCount } }
        set { getReplyEventIDCallsCountLock.withLock { getReplyEventIDUnderlyingCallsCount = newValue } }
    }
    var getReplyEventIDCalled: Bool {
        return getReplyEventIDCallsCount > 0
    }
    private let getReplyEventIDReceivedEventIDLock = NSLock()
    private var getReplyEventIDUnderlyingReceivedEventID: String?
    var getReplyEventIDReceivedEventID: String? {
        get { getReplyEventIDReceivedEventIDLock.withLock { getReplyEventIDUnderlyingReceivedEventID } }
        set { getReplyEventIDReceivedEventIDLock.withLock { getReplyEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let getReplyEventIDReceivedInvocationsLock = NSLock()
    private var getReplyEventIDUnderlyingReceivedInvocations: [String] = []
    var getReplyEventIDReceivedInvocations: [String] {
        get { getReplyEventIDReceivedInvocationsLock.withLock { getReplyEventIDUnderlyingReceivedInvocations } }
        set { getReplyEventIDReceivedInvocationsLock.withLock { getReplyEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let getReplyEventIDReturnValueLock = NSLock()
    private var getReplyEventIDUnderlyingReturnValue: Result<TimelineItemReply, ComposerDraftServiceError>!
    var getReplyEventIDReturnValue: Result<TimelineItemReply, ComposerDraftServiceError>! {
        get { getReplyEventIDReturnValueLock.withLock { getReplyEventIDUnderlyingReturnValue } }
        set { getReplyEventIDReturnValueLock.withLock { getReplyEventIDUnderlyingReturnValue = newValue } }
    }
    var getReplyEventIDClosure: ((String) async -> Result<TimelineItemReply, ComposerDraftServiceError>)?

    func getReply(eventID: String) async -> Result<TimelineItemReply, ComposerDraftServiceError> {
        getReplyEventIDCallsCountLock.withLock { getReplyEventIDUnderlyingCallsCount += 1 }
        getReplyEventIDReceivedEventID = eventID
        getReplyEventIDReceivedInvocationsLock.withLock { getReplyEventIDUnderlyingReceivedInvocations.append(eventID) }
        if let getReplyEventIDClosure = getReplyEventIDClosure {
            return await getReplyEventIDClosure(eventID)
        } else {
            return getReplyEventIDReturnValue
        }
    }
}
class ElementCallServiceMock: ElementCallServiceProtocol, @unchecked Sendable {
    var actions: AnyPublisher<ElementCallServiceAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<ElementCallServiceAction, Never>!
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        get { return underlyingOngoingCallRoomIDPublisher }
        set(value) { underlyingOngoingCallRoomIDPublisher = value }
    }
    var underlyingOngoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>!

    //MARK: - setClientProxy

    private let setClientProxyCallsCountLock = NSLock()
    private var setClientProxyUnderlyingCallsCount = 0
    var setClientProxyCallsCount: Int {
        get { setClientProxyCallsCountLock.withLock { setClientProxyUnderlyingCallsCount } }
        set { setClientProxyCallsCountLock.withLock { setClientProxyUnderlyingCallsCount = newValue } }
    }
    var setClientProxyCalled: Bool {
        return setClientProxyCallsCount > 0
    }
    private let setClientProxyReceivedClientProxyLock = NSLock()
    private var setClientProxyUnderlyingReceivedClientProxy: ClientProxyProtocol?
    var setClientProxyReceivedClientProxy: ClientProxyProtocol? {
        get { setClientProxyReceivedClientProxyLock.withLock { setClientProxyUnderlyingReceivedClientProxy } }
        set { setClientProxyReceivedClientProxyLock.withLock { setClientProxyUnderlyingReceivedClientProxy = newValue } }
    }
    private let setClientProxyReceivedInvocationsLock = NSLock()
    private var setClientProxyUnderlyingReceivedInvocations: [ClientProxyProtocol] = []
    var setClientProxyReceivedInvocations: [ClientProxyProtocol] {
        get { setClientProxyReceivedInvocationsLock.withLock { setClientProxyUnderlyingReceivedInvocations } }
        set { setClientProxyReceivedInvocationsLock.withLock { setClientProxyUnderlyingReceivedInvocations = newValue } }
    }
    var setClientProxyClosure: ((ClientProxyProtocol) -> Void)?

    func setClientProxy(_ clientProxy: ClientProxyProtocol) {
        setClientProxyCallsCountLock.withLock { setClientProxyUnderlyingCallsCount += 1 }
        setClientProxyReceivedClientProxy = clientProxy
        setClientProxyReceivedInvocationsLock.withLock { setClientProxyUnderlyingReceivedInvocations.append(clientProxy) }
        setClientProxyClosure?(clientProxy)
    }
    //MARK: - setupCallSession

    private let setupCallSessionRoomIDRoomDisplayNameCallsCountLock = NSLock()
    private var setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount = 0
    var setupCallSessionRoomIDRoomDisplayNameCallsCount: Int {
        get { setupCallSessionRoomIDRoomDisplayNameCallsCountLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount } }
        set { setupCallSessionRoomIDRoomDisplayNameCallsCountLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount = newValue } }
    }
    var setupCallSessionRoomIDRoomDisplayNameCalled: Bool {
        return setupCallSessionRoomIDRoomDisplayNameCallsCount > 0
    }
    private let setupCallSessionRoomIDRoomDisplayNameReceivedArgumentsLock = NSLock()
    private var setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedArguments: (roomID: String, roomDisplayName: String)?
    var setupCallSessionRoomIDRoomDisplayNameReceivedArguments: (roomID: String, roomDisplayName: String)? {
        get { setupCallSessionRoomIDRoomDisplayNameReceivedArgumentsLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedArguments } }
        set { setupCallSessionRoomIDRoomDisplayNameReceivedArgumentsLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedArguments = newValue } }
    }
    private let setupCallSessionRoomIDRoomDisplayNameReceivedInvocationsLock = NSLock()
    private var setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedInvocations: [(roomID: String, roomDisplayName: String)] = []
    var setupCallSessionRoomIDRoomDisplayNameReceivedInvocations: [(roomID: String, roomDisplayName: String)] {
        get { setupCallSessionRoomIDRoomDisplayNameReceivedInvocationsLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedInvocations } }
        set { setupCallSessionRoomIDRoomDisplayNameReceivedInvocationsLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedInvocations = newValue } }
    }
    var setupCallSessionRoomIDRoomDisplayNameClosure: ((String, String) async -> Void)?

    func setupCallSession(roomID: String, roomDisplayName: String) async {
        setupCallSessionRoomIDRoomDisplayNameCallsCountLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingCallsCount += 1 }
        setupCallSessionRoomIDRoomDisplayNameReceivedArguments = (roomID: roomID, roomDisplayName: roomDisplayName)
        setupCallSessionRoomIDRoomDisplayNameReceivedInvocationsLock.withLock { setupCallSessionRoomIDRoomDisplayNameUnderlyingReceivedInvocations.append((roomID: roomID, roomDisplayName: roomDisplayName)) }
        await setupCallSessionRoomIDRoomDisplayNameClosure?(roomID, roomDisplayName)
    }
    //MARK: - tearDownCallSession

    private let tearDownCallSessionCallsCountLock = NSLock()
    private var tearDownCallSessionUnderlyingCallsCount = 0
    var tearDownCallSessionCallsCount: Int {
        get { tearDownCallSessionCallsCountLock.withLock { tearDownCallSessionUnderlyingCallsCount } }
        set { tearDownCallSessionCallsCountLock.withLock { tearDownCallSessionUnderlyingCallsCount = newValue } }
    }
    var tearDownCallSessionCalled: Bool {
        return tearDownCallSessionCallsCount > 0
    }
    var tearDownCallSessionClosure: (() -> Void)?

    func tearDownCallSession() {
        tearDownCallSessionCallsCountLock.withLock { tearDownCallSessionUnderlyingCallsCount += 1 }
        tearDownCallSessionClosure?()
    }
    //MARK: - setAudioEnabled

    private let setAudioEnabledRoomIDCallsCountLock = NSLock()
    private var setAudioEnabledRoomIDUnderlyingCallsCount = 0
    var setAudioEnabledRoomIDCallsCount: Int {
        get { setAudioEnabledRoomIDCallsCountLock.withLock { setAudioEnabledRoomIDUnderlyingCallsCount } }
        set { setAudioEnabledRoomIDCallsCountLock.withLock { setAudioEnabledRoomIDUnderlyingCallsCount = newValue } }
    }
    var setAudioEnabledRoomIDCalled: Bool {
        return setAudioEnabledRoomIDCallsCount > 0
    }
    private let setAudioEnabledRoomIDReceivedArgumentsLock = NSLock()
    private var setAudioEnabledRoomIDUnderlyingReceivedArguments: (enabled: Bool, roomID: String)?
    var setAudioEnabledRoomIDReceivedArguments: (enabled: Bool, roomID: String)? {
        get { setAudioEnabledRoomIDReceivedArgumentsLock.withLock { setAudioEnabledRoomIDUnderlyingReceivedArguments } }
        set { setAudioEnabledRoomIDReceivedArgumentsLock.withLock { setAudioEnabledRoomIDUnderlyingReceivedArguments = newValue } }
    }
    private let setAudioEnabledRoomIDReceivedInvocationsLock = NSLock()
    private var setAudioEnabledRoomIDUnderlyingReceivedInvocations: [(enabled: Bool, roomID: String)] = []
    var setAudioEnabledRoomIDReceivedInvocations: [(enabled: Bool, roomID: String)] {
        get { setAudioEnabledRoomIDReceivedInvocationsLock.withLock { setAudioEnabledRoomIDUnderlyingReceivedInvocations } }
        set { setAudioEnabledRoomIDReceivedInvocationsLock.withLock { setAudioEnabledRoomIDUnderlyingReceivedInvocations = newValue } }
    }
    var setAudioEnabledRoomIDClosure: ((Bool, String) -> Void)?

    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        setAudioEnabledRoomIDCallsCountLock.withLock { setAudioEnabledRoomIDUnderlyingCallsCount += 1 }
        setAudioEnabledRoomIDReceivedArguments = (enabled: enabled, roomID: roomID)
        setAudioEnabledRoomIDReceivedInvocationsLock.withLock { setAudioEnabledRoomIDUnderlyingReceivedInvocations.append((enabled: enabled, roomID: roomID)) }
        setAudioEnabledRoomIDClosure?(enabled, roomID)
    }
}
class ElementCallWidgetDriverMock: ElementCallWidgetDriverProtocol, @unchecked Sendable {
    var widgetID: String {
        get { return underlyingWidgetID }
        set(value) { underlyingWidgetID = value }
    }
    var underlyingWidgetID: String!
    var messagePublisher: PassthroughSubject<String, Never> {
        get { return underlyingMessagePublisher }
        set(value) { underlyingMessagePublisher = value }
    }
    var underlyingMessagePublisher: PassthroughSubject<String, Never>!
    var actions: AnyPublisher<ElementCallWidgetDriverAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<ElementCallWidgetDriverAction, Never>!

    //MARK: - start

    private let startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCallsCountLock = NSLock()
    private var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingCallsCount = 0
    var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCallsCount: Int {
        get { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCallsCountLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingCallsCount } }
        set { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCallsCountLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingCallsCount = newValue } }
    }
    var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCalled: Bool {
        return startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCallsCount > 0
    }
    private let startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedArgumentsLock = NSLock()
    private var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedArguments: (baseURL: URL, clientID: String, colorScheme: ColorScheme, voiceOnly: Bool, rageshakeURL: String?, analyticsConfiguration: ElementCallAnalyticsConfiguration?)?
    var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedArguments: (baseURL: URL, clientID: String, colorScheme: ColorScheme, voiceOnly: Bool, rageshakeURL: String?, analyticsConfiguration: ElementCallAnalyticsConfiguration?)? {
        get { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedArgumentsLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedArguments } }
        set { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedArgumentsLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedArguments = newValue } }
    }
    private let startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedInvocationsLock = NSLock()
    private var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedInvocations: [(baseURL: URL, clientID: String, colorScheme: ColorScheme, voiceOnly: Bool, rageshakeURL: String?, analyticsConfiguration: ElementCallAnalyticsConfiguration?)] = []
    var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedInvocations: [(baseURL: URL, clientID: String, colorScheme: ColorScheme, voiceOnly: Bool, rageshakeURL: String?, analyticsConfiguration: ElementCallAnalyticsConfiguration?)] {
        get { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedInvocationsLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedInvocations } }
        set { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedInvocationsLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedInvocations = newValue } }
    }

    private let startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReturnValueLock = NSLock()
    private var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReturnValue: Result<URL, ElementCallWidgetDriverError>!
    var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReturnValue: Result<URL, ElementCallWidgetDriverError>! {
        get { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReturnValueLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReturnValue } }
        set { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReturnValueLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReturnValue = newValue } }
    }
    var startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationClosure: ((URL, String, ColorScheme, Bool, String?, ElementCallAnalyticsConfiguration?) async -> Result<URL, ElementCallWidgetDriverError>)?

    func start(baseURL: URL, clientID: String, colorScheme: ColorScheme, voiceOnly: Bool, rageshakeURL: String?, analyticsConfiguration: ElementCallAnalyticsConfiguration?) async -> Result<URL, ElementCallWidgetDriverError> {
        startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationCallsCountLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingCallsCount += 1 }
        startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedArguments = (baseURL: baseURL, clientID: clientID, colorScheme: colorScheme, voiceOnly: voiceOnly, rageshakeURL: rageshakeURL, analyticsConfiguration: analyticsConfiguration)
        startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReceivedInvocationsLock.withLock { startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationUnderlyingReceivedInvocations.append((baseURL: baseURL, clientID: clientID, colorScheme: colorScheme, voiceOnly: voiceOnly, rageshakeURL: rageshakeURL, analyticsConfiguration: analyticsConfiguration)) }
        if let startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationClosure = startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationClosure {
            return await startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationClosure(baseURL, clientID, colorScheme, voiceOnly, rageshakeURL, analyticsConfiguration)
        } else {
            return startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReturnValue
        }
    }
    //MARK: - handleMessage

    private let handleMessageCallsCountLock = NSLock()
    private var handleMessageUnderlyingCallsCount = 0
    var handleMessageCallsCount: Int {
        get { handleMessageCallsCountLock.withLock { handleMessageUnderlyingCallsCount } }
        set { handleMessageCallsCountLock.withLock { handleMessageUnderlyingCallsCount = newValue } }
    }
    var handleMessageCalled: Bool {
        return handleMessageCallsCount > 0
    }
    private let handleMessageReceivedMessageLock = NSLock()
    private var handleMessageUnderlyingReceivedMessage: String?
    var handleMessageReceivedMessage: String? {
        get { handleMessageReceivedMessageLock.withLock { handleMessageUnderlyingReceivedMessage } }
        set { handleMessageReceivedMessageLock.withLock { handleMessageUnderlyingReceivedMessage = newValue } }
    }
    private let handleMessageReceivedInvocationsLock = NSLock()
    private var handleMessageUnderlyingReceivedInvocations: [String] = []
    var handleMessageReceivedInvocations: [String] {
        get { handleMessageReceivedInvocationsLock.withLock { handleMessageUnderlyingReceivedInvocations } }
        set { handleMessageReceivedInvocationsLock.withLock { handleMessageUnderlyingReceivedInvocations = newValue } }
    }

    private let handleMessageReturnValueLock = NSLock()
    private var handleMessageUnderlyingReturnValue: Result<Bool, ElementCallWidgetDriverError>!
    var handleMessageReturnValue: Result<Bool, ElementCallWidgetDriverError>! {
        get { handleMessageReturnValueLock.withLock { handleMessageUnderlyingReturnValue } }
        set { handleMessageReturnValueLock.withLock { handleMessageUnderlyingReturnValue = newValue } }
    }
    var handleMessageClosure: ((String) async -> Result<Bool, ElementCallWidgetDriverError>)?

    @discardableResult
    func handleMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError> {
        handleMessageCallsCountLock.withLock { handleMessageUnderlyingCallsCount += 1 }
        handleMessageReceivedMessage = message
        handleMessageReceivedInvocationsLock.withLock { handleMessageUnderlyingReceivedInvocations.append(message) }
        if let handleMessageClosure = handleMessageClosure {
            return await handleMessageClosure(message)
        } else {
            return handleMessageReturnValue
        }
    }
}
class HomeserverCapabilitiesProxyMock: HomeserverCapabilitiesProxyProtocol, @unchecked Sendable {

    //MARK: - refresh

    private let refreshCallsCountLock = NSLock()
    private var refreshUnderlyingCallsCount = 0
    var refreshCallsCount: Int {
        get { refreshCallsCountLock.withLock { refreshUnderlyingCallsCount } }
        set { refreshCallsCountLock.withLock { refreshUnderlyingCallsCount = newValue } }
    }
    var refreshCalled: Bool {
        return refreshCallsCount > 0
    }
    var refreshClosure: (() async -> Void)?

    func refresh() async {
        refreshCallsCountLock.withLock { refreshUnderlyingCallsCount += 1 }
        await refreshClosure?()
    }
    //MARK: - canChangeAvatar

    private let canChangeAvatarCallsCountLock = NSLock()
    private var canChangeAvatarUnderlyingCallsCount = 0
    var canChangeAvatarCallsCount: Int {
        get { canChangeAvatarCallsCountLock.withLock { canChangeAvatarUnderlyingCallsCount } }
        set { canChangeAvatarCallsCountLock.withLock { canChangeAvatarUnderlyingCallsCount = newValue } }
    }
    var canChangeAvatarCalled: Bool {
        return canChangeAvatarCallsCount > 0
    }

    private let canChangeAvatarReturnValueLock = NSLock()
    private var canChangeAvatarUnderlyingReturnValue: Bool!
    var canChangeAvatarReturnValue: Bool! {
        get { canChangeAvatarReturnValueLock.withLock { canChangeAvatarUnderlyingReturnValue } }
        set { canChangeAvatarReturnValueLock.withLock { canChangeAvatarUnderlyingReturnValue = newValue } }
    }
    var canChangeAvatarClosure: (() async -> Bool)?

    func canChangeAvatar() async -> Bool {
        canChangeAvatarCallsCountLock.withLock { canChangeAvatarUnderlyingCallsCount += 1 }
        if let canChangeAvatarClosure = canChangeAvatarClosure {
            return await canChangeAvatarClosure()
        } else {
            return canChangeAvatarReturnValue
        }
    }
    //MARK: - canChangeDisplayName

    private let canChangeDisplayNameCallsCountLock = NSLock()
    private var canChangeDisplayNameUnderlyingCallsCount = 0
    var canChangeDisplayNameCallsCount: Int {
        get { canChangeDisplayNameCallsCountLock.withLock { canChangeDisplayNameUnderlyingCallsCount } }
        set { canChangeDisplayNameCallsCountLock.withLock { canChangeDisplayNameUnderlyingCallsCount = newValue } }
    }
    var canChangeDisplayNameCalled: Bool {
        return canChangeDisplayNameCallsCount > 0
    }

    private let canChangeDisplayNameReturnValueLock = NSLock()
    private var canChangeDisplayNameUnderlyingReturnValue: Bool!
    var canChangeDisplayNameReturnValue: Bool! {
        get { canChangeDisplayNameReturnValueLock.withLock { canChangeDisplayNameUnderlyingReturnValue } }
        set { canChangeDisplayNameReturnValueLock.withLock { canChangeDisplayNameUnderlyingReturnValue = newValue } }
    }
    var canChangeDisplayNameClosure: (() async -> Bool)?

    func canChangeDisplayName() async -> Bool {
        canChangeDisplayNameCallsCountLock.withLock { canChangeDisplayNameUnderlyingCallsCount += 1 }
        if let canChangeDisplayNameClosure = canChangeDisplayNameClosure {
            return await canChangeDisplayNameClosure()
        } else {
            return canChangeDisplayNameReturnValue
        }
    }
}
class InvitedRoomProxyMock: InvitedRoomProxyProtocol, @unchecked Sendable {
    var info: BaseRoomInfoProxyProtocol {
        get { return underlyingInfo }
        set(value) { underlyingInfo = value }
    }
    var underlyingInfo: BaseRoomInfoProxyProtocol!
    var inviter: RoomMemberProxyProtocol?
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!

    //MARK: - rejectInvitation

    private let rejectInvitationCallsCountLock = NSLock()
    private var rejectInvitationUnderlyingCallsCount = 0
    var rejectInvitationCallsCount: Int {
        get { rejectInvitationCallsCountLock.withLock { rejectInvitationUnderlyingCallsCount } }
        set { rejectInvitationCallsCountLock.withLock { rejectInvitationUnderlyingCallsCount = newValue } }
    }
    var rejectInvitationCalled: Bool {
        return rejectInvitationCallsCount > 0
    }

    private let rejectInvitationReturnValueLock = NSLock()
    private var rejectInvitationUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var rejectInvitationReturnValue: Result<Void, RoomProxyError>! {
        get { rejectInvitationReturnValueLock.withLock { rejectInvitationUnderlyingReturnValue } }
        set { rejectInvitationReturnValueLock.withLock { rejectInvitationUnderlyingReturnValue = newValue } }
    }
    var rejectInvitationClosure: (() async -> Result<Void, RoomProxyError>)?

    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        rejectInvitationCallsCountLock.withLock { rejectInvitationUnderlyingCallsCount += 1 }
        if let rejectInvitationClosure = rejectInvitationClosure {
            return await rejectInvitationClosure()
        } else {
            return rejectInvitationReturnValue
        }
    }
}
class JoinedRoomProxyMock: JoinedRoomProxyProtocol, @unchecked Sendable {
    var infoPublisher: CurrentValuePublisher<RoomInfoProxyProtocol, Never> {
        get { return underlyingInfoPublisher }
        set(value) { underlyingInfoPublisher = value }
    }
    var underlyingInfoPublisher: CurrentValuePublisher<RoomInfoProxyProtocol, Never>!
    var membersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> {
        get { return underlyingMembersPublisher }
        set(value) { underlyingMembersPublisher = value }
    }
    var underlyingMembersPublisher: CurrentValuePublisher<[RoomMemberProxyProtocol], Never>!
    var typingMembersPublisher: CurrentValuePublisher<[String], Never> {
        get { return underlyingTypingMembersPublisher }
        set(value) { underlyingTypingMembersPublisher = value }
    }
    var underlyingTypingMembersPublisher: CurrentValuePublisher<[String], Never>!
    var identityStatusChangesPublisher: CurrentValuePublisher<[IdentityStatusChange], Never> {
        get { return underlyingIdentityStatusChangesPublisher }
        set(value) { underlyingIdentityStatusChangesPublisher = value }
    }
    var underlyingIdentityStatusChangesPublisher: CurrentValuePublisher<[IdentityStatusChange], Never>!
    var knockRequestsStatePublisher: CurrentValuePublisher<KnockRequestsState, Never> {
        get { return underlyingKnockRequestsStatePublisher }
        set(value) { underlyingKnockRequestsStatePublisher = value }
    }
    var underlyingKnockRequestsStatePublisher: CurrentValuePublisher<KnockRequestsState, Never>!
    var timeline: TimelineProxyProtocol {
        get { return underlyingTimeline }
        set(value) { underlyingTimeline = value }
    }
    var underlyingTimeline: TimelineProxyProtocol!
    var predecessorRoom: PredecessorRoom?
    var successorRoom: SuccessorRoom?
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!

    //MARK: - subscribeForUpdates

    private let subscribeForUpdatesCallsCountLock = NSLock()
    private var subscribeForUpdatesUnderlyingCallsCount = 0
    var subscribeForUpdatesCallsCount: Int {
        get { subscribeForUpdatesCallsCountLock.withLock { subscribeForUpdatesUnderlyingCallsCount } }
        set { subscribeForUpdatesCallsCountLock.withLock { subscribeForUpdatesUnderlyingCallsCount = newValue } }
    }
    var subscribeForUpdatesCalled: Bool {
        return subscribeForUpdatesCallsCount > 0
    }
    var subscribeForUpdatesClosure: (() async -> Void)?

    func subscribeForUpdates() async {
        subscribeForUpdatesCallsCountLock.withLock { subscribeForUpdatesUnderlyingCallsCount += 1 }
        await subscribeForUpdatesClosure?()
    }
    //MARK: - subscribeToRoomInfoUpdates

    private let subscribeToRoomInfoUpdatesCallsCountLock = NSLock()
    private var subscribeToRoomInfoUpdatesUnderlyingCallsCount = 0
    var subscribeToRoomInfoUpdatesCallsCount: Int {
        get { subscribeToRoomInfoUpdatesCallsCountLock.withLock { subscribeToRoomInfoUpdatesUnderlyingCallsCount } }
        set { subscribeToRoomInfoUpdatesCallsCountLock.withLock { subscribeToRoomInfoUpdatesUnderlyingCallsCount = newValue } }
    }
    var subscribeToRoomInfoUpdatesCalled: Bool {
        return subscribeToRoomInfoUpdatesCallsCount > 0
    }
    var subscribeToRoomInfoUpdatesClosure: (() -> Void)?

    func subscribeToRoomInfoUpdates() {
        subscribeToRoomInfoUpdatesCallsCountLock.withLock { subscribeToRoomInfoUpdatesUnderlyingCallsCount += 1 }
        subscribeToRoomInfoUpdatesClosure?()
    }
    //MARK: - timelineFocusedOnEvent

    private let timelineFocusedOnEventEventIDNumberOfEventsCallsCountLock = NSLock()
    private var timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount = 0
    var timelineFocusedOnEventEventIDNumberOfEventsCallsCount: Int {
        get { timelineFocusedOnEventEventIDNumberOfEventsCallsCountLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount } }
        set { timelineFocusedOnEventEventIDNumberOfEventsCallsCountLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount = newValue } }
    }
    var timelineFocusedOnEventEventIDNumberOfEventsCalled: Bool {
        return timelineFocusedOnEventEventIDNumberOfEventsCallsCount > 0
    }
    private let timelineFocusedOnEventEventIDNumberOfEventsReceivedArgumentsLock = NSLock()
    private var timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedArguments: (eventID: String, numberOfEvents: UInt16)?
    var timelineFocusedOnEventEventIDNumberOfEventsReceivedArguments: (eventID: String, numberOfEvents: UInt16)? {
        get { timelineFocusedOnEventEventIDNumberOfEventsReceivedArgumentsLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedArguments } }
        set { timelineFocusedOnEventEventIDNumberOfEventsReceivedArgumentsLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedArguments = newValue } }
    }
    private let timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocationsLock = NSLock()
    private var timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedInvocations: [(eventID: String, numberOfEvents: UInt16)] = []
    var timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocations: [(eventID: String, numberOfEvents: UInt16)] {
        get { timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocationsLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedInvocations } }
        set { timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocationsLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedInvocations = newValue } }
    }

    private let timelineFocusedOnEventEventIDNumberOfEventsReturnValueLock = NSLock()
    private var timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue: Result<TimelineProxyProtocol, RoomProxyError>!
    var timelineFocusedOnEventEventIDNumberOfEventsReturnValue: Result<TimelineProxyProtocol, RoomProxyError>! {
        get { timelineFocusedOnEventEventIDNumberOfEventsReturnValueLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue } }
        set { timelineFocusedOnEventEventIDNumberOfEventsReturnValueLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReturnValue = newValue } }
    }
    var timelineFocusedOnEventEventIDNumberOfEventsClosure: ((String, UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError>)?

    func timelineFocusedOnEvent(eventID: String, numberOfEvents: UInt16) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        timelineFocusedOnEventEventIDNumberOfEventsCallsCountLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingCallsCount += 1 }
        timelineFocusedOnEventEventIDNumberOfEventsReceivedArguments = (eventID: eventID, numberOfEvents: numberOfEvents)
        timelineFocusedOnEventEventIDNumberOfEventsReceivedInvocationsLock.withLock { timelineFocusedOnEventEventIDNumberOfEventsUnderlyingReceivedInvocations.append((eventID: eventID, numberOfEvents: numberOfEvents)) }
        if let timelineFocusedOnEventEventIDNumberOfEventsClosure = timelineFocusedOnEventEventIDNumberOfEventsClosure {
            return await timelineFocusedOnEventEventIDNumberOfEventsClosure(eventID, numberOfEvents)
        } else {
            return timelineFocusedOnEventEventIDNumberOfEventsReturnValue
        }
    }
    //MARK: - threadTimeline

    private let threadTimelineEventIDCallsCountLock = NSLock()
    private var threadTimelineEventIDUnderlyingCallsCount = 0
    var threadTimelineEventIDCallsCount: Int {
        get { threadTimelineEventIDCallsCountLock.withLock { threadTimelineEventIDUnderlyingCallsCount } }
        set { threadTimelineEventIDCallsCountLock.withLock { threadTimelineEventIDUnderlyingCallsCount = newValue } }
    }
    var threadTimelineEventIDCalled: Bool {
        return threadTimelineEventIDCallsCount > 0
    }
    private let threadTimelineEventIDReceivedEventIDLock = NSLock()
    private var threadTimelineEventIDUnderlyingReceivedEventID: String?
    var threadTimelineEventIDReceivedEventID: String? {
        get { threadTimelineEventIDReceivedEventIDLock.withLock { threadTimelineEventIDUnderlyingReceivedEventID } }
        set { threadTimelineEventIDReceivedEventIDLock.withLock { threadTimelineEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let threadTimelineEventIDReceivedInvocationsLock = NSLock()
    private var threadTimelineEventIDUnderlyingReceivedInvocations: [String] = []
    var threadTimelineEventIDReceivedInvocations: [String] {
        get { threadTimelineEventIDReceivedInvocationsLock.withLock { threadTimelineEventIDUnderlyingReceivedInvocations } }
        set { threadTimelineEventIDReceivedInvocationsLock.withLock { threadTimelineEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let threadTimelineEventIDReturnValueLock = NSLock()
    private var threadTimelineEventIDUnderlyingReturnValue: Result<TimelineProxyProtocol, RoomProxyError>!
    var threadTimelineEventIDReturnValue: Result<TimelineProxyProtocol, RoomProxyError>! {
        get { threadTimelineEventIDReturnValueLock.withLock { threadTimelineEventIDUnderlyingReturnValue } }
        set { threadTimelineEventIDReturnValueLock.withLock { threadTimelineEventIDUnderlyingReturnValue = newValue } }
    }
    var threadTimelineEventIDClosure: ((String) async -> Result<TimelineProxyProtocol, RoomProxyError>)?

    func threadTimeline(eventID: String) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        threadTimelineEventIDCallsCountLock.withLock { threadTimelineEventIDUnderlyingCallsCount += 1 }
        threadTimelineEventIDReceivedEventID = eventID
        threadTimelineEventIDReceivedInvocationsLock.withLock { threadTimelineEventIDUnderlyingReceivedInvocations.append(eventID) }
        if let threadTimelineEventIDClosure = threadTimelineEventIDClosure {
            return await threadTimelineEventIDClosure(eventID)
        } else {
            return threadTimelineEventIDReturnValue
        }
    }
    //MARK: - threadListService

    private let threadListServiceCallsCountLock = NSLock()
    private var threadListServiceUnderlyingCallsCount = 0
    var threadListServiceCallsCount: Int {
        get { threadListServiceCallsCountLock.withLock { threadListServiceUnderlyingCallsCount } }
        set { threadListServiceCallsCountLock.withLock { threadListServiceUnderlyingCallsCount = newValue } }
    }
    var threadListServiceCalled: Bool {
        return threadListServiceCallsCount > 0
    }

    private let threadListServiceReturnValueLock = NSLock()
    private var threadListServiceUnderlyingReturnValue: RoomThreadListServiceProxyProtocol!
    var threadListServiceReturnValue: RoomThreadListServiceProxyProtocol! {
        get { threadListServiceReturnValueLock.withLock { threadListServiceUnderlyingReturnValue } }
        set { threadListServiceReturnValueLock.withLock { threadListServiceUnderlyingReturnValue = newValue } }
    }
    var threadListServiceClosure: (() -> RoomThreadListServiceProxyProtocol)?

    func threadListService() -> RoomThreadListServiceProxyProtocol {
        threadListServiceCallsCountLock.withLock { threadListServiceUnderlyingCallsCount += 1 }
        if let threadListServiceClosure = threadListServiceClosure {
            return threadListServiceClosure()
        } else {
            return threadListServiceReturnValue
        }
    }
    //MARK: - loadOrFetchEventDetails

    private let loadOrFetchEventDetailsForCallsCountLock = NSLock()
    private var loadOrFetchEventDetailsForUnderlyingCallsCount = 0
    var loadOrFetchEventDetailsForCallsCount: Int {
        get { loadOrFetchEventDetailsForCallsCountLock.withLock { loadOrFetchEventDetailsForUnderlyingCallsCount } }
        set { loadOrFetchEventDetailsForCallsCountLock.withLock { loadOrFetchEventDetailsForUnderlyingCallsCount = newValue } }
    }
    var loadOrFetchEventDetailsForCalled: Bool {
        return loadOrFetchEventDetailsForCallsCount > 0
    }
    private let loadOrFetchEventDetailsForReceivedEventIDLock = NSLock()
    private var loadOrFetchEventDetailsForUnderlyingReceivedEventID: String?
    var loadOrFetchEventDetailsForReceivedEventID: String? {
        get { loadOrFetchEventDetailsForReceivedEventIDLock.withLock { loadOrFetchEventDetailsForUnderlyingReceivedEventID } }
        set { loadOrFetchEventDetailsForReceivedEventIDLock.withLock { loadOrFetchEventDetailsForUnderlyingReceivedEventID = newValue } }
    }
    private let loadOrFetchEventDetailsForReceivedInvocationsLock = NSLock()
    private var loadOrFetchEventDetailsForUnderlyingReceivedInvocations: [String] = []
    var loadOrFetchEventDetailsForReceivedInvocations: [String] {
        get { loadOrFetchEventDetailsForReceivedInvocationsLock.withLock { loadOrFetchEventDetailsForUnderlyingReceivedInvocations } }
        set { loadOrFetchEventDetailsForReceivedInvocationsLock.withLock { loadOrFetchEventDetailsForUnderlyingReceivedInvocations = newValue } }
    }

    private let loadOrFetchEventDetailsForReturnValueLock = NSLock()
    private var loadOrFetchEventDetailsForUnderlyingReturnValue: Result<TimelineEvent, RoomProxyError>!
    var loadOrFetchEventDetailsForReturnValue: Result<TimelineEvent, RoomProxyError>! {
        get { loadOrFetchEventDetailsForReturnValueLock.withLock { loadOrFetchEventDetailsForUnderlyingReturnValue } }
        set { loadOrFetchEventDetailsForReturnValueLock.withLock { loadOrFetchEventDetailsForUnderlyingReturnValue = newValue } }
    }
    var loadOrFetchEventDetailsForClosure: ((String) async -> Result<TimelineEvent, RoomProxyError>)?

    func loadOrFetchEventDetails(for eventID: String) async -> Result<TimelineEvent, RoomProxyError> {
        loadOrFetchEventDetailsForCallsCountLock.withLock { loadOrFetchEventDetailsForUnderlyingCallsCount += 1 }
        loadOrFetchEventDetailsForReceivedEventID = eventID
        loadOrFetchEventDetailsForReceivedInvocationsLock.withLock { loadOrFetchEventDetailsForUnderlyingReceivedInvocations.append(eventID) }
        if let loadOrFetchEventDetailsForClosure = loadOrFetchEventDetailsForClosure {
            return await loadOrFetchEventDetailsForClosure(eventID)
        } else {
            return loadOrFetchEventDetailsForReturnValue
        }
    }
    //MARK: - messageFilteredTimeline

    private let messageFilteredTimelineFocusAllowedMessageTypesPresentationCallsCountLock = NSLock()
    private var messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingCallsCount = 0
    var messageFilteredTimelineFocusAllowedMessageTypesPresentationCallsCount: Int {
        get { messageFilteredTimelineFocusAllowedMessageTypesPresentationCallsCountLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingCallsCount } }
        set { messageFilteredTimelineFocusAllowedMessageTypesPresentationCallsCountLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingCallsCount = newValue } }
    }
    var messageFilteredTimelineFocusAllowedMessageTypesPresentationCalled: Bool {
        return messageFilteredTimelineFocusAllowedMessageTypesPresentationCallsCount > 0
    }
    private let messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedArgumentsLock = NSLock()
    private var messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedArguments: (focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation)?
    var messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedArguments: (focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation)? {
        get { messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedArgumentsLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedArguments } }
        set { messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedArgumentsLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedArguments = newValue } }
    }
    private let messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedInvocationsLock = NSLock()
    private var messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedInvocations: [(focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation)] = []
    var messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedInvocations: [(focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation)] {
        get { messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedInvocationsLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedInvocations } }
        set { messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedInvocationsLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedInvocations = newValue } }
    }

    private let messageFilteredTimelineFocusAllowedMessageTypesPresentationReturnValueLock = NSLock()
    private var messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReturnValue: Result<TimelineProxyProtocol, RoomProxyError>!
    var messageFilteredTimelineFocusAllowedMessageTypesPresentationReturnValue: Result<TimelineProxyProtocol, RoomProxyError>! {
        get { messageFilteredTimelineFocusAllowedMessageTypesPresentationReturnValueLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReturnValue } }
        set { messageFilteredTimelineFocusAllowedMessageTypesPresentationReturnValueLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReturnValue = newValue } }
    }
    var messageFilteredTimelineFocusAllowedMessageTypesPresentationClosure: ((TimelineFocus, [TimelineAllowedMessageType], TimelineKind.MediaPresentation) async -> Result<TimelineProxyProtocol, RoomProxyError>)?

    func messageFilteredTimeline(focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation) async -> Result<TimelineProxyProtocol, RoomProxyError> {
        messageFilteredTimelineFocusAllowedMessageTypesPresentationCallsCountLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingCallsCount += 1 }
        messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedArguments = (focus: focus, allowedMessageTypes: allowedMessageTypes, presentation: presentation)
        messageFilteredTimelineFocusAllowedMessageTypesPresentationReceivedInvocationsLock.withLock { messageFilteredTimelineFocusAllowedMessageTypesPresentationUnderlyingReceivedInvocations.append((focus: focus, allowedMessageTypes: allowedMessageTypes, presentation: presentation)) }
        if let messageFilteredTimelineFocusAllowedMessageTypesPresentationClosure = messageFilteredTimelineFocusAllowedMessageTypesPresentationClosure {
            return await messageFilteredTimelineFocusAllowedMessageTypesPresentationClosure(focus, allowedMessageTypes, presentation)
        } else {
            return messageFilteredTimelineFocusAllowedMessageTypesPresentationReturnValue
        }
    }
    //MARK: - pinnedEventsTimeline

    private let pinnedEventsTimelineCallsCountLock = NSLock()
    private var pinnedEventsTimelineUnderlyingCallsCount = 0
    var pinnedEventsTimelineCallsCount: Int {
        get { pinnedEventsTimelineCallsCountLock.withLock { pinnedEventsTimelineUnderlyingCallsCount } }
        set { pinnedEventsTimelineCallsCountLock.withLock { pinnedEventsTimelineUnderlyingCallsCount = newValue } }
    }
    var pinnedEventsTimelineCalled: Bool {
        return pinnedEventsTimelineCallsCount > 0
    }

    private let pinnedEventsTimelineReturnValueLock = NSLock()
    private var pinnedEventsTimelineUnderlyingReturnValue: Result<TimelineProxyProtocol, RoomProxyError>!
    var pinnedEventsTimelineReturnValue: Result<TimelineProxyProtocol, RoomProxyError>! {
        get { pinnedEventsTimelineReturnValueLock.withLock { pinnedEventsTimelineUnderlyingReturnValue } }
        set { pinnedEventsTimelineReturnValueLock.withLock { pinnedEventsTimelineUnderlyingReturnValue = newValue } }
    }
    var pinnedEventsTimelineClosure: (() async -> Result<TimelineProxyProtocol, RoomProxyError>)?

    func pinnedEventsTimeline() async -> Result<TimelineProxyProtocol, RoomProxyError> {
        pinnedEventsTimelineCallsCountLock.withLock { pinnedEventsTimelineUnderlyingCallsCount += 1 }
        if let pinnedEventsTimelineClosure = pinnedEventsTimelineClosure {
            return await pinnedEventsTimelineClosure()
        } else {
            return pinnedEventsTimelineReturnValue
        }
    }
    //MARK: - enableEncryption

    private let enableEncryptionCallsCountLock = NSLock()
    private var enableEncryptionUnderlyingCallsCount = 0
    var enableEncryptionCallsCount: Int {
        get { enableEncryptionCallsCountLock.withLock { enableEncryptionUnderlyingCallsCount } }
        set { enableEncryptionCallsCountLock.withLock { enableEncryptionUnderlyingCallsCount = newValue } }
    }
    var enableEncryptionCalled: Bool {
        return enableEncryptionCallsCount > 0
    }

    private let enableEncryptionReturnValueLock = NSLock()
    private var enableEncryptionUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var enableEncryptionReturnValue: Result<Void, RoomProxyError>! {
        get { enableEncryptionReturnValueLock.withLock { enableEncryptionUnderlyingReturnValue } }
        set { enableEncryptionReturnValueLock.withLock { enableEncryptionUnderlyingReturnValue = newValue } }
    }
    var enableEncryptionClosure: (() async -> Result<Void, RoomProxyError>)?

    func enableEncryption() async -> Result<Void, RoomProxyError> {
        enableEncryptionCallsCountLock.withLock { enableEncryptionUnderlyingCallsCount += 1 }
        if let enableEncryptionClosure = enableEncryptionClosure {
            return await enableEncryptionClosure()
        } else {
            return enableEncryptionReturnValue
        }
    }
    //MARK: - redact

    private let redactCallsCountLock = NSLock()
    private var redactUnderlyingCallsCount = 0
    var redactCallsCount: Int {
        get { redactCallsCountLock.withLock { redactUnderlyingCallsCount } }
        set { redactCallsCountLock.withLock { redactUnderlyingCallsCount = newValue } }
    }
    var redactCalled: Bool {
        return redactCallsCount > 0
    }
    private let redactReceivedEventIDLock = NSLock()
    private var redactUnderlyingReceivedEventID: String?
    var redactReceivedEventID: String? {
        get { redactReceivedEventIDLock.withLock { redactUnderlyingReceivedEventID } }
        set { redactReceivedEventIDLock.withLock { redactUnderlyingReceivedEventID = newValue } }
    }
    private let redactReceivedInvocationsLock = NSLock()
    private var redactUnderlyingReceivedInvocations: [String] = []
    var redactReceivedInvocations: [String] {
        get { redactReceivedInvocationsLock.withLock { redactUnderlyingReceivedInvocations } }
        set { redactReceivedInvocationsLock.withLock { redactUnderlyingReceivedInvocations = newValue } }
    }

    private let redactReturnValueLock = NSLock()
    private var redactUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var redactReturnValue: Result<Void, RoomProxyError>! {
        get { redactReturnValueLock.withLock { redactUnderlyingReturnValue } }
        set { redactReturnValueLock.withLock { redactUnderlyingReturnValue = newValue } }
    }
    var redactClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        redactCallsCountLock.withLock { redactUnderlyingCallsCount += 1 }
        redactReceivedEventID = eventID
        redactReceivedInvocationsLock.withLock { redactUnderlyingReceivedInvocations.append(eventID) }
        if let redactClosure = redactClosure {
            return await redactClosure(eventID)
        } else {
            return redactReturnValue
        }
    }
    //MARK: - reportContent

    private let reportContentReasonCallsCountLock = NSLock()
    private var reportContentReasonUnderlyingCallsCount = 0
    var reportContentReasonCallsCount: Int {
        get { reportContentReasonCallsCountLock.withLock { reportContentReasonUnderlyingCallsCount } }
        set { reportContentReasonCallsCountLock.withLock { reportContentReasonUnderlyingCallsCount = newValue } }
    }
    var reportContentReasonCalled: Bool {
        return reportContentReasonCallsCount > 0
    }
    private let reportContentReasonReceivedArgumentsLock = NSLock()
    private var reportContentReasonUnderlyingReceivedArguments: (eventID: String, reason: String?)?
    var reportContentReasonReceivedArguments: (eventID: String, reason: String?)? {
        get { reportContentReasonReceivedArgumentsLock.withLock { reportContentReasonUnderlyingReceivedArguments } }
        set { reportContentReasonReceivedArgumentsLock.withLock { reportContentReasonUnderlyingReceivedArguments = newValue } }
    }
    private let reportContentReasonReceivedInvocationsLock = NSLock()
    private var reportContentReasonUnderlyingReceivedInvocations: [(eventID: String, reason: String?)] = []
    var reportContentReasonReceivedInvocations: [(eventID: String, reason: String?)] {
        get { reportContentReasonReceivedInvocationsLock.withLock { reportContentReasonUnderlyingReceivedInvocations } }
        set { reportContentReasonReceivedInvocationsLock.withLock { reportContentReasonUnderlyingReceivedInvocations = newValue } }
    }

    private let reportContentReasonReturnValueLock = NSLock()
    private var reportContentReasonUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var reportContentReasonReturnValue: Result<Void, RoomProxyError>! {
        get { reportContentReasonReturnValueLock.withLock { reportContentReasonUnderlyingReturnValue } }
        set { reportContentReasonReturnValueLock.withLock { reportContentReasonUnderlyingReturnValue = newValue } }
    }
    var reportContentReasonClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        reportContentReasonCallsCountLock.withLock { reportContentReasonUnderlyingCallsCount += 1 }
        reportContentReasonReceivedArguments = (eventID: eventID, reason: reason)
        reportContentReasonReceivedInvocationsLock.withLock { reportContentReasonUnderlyingReceivedInvocations.append((eventID: eventID, reason: reason)) }
        if let reportContentReasonClosure = reportContentReasonClosure {
            return await reportContentReasonClosure(eventID, reason)
        } else {
            return reportContentReasonReturnValue
        }
    }
    //MARK: - reportRoom

    private let reportRoomReasonCallsCountLock = NSLock()
    private var reportRoomReasonUnderlyingCallsCount = 0
    var reportRoomReasonCallsCount: Int {
        get { reportRoomReasonCallsCountLock.withLock { reportRoomReasonUnderlyingCallsCount } }
        set { reportRoomReasonCallsCountLock.withLock { reportRoomReasonUnderlyingCallsCount = newValue } }
    }
    var reportRoomReasonCalled: Bool {
        return reportRoomReasonCallsCount > 0
    }
    private let reportRoomReasonReceivedReasonLock = NSLock()
    private var reportRoomReasonUnderlyingReceivedReason: String?
    var reportRoomReasonReceivedReason: String? {
        get { reportRoomReasonReceivedReasonLock.withLock { reportRoomReasonUnderlyingReceivedReason } }
        set { reportRoomReasonReceivedReasonLock.withLock { reportRoomReasonUnderlyingReceivedReason = newValue } }
    }
    private let reportRoomReasonReceivedInvocationsLock = NSLock()
    private var reportRoomReasonUnderlyingReceivedInvocations: [String] = []
    var reportRoomReasonReceivedInvocations: [String] {
        get { reportRoomReasonReceivedInvocationsLock.withLock { reportRoomReasonUnderlyingReceivedInvocations } }
        set { reportRoomReasonReceivedInvocationsLock.withLock { reportRoomReasonUnderlyingReceivedInvocations = newValue } }
    }

    private let reportRoomReasonReturnValueLock = NSLock()
    private var reportRoomReasonUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var reportRoomReasonReturnValue: Result<Void, RoomProxyError>! {
        get { reportRoomReasonReturnValueLock.withLock { reportRoomReasonUnderlyingReturnValue } }
        set { reportRoomReasonReturnValueLock.withLock { reportRoomReasonUnderlyingReturnValue = newValue } }
    }
    var reportRoomReasonClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func reportRoom(reason: String) async -> Result<Void, RoomProxyError> {
        reportRoomReasonCallsCountLock.withLock { reportRoomReasonUnderlyingCallsCount += 1 }
        reportRoomReasonReceivedReason = reason
        reportRoomReasonReceivedInvocationsLock.withLock { reportRoomReasonUnderlyingReceivedInvocations.append(reason) }
        if let reportRoomReasonClosure = reportRoomReasonClosure {
            return await reportRoomReasonClosure(reason)
        } else {
            return reportRoomReasonReturnValue
        }
    }
    //MARK: - leaveRoom

    private let leaveRoomCallsCountLock = NSLock()
    private var leaveRoomUnderlyingCallsCount = 0
    var leaveRoomCallsCount: Int {
        get { leaveRoomCallsCountLock.withLock { leaveRoomUnderlyingCallsCount } }
        set { leaveRoomCallsCountLock.withLock { leaveRoomUnderlyingCallsCount = newValue } }
    }
    var leaveRoomCalled: Bool {
        return leaveRoomCallsCount > 0
    }

    private let leaveRoomReturnValueLock = NSLock()
    private var leaveRoomUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var leaveRoomReturnValue: Result<Void, RoomProxyError>! {
        get { leaveRoomReturnValueLock.withLock { leaveRoomUnderlyingReturnValue } }
        set { leaveRoomReturnValueLock.withLock { leaveRoomUnderlyingReturnValue = newValue } }
    }
    var leaveRoomClosure: (() async -> Result<Void, RoomProxyError>)?

    func leaveRoom() async -> Result<Void, RoomProxyError> {
        leaveRoomCallsCountLock.withLock { leaveRoomUnderlyingCallsCount += 1 }
        if let leaveRoomClosure = leaveRoomClosure {
            return await leaveRoomClosure()
        } else {
            return leaveRoomReturnValue
        }
    }
    //MARK: - updateMembers

    private let updateMembersCallsCountLock = NSLock()
    private var updateMembersUnderlyingCallsCount = 0
    var updateMembersCallsCount: Int {
        get { updateMembersCallsCountLock.withLock { updateMembersUnderlyingCallsCount } }
        set { updateMembersCallsCountLock.withLock { updateMembersUnderlyingCallsCount = newValue } }
    }
    var updateMembersCalled: Bool {
        return updateMembersCallsCount > 0
    }
    var updateMembersClosure: (() async -> Void)?

    func updateMembers() async {
        updateMembersCallsCountLock.withLock { updateMembersUnderlyingCallsCount += 1 }
        await updateMembersClosure?()
    }
    //MARK: - getMember

    private let getMemberUserIDCallsCountLock = NSLock()
    private var getMemberUserIDUnderlyingCallsCount = 0
    var getMemberUserIDCallsCount: Int {
        get { getMemberUserIDCallsCountLock.withLock { getMemberUserIDUnderlyingCallsCount } }
        set { getMemberUserIDCallsCountLock.withLock { getMemberUserIDUnderlyingCallsCount = newValue } }
    }
    var getMemberUserIDCalled: Bool {
        return getMemberUserIDCallsCount > 0
    }
    private let getMemberUserIDReceivedUserIDLock = NSLock()
    private var getMemberUserIDUnderlyingReceivedUserID: String?
    var getMemberUserIDReceivedUserID: String? {
        get { getMemberUserIDReceivedUserIDLock.withLock { getMemberUserIDUnderlyingReceivedUserID } }
        set { getMemberUserIDReceivedUserIDLock.withLock { getMemberUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let getMemberUserIDReceivedInvocationsLock = NSLock()
    private var getMemberUserIDUnderlyingReceivedInvocations: [String] = []
    var getMemberUserIDReceivedInvocations: [String] {
        get { getMemberUserIDReceivedInvocationsLock.withLock { getMemberUserIDUnderlyingReceivedInvocations } }
        set { getMemberUserIDReceivedInvocationsLock.withLock { getMemberUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let getMemberUserIDReturnValueLock = NSLock()
    private var getMemberUserIDUnderlyingReturnValue: Result<RoomMemberProxyProtocol, RoomProxyError>!
    var getMemberUserIDReturnValue: Result<RoomMemberProxyProtocol, RoomProxyError>! {
        get { getMemberUserIDReturnValueLock.withLock { getMemberUserIDUnderlyingReturnValue } }
        set { getMemberUserIDReturnValueLock.withLock { getMemberUserIDUnderlyingReturnValue = newValue } }
    }
    var getMemberUserIDClosure: ((String) async -> Result<RoomMemberProxyProtocol, RoomProxyError>)?

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError> {
        getMemberUserIDCallsCountLock.withLock { getMemberUserIDUnderlyingCallsCount += 1 }
        getMemberUserIDReceivedUserID = userID
        getMemberUserIDReceivedInvocationsLock.withLock { getMemberUserIDUnderlyingReceivedInvocations.append(userID) }
        if let getMemberUserIDClosure = getMemberUserIDClosure {
            return await getMemberUserIDClosure(userID)
        } else {
            return getMemberUserIDReturnValue
        }
    }
    //MARK: - invite

    private let inviteUserIDCallsCountLock = NSLock()
    private var inviteUserIDUnderlyingCallsCount = 0
    var inviteUserIDCallsCount: Int {
        get { inviteUserIDCallsCountLock.withLock { inviteUserIDUnderlyingCallsCount } }
        set { inviteUserIDCallsCountLock.withLock { inviteUserIDUnderlyingCallsCount = newValue } }
    }
    var inviteUserIDCalled: Bool {
        return inviteUserIDCallsCount > 0
    }
    private let inviteUserIDReceivedUserIDLock = NSLock()
    private var inviteUserIDUnderlyingReceivedUserID: String?
    var inviteUserIDReceivedUserID: String? {
        get { inviteUserIDReceivedUserIDLock.withLock { inviteUserIDUnderlyingReceivedUserID } }
        set { inviteUserIDReceivedUserIDLock.withLock { inviteUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let inviteUserIDReceivedInvocationsLock = NSLock()
    private var inviteUserIDUnderlyingReceivedInvocations: [String] = []
    var inviteUserIDReceivedInvocations: [String] {
        get { inviteUserIDReceivedInvocationsLock.withLock { inviteUserIDUnderlyingReceivedInvocations } }
        set { inviteUserIDReceivedInvocationsLock.withLock { inviteUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let inviteUserIDReturnValueLock = NSLock()
    private var inviteUserIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var inviteUserIDReturnValue: Result<Void, RoomProxyError>! {
        get { inviteUserIDReturnValueLock.withLock { inviteUserIDUnderlyingReturnValue } }
        set { inviteUserIDReturnValueLock.withLock { inviteUserIDUnderlyingReturnValue = newValue } }
    }
    var inviteUserIDClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func invite(userID: String) async -> Result<Void, RoomProxyError> {
        inviteUserIDCallsCountLock.withLock { inviteUserIDUnderlyingCallsCount += 1 }
        inviteUserIDReceivedUserID = userID
        inviteUserIDReceivedInvocationsLock.withLock { inviteUserIDUnderlyingReceivedInvocations.append(userID) }
        if let inviteUserIDClosure = inviteUserIDClosure {
            return await inviteUserIDClosure(userID)
        } else {
            return inviteUserIDReturnValue
        }
    }
    //MARK: - setName

    private let setNameCallsCountLock = NSLock()
    private var setNameUnderlyingCallsCount = 0
    var setNameCallsCount: Int {
        get { setNameCallsCountLock.withLock { setNameUnderlyingCallsCount } }
        set { setNameCallsCountLock.withLock { setNameUnderlyingCallsCount = newValue } }
    }
    var setNameCalled: Bool {
        return setNameCallsCount > 0
    }
    private let setNameReceivedNameLock = NSLock()
    private var setNameUnderlyingReceivedName: String?
    var setNameReceivedName: String? {
        get { setNameReceivedNameLock.withLock { setNameUnderlyingReceivedName } }
        set { setNameReceivedNameLock.withLock { setNameUnderlyingReceivedName = newValue } }
    }
    private let setNameReceivedInvocationsLock = NSLock()
    private var setNameUnderlyingReceivedInvocations: [String] = []
    var setNameReceivedInvocations: [String] {
        get { setNameReceivedInvocationsLock.withLock { setNameUnderlyingReceivedInvocations } }
        set { setNameReceivedInvocationsLock.withLock { setNameUnderlyingReceivedInvocations = newValue } }
    }

    private let setNameReturnValueLock = NSLock()
    private var setNameUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var setNameReturnValue: Result<Void, RoomProxyError>! {
        get { setNameReturnValueLock.withLock { setNameUnderlyingReturnValue } }
        set { setNameReturnValueLock.withLock { setNameUnderlyingReturnValue = newValue } }
    }
    var setNameClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func setName(_ name: String) async -> Result<Void, RoomProxyError> {
        setNameCallsCountLock.withLock { setNameUnderlyingCallsCount += 1 }
        setNameReceivedName = name
        setNameReceivedInvocationsLock.withLock { setNameUnderlyingReceivedInvocations.append(name) }
        if let setNameClosure = setNameClosure {
            return await setNameClosure(name)
        } else {
            return setNameReturnValue
        }
    }
    //MARK: - setTopic

    private let setTopicCallsCountLock = NSLock()
    private var setTopicUnderlyingCallsCount = 0
    var setTopicCallsCount: Int {
        get { setTopicCallsCountLock.withLock { setTopicUnderlyingCallsCount } }
        set { setTopicCallsCountLock.withLock { setTopicUnderlyingCallsCount = newValue } }
    }
    var setTopicCalled: Bool {
        return setTopicCallsCount > 0
    }
    private let setTopicReceivedTopicLock = NSLock()
    private var setTopicUnderlyingReceivedTopic: String?
    var setTopicReceivedTopic: String? {
        get { setTopicReceivedTopicLock.withLock { setTopicUnderlyingReceivedTopic } }
        set { setTopicReceivedTopicLock.withLock { setTopicUnderlyingReceivedTopic = newValue } }
    }
    private let setTopicReceivedInvocationsLock = NSLock()
    private var setTopicUnderlyingReceivedInvocations: [String] = []
    var setTopicReceivedInvocations: [String] {
        get { setTopicReceivedInvocationsLock.withLock { setTopicUnderlyingReceivedInvocations } }
        set { setTopicReceivedInvocationsLock.withLock { setTopicUnderlyingReceivedInvocations = newValue } }
    }

    private let setTopicReturnValueLock = NSLock()
    private var setTopicUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var setTopicReturnValue: Result<Void, RoomProxyError>! {
        get { setTopicReturnValueLock.withLock { setTopicUnderlyingReturnValue } }
        set { setTopicReturnValueLock.withLock { setTopicUnderlyingReturnValue = newValue } }
    }
    var setTopicClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError> {
        setTopicCallsCountLock.withLock { setTopicUnderlyingCallsCount += 1 }
        setTopicReceivedTopic = topic
        setTopicReceivedInvocationsLock.withLock { setTopicUnderlyingReceivedInvocations.append(topic) }
        if let setTopicClosure = setTopicClosure {
            return await setTopicClosure(topic)
        } else {
            return setTopicReturnValue
        }
    }
    //MARK: - removeAvatar

    private let removeAvatarCallsCountLock = NSLock()
    private var removeAvatarUnderlyingCallsCount = 0
    var removeAvatarCallsCount: Int {
        get { removeAvatarCallsCountLock.withLock { removeAvatarUnderlyingCallsCount } }
        set { removeAvatarCallsCountLock.withLock { removeAvatarUnderlyingCallsCount = newValue } }
    }
    var removeAvatarCalled: Bool {
        return removeAvatarCallsCount > 0
    }

    private let removeAvatarReturnValueLock = NSLock()
    private var removeAvatarUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var removeAvatarReturnValue: Result<Void, RoomProxyError>! {
        get { removeAvatarReturnValueLock.withLock { removeAvatarUnderlyingReturnValue } }
        set { removeAvatarReturnValueLock.withLock { removeAvatarUnderlyingReturnValue = newValue } }
    }
    var removeAvatarClosure: (() async -> Result<Void, RoomProxyError>)?

    func removeAvatar() async -> Result<Void, RoomProxyError> {
        removeAvatarCallsCountLock.withLock { removeAvatarUnderlyingCallsCount += 1 }
        if let removeAvatarClosure = removeAvatarClosure {
            return await removeAvatarClosure()
        } else {
            return removeAvatarReturnValue
        }
    }
    //MARK: - uploadAvatar

    private let uploadAvatarMediaCallsCountLock = NSLock()
    private var uploadAvatarMediaUnderlyingCallsCount = 0
    var uploadAvatarMediaCallsCount: Int {
        get { uploadAvatarMediaCallsCountLock.withLock { uploadAvatarMediaUnderlyingCallsCount } }
        set { uploadAvatarMediaCallsCountLock.withLock { uploadAvatarMediaUnderlyingCallsCount = newValue } }
    }
    var uploadAvatarMediaCalled: Bool {
        return uploadAvatarMediaCallsCount > 0
    }
    private let uploadAvatarMediaReceivedMediaLock = NSLock()
    private var uploadAvatarMediaUnderlyingReceivedMedia: MediaInfo?
    var uploadAvatarMediaReceivedMedia: MediaInfo? {
        get { uploadAvatarMediaReceivedMediaLock.withLock { uploadAvatarMediaUnderlyingReceivedMedia } }
        set { uploadAvatarMediaReceivedMediaLock.withLock { uploadAvatarMediaUnderlyingReceivedMedia = newValue } }
    }
    private let uploadAvatarMediaReceivedInvocationsLock = NSLock()
    private var uploadAvatarMediaUnderlyingReceivedInvocations: [MediaInfo] = []
    var uploadAvatarMediaReceivedInvocations: [MediaInfo] {
        get { uploadAvatarMediaReceivedInvocationsLock.withLock { uploadAvatarMediaUnderlyingReceivedInvocations } }
        set { uploadAvatarMediaReceivedInvocationsLock.withLock { uploadAvatarMediaUnderlyingReceivedInvocations = newValue } }
    }

    private let uploadAvatarMediaReturnValueLock = NSLock()
    private var uploadAvatarMediaUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var uploadAvatarMediaReturnValue: Result<Void, RoomProxyError>! {
        get { uploadAvatarMediaReturnValueLock.withLock { uploadAvatarMediaUnderlyingReturnValue } }
        set { uploadAvatarMediaReturnValueLock.withLock { uploadAvatarMediaUnderlyingReturnValue = newValue } }
    }
    var uploadAvatarMediaClosure: ((MediaInfo) async -> Result<Void, RoomProxyError>)?

    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError> {
        uploadAvatarMediaCallsCountLock.withLock { uploadAvatarMediaUnderlyingCallsCount += 1 }
        uploadAvatarMediaReceivedMedia = media
        uploadAvatarMediaReceivedInvocationsLock.withLock { uploadAvatarMediaUnderlyingReceivedInvocations.append(media) }
        if let uploadAvatarMediaClosure = uploadAvatarMediaClosure {
            return await uploadAvatarMediaClosure(media)
        } else {
            return uploadAvatarMediaReturnValue
        }
    }
    //MARK: - markAsRead

    private let markAsReadReceiptTypeCallsCountLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingCallsCount = 0
    var markAsReadReceiptTypeCallsCount: Int {
        get { markAsReadReceiptTypeCallsCountLock.withLock { markAsReadReceiptTypeUnderlyingCallsCount } }
        set { markAsReadReceiptTypeCallsCountLock.withLock { markAsReadReceiptTypeUnderlyingCallsCount = newValue } }
    }
    var markAsReadReceiptTypeCalled: Bool {
        return markAsReadReceiptTypeCallsCount > 0
    }
    private let markAsReadReceiptTypeReceivedReceiptTypeLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingReceivedReceiptType: ReceiptType?
    var markAsReadReceiptTypeReceivedReceiptType: ReceiptType? {
        get { markAsReadReceiptTypeReceivedReceiptTypeLock.withLock { markAsReadReceiptTypeUnderlyingReceivedReceiptType } }
        set { markAsReadReceiptTypeReceivedReceiptTypeLock.withLock { markAsReadReceiptTypeUnderlyingReceivedReceiptType = newValue } }
    }
    private let markAsReadReceiptTypeReceivedInvocationsLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingReceivedInvocations: [ReceiptType] = []
    var markAsReadReceiptTypeReceivedInvocations: [ReceiptType] {
        get { markAsReadReceiptTypeReceivedInvocationsLock.withLock { markAsReadReceiptTypeUnderlyingReceivedInvocations } }
        set { markAsReadReceiptTypeReceivedInvocationsLock.withLock { markAsReadReceiptTypeUnderlyingReceivedInvocations = newValue } }
    }

    private let markAsReadReceiptTypeReturnValueLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var markAsReadReceiptTypeReturnValue: Result<Void, RoomProxyError>! {
        get { markAsReadReceiptTypeReturnValueLock.withLock { markAsReadReceiptTypeUnderlyingReturnValue } }
        set { markAsReadReceiptTypeReturnValueLock.withLock { markAsReadReceiptTypeUnderlyingReturnValue = newValue } }
    }
    var markAsReadReceiptTypeClosure: ((ReceiptType) async -> Result<Void, RoomProxyError>)?

    func markAsRead(receiptType: ReceiptType) async -> Result<Void, RoomProxyError> {
        markAsReadReceiptTypeCallsCountLock.withLock { markAsReadReceiptTypeUnderlyingCallsCount += 1 }
        markAsReadReceiptTypeReceivedReceiptType = receiptType
        markAsReadReceiptTypeReceivedInvocationsLock.withLock { markAsReadReceiptTypeUnderlyingReceivedInvocations.append(receiptType) }
        if let markAsReadReceiptTypeClosure = markAsReadReceiptTypeClosure {
            return await markAsReadReceiptTypeClosure(receiptType)
        } else {
            return markAsReadReceiptTypeReturnValue
        }
    }
    //MARK: - edit

    private let editEventIDNewContentCallsCountLock = NSLock()
    private var editEventIDNewContentUnderlyingCallsCount = 0
    var editEventIDNewContentCallsCount: Int {
        get { editEventIDNewContentCallsCountLock.withLock { editEventIDNewContentUnderlyingCallsCount } }
        set { editEventIDNewContentCallsCountLock.withLock { editEventIDNewContentUnderlyingCallsCount = newValue } }
    }
    var editEventIDNewContentCalled: Bool {
        return editEventIDNewContentCallsCount > 0
    }
    private let editEventIDNewContentReceivedArgumentsLock = NSLock()
    private var editEventIDNewContentUnderlyingReceivedArguments: (eventID: String, newContent: RoomMessageEventContentWithoutRelation)?
    var editEventIDNewContentReceivedArguments: (eventID: String, newContent: RoomMessageEventContentWithoutRelation)? {
        get { editEventIDNewContentReceivedArgumentsLock.withLock { editEventIDNewContentUnderlyingReceivedArguments } }
        set { editEventIDNewContentReceivedArgumentsLock.withLock { editEventIDNewContentUnderlyingReceivedArguments = newValue } }
    }
    private let editEventIDNewContentReceivedInvocationsLock = NSLock()
    private var editEventIDNewContentUnderlyingReceivedInvocations: [(eventID: String, newContent: RoomMessageEventContentWithoutRelation)] = []
    var editEventIDNewContentReceivedInvocations: [(eventID: String, newContent: RoomMessageEventContentWithoutRelation)] {
        get { editEventIDNewContentReceivedInvocationsLock.withLock { editEventIDNewContentUnderlyingReceivedInvocations } }
        set { editEventIDNewContentReceivedInvocationsLock.withLock { editEventIDNewContentUnderlyingReceivedInvocations = newValue } }
    }

    private let editEventIDNewContentReturnValueLock = NSLock()
    private var editEventIDNewContentUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var editEventIDNewContentReturnValue: Result<Void, RoomProxyError>! {
        get { editEventIDNewContentReturnValueLock.withLock { editEventIDNewContentUnderlyingReturnValue } }
        set { editEventIDNewContentReturnValueLock.withLock { editEventIDNewContentUnderlyingReturnValue = newValue } }
    }
    var editEventIDNewContentClosure: ((String, RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError>)?

    func edit(eventID: String, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError> {
        editEventIDNewContentCallsCountLock.withLock { editEventIDNewContentUnderlyingCallsCount += 1 }
        editEventIDNewContentReceivedArguments = (eventID: eventID, newContent: newContent)
        editEventIDNewContentReceivedInvocationsLock.withLock { editEventIDNewContentUnderlyingReceivedInvocations.append((eventID: eventID, newContent: newContent)) }
        if let editEventIDNewContentClosure = editEventIDNewContentClosure {
            return await editEventIDNewContentClosure(eventID, newContent)
        } else {
            return editEventIDNewContentReturnValue
        }
    }
    //MARK: - sendTypingNotification

    private let sendTypingNotificationIsTypingCallsCountLock = NSLock()
    private var sendTypingNotificationIsTypingUnderlyingCallsCount = 0
    var sendTypingNotificationIsTypingCallsCount: Int {
        get { sendTypingNotificationIsTypingCallsCountLock.withLock { sendTypingNotificationIsTypingUnderlyingCallsCount } }
        set { sendTypingNotificationIsTypingCallsCountLock.withLock { sendTypingNotificationIsTypingUnderlyingCallsCount = newValue } }
    }
    var sendTypingNotificationIsTypingCalled: Bool {
        return sendTypingNotificationIsTypingCallsCount > 0
    }
    private let sendTypingNotificationIsTypingReceivedIsTypingLock = NSLock()
    private var sendTypingNotificationIsTypingUnderlyingReceivedIsTyping: Bool?
    var sendTypingNotificationIsTypingReceivedIsTyping: Bool? {
        get { sendTypingNotificationIsTypingReceivedIsTypingLock.withLock { sendTypingNotificationIsTypingUnderlyingReceivedIsTyping } }
        set { sendTypingNotificationIsTypingReceivedIsTypingLock.withLock { sendTypingNotificationIsTypingUnderlyingReceivedIsTyping = newValue } }
    }
    private let sendTypingNotificationIsTypingReceivedInvocationsLock = NSLock()
    private var sendTypingNotificationIsTypingUnderlyingReceivedInvocations: [Bool] = []
    var sendTypingNotificationIsTypingReceivedInvocations: [Bool] {
        get { sendTypingNotificationIsTypingReceivedInvocationsLock.withLock { sendTypingNotificationIsTypingUnderlyingReceivedInvocations } }
        set { sendTypingNotificationIsTypingReceivedInvocationsLock.withLock { sendTypingNotificationIsTypingUnderlyingReceivedInvocations = newValue } }
    }

    private let sendTypingNotificationIsTypingReturnValueLock = NSLock()
    private var sendTypingNotificationIsTypingUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var sendTypingNotificationIsTypingReturnValue: Result<Void, RoomProxyError>! {
        get { sendTypingNotificationIsTypingReturnValueLock.withLock { sendTypingNotificationIsTypingUnderlyingReturnValue } }
        set { sendTypingNotificationIsTypingReturnValueLock.withLock { sendTypingNotificationIsTypingUnderlyingReturnValue = newValue } }
    }
    var sendTypingNotificationIsTypingClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    @discardableResult
    func sendTypingNotification(isTyping: Bool) async -> Result<Void, RoomProxyError> {
        sendTypingNotificationIsTypingCallsCountLock.withLock { sendTypingNotificationIsTypingUnderlyingCallsCount += 1 }
        sendTypingNotificationIsTypingReceivedIsTyping = isTyping
        sendTypingNotificationIsTypingReceivedInvocationsLock.withLock { sendTypingNotificationIsTypingUnderlyingReceivedInvocations.append(isTyping) }
        if let sendTypingNotificationIsTypingClosure = sendTypingNotificationIsTypingClosure {
            return await sendTypingNotificationIsTypingClosure(isTyping)
        } else {
            return sendTypingNotificationIsTypingReturnValue
        }
    }
    //MARK: - ignoreDeviceTrustAndResend

    private let ignoreDeviceTrustAndResendDevicesSendHandleCallsCountLock = NSLock()
    private var ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingCallsCount = 0
    var ignoreDeviceTrustAndResendDevicesSendHandleCallsCount: Int {
        get { ignoreDeviceTrustAndResendDevicesSendHandleCallsCountLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingCallsCount } }
        set { ignoreDeviceTrustAndResendDevicesSendHandleCallsCountLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingCallsCount = newValue } }
    }
    var ignoreDeviceTrustAndResendDevicesSendHandleCalled: Bool {
        return ignoreDeviceTrustAndResendDevicesSendHandleCallsCount > 0
    }
    private let ignoreDeviceTrustAndResendDevicesSendHandleReceivedArgumentsLock = NSLock()
    private var ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedArguments: (devices: [String: [String]], sendHandle: SendHandleProxy)?
    var ignoreDeviceTrustAndResendDevicesSendHandleReceivedArguments: (devices: [String: [String]], sendHandle: SendHandleProxy)? {
        get { ignoreDeviceTrustAndResendDevicesSendHandleReceivedArgumentsLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedArguments } }
        set { ignoreDeviceTrustAndResendDevicesSendHandleReceivedArgumentsLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedArguments = newValue } }
    }
    private let ignoreDeviceTrustAndResendDevicesSendHandleReceivedInvocationsLock = NSLock()
    private var ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedInvocations: [(devices: [String: [String]], sendHandle: SendHandleProxy)] = []
    var ignoreDeviceTrustAndResendDevicesSendHandleReceivedInvocations: [(devices: [String: [String]], sendHandle: SendHandleProxy)] {
        get { ignoreDeviceTrustAndResendDevicesSendHandleReceivedInvocationsLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedInvocations } }
        set { ignoreDeviceTrustAndResendDevicesSendHandleReceivedInvocationsLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedInvocations = newValue } }
    }

    private let ignoreDeviceTrustAndResendDevicesSendHandleReturnValueLock = NSLock()
    private var ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var ignoreDeviceTrustAndResendDevicesSendHandleReturnValue: Result<Void, RoomProxyError>! {
        get { ignoreDeviceTrustAndResendDevicesSendHandleReturnValueLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReturnValue } }
        set { ignoreDeviceTrustAndResendDevicesSendHandleReturnValueLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReturnValue = newValue } }
    }
    var ignoreDeviceTrustAndResendDevicesSendHandleClosure: (([String: [String]], SendHandleProxy) async -> Result<Void, RoomProxyError>)?

    func ignoreDeviceTrustAndResend(devices: [String: [String]], sendHandle: SendHandleProxy) async -> Result<Void, RoomProxyError> {
        ignoreDeviceTrustAndResendDevicesSendHandleCallsCountLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingCallsCount += 1 }
        ignoreDeviceTrustAndResendDevicesSendHandleReceivedArguments = (devices: devices, sendHandle: sendHandle)
        ignoreDeviceTrustAndResendDevicesSendHandleReceivedInvocationsLock.withLock { ignoreDeviceTrustAndResendDevicesSendHandleUnderlyingReceivedInvocations.append((devices: devices, sendHandle: sendHandle)) }
        if let ignoreDeviceTrustAndResendDevicesSendHandleClosure = ignoreDeviceTrustAndResendDevicesSendHandleClosure {
            return await ignoreDeviceTrustAndResendDevicesSendHandleClosure(devices, sendHandle)
        } else {
            return ignoreDeviceTrustAndResendDevicesSendHandleReturnValue
        }
    }
    //MARK: - withdrawVerificationAndResend

    private let withdrawVerificationAndResendUserIDsSendHandleCallsCountLock = NSLock()
    private var withdrawVerificationAndResendUserIDsSendHandleUnderlyingCallsCount = 0
    var withdrawVerificationAndResendUserIDsSendHandleCallsCount: Int {
        get { withdrawVerificationAndResendUserIDsSendHandleCallsCountLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingCallsCount } }
        set { withdrawVerificationAndResendUserIDsSendHandleCallsCountLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingCallsCount = newValue } }
    }
    var withdrawVerificationAndResendUserIDsSendHandleCalled: Bool {
        return withdrawVerificationAndResendUserIDsSendHandleCallsCount > 0
    }
    private let withdrawVerificationAndResendUserIDsSendHandleReceivedArgumentsLock = NSLock()
    private var withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedArguments: (userIDs: [String], sendHandle: SendHandleProxy)?
    var withdrawVerificationAndResendUserIDsSendHandleReceivedArguments: (userIDs: [String], sendHandle: SendHandleProxy)? {
        get { withdrawVerificationAndResendUserIDsSendHandleReceivedArgumentsLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedArguments } }
        set { withdrawVerificationAndResendUserIDsSendHandleReceivedArgumentsLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedArguments = newValue } }
    }
    private let withdrawVerificationAndResendUserIDsSendHandleReceivedInvocationsLock = NSLock()
    private var withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedInvocations: [(userIDs: [String], sendHandle: SendHandleProxy)] = []
    var withdrawVerificationAndResendUserIDsSendHandleReceivedInvocations: [(userIDs: [String], sendHandle: SendHandleProxy)] {
        get { withdrawVerificationAndResendUserIDsSendHandleReceivedInvocationsLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedInvocations } }
        set { withdrawVerificationAndResendUserIDsSendHandleReceivedInvocationsLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedInvocations = newValue } }
    }

    private let withdrawVerificationAndResendUserIDsSendHandleReturnValueLock = NSLock()
    private var withdrawVerificationAndResendUserIDsSendHandleUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var withdrawVerificationAndResendUserIDsSendHandleReturnValue: Result<Void, RoomProxyError>! {
        get { withdrawVerificationAndResendUserIDsSendHandleReturnValueLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReturnValue } }
        set { withdrawVerificationAndResendUserIDsSendHandleReturnValueLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReturnValue = newValue } }
    }
    var withdrawVerificationAndResendUserIDsSendHandleClosure: (([String], SendHandleProxy) async -> Result<Void, RoomProxyError>)?

    func withdrawVerificationAndResend(userIDs: [String], sendHandle: SendHandleProxy) async -> Result<Void, RoomProxyError> {
        withdrawVerificationAndResendUserIDsSendHandleCallsCountLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingCallsCount += 1 }
        withdrawVerificationAndResendUserIDsSendHandleReceivedArguments = (userIDs: userIDs, sendHandle: sendHandle)
        withdrawVerificationAndResendUserIDsSendHandleReceivedInvocationsLock.withLock { withdrawVerificationAndResendUserIDsSendHandleUnderlyingReceivedInvocations.append((userIDs: userIDs, sendHandle: sendHandle)) }
        if let withdrawVerificationAndResendUserIDsSendHandleClosure = withdrawVerificationAndResendUserIDsSendHandleClosure {
            return await withdrawVerificationAndResendUserIDsSendHandleClosure(userIDs, sendHandle)
        } else {
            return withdrawVerificationAndResendUserIDsSendHandleReturnValue
        }
    }
    //MARK: - updateJoinRule

    private let updateJoinRuleCallsCountLock = NSLock()
    private var updateJoinRuleUnderlyingCallsCount = 0
    var updateJoinRuleCallsCount: Int {
        get { updateJoinRuleCallsCountLock.withLock { updateJoinRuleUnderlyingCallsCount } }
        set { updateJoinRuleCallsCountLock.withLock { updateJoinRuleUnderlyingCallsCount = newValue } }
    }
    var updateJoinRuleCalled: Bool {
        return updateJoinRuleCallsCount > 0
    }
    private let updateJoinRuleReceivedRuleLock = NSLock()
    private var updateJoinRuleUnderlyingReceivedRule: JoinRule?
    var updateJoinRuleReceivedRule: JoinRule? {
        get { updateJoinRuleReceivedRuleLock.withLock { updateJoinRuleUnderlyingReceivedRule } }
        set { updateJoinRuleReceivedRuleLock.withLock { updateJoinRuleUnderlyingReceivedRule = newValue } }
    }
    private let updateJoinRuleReceivedInvocationsLock = NSLock()
    private var updateJoinRuleUnderlyingReceivedInvocations: [JoinRule] = []
    var updateJoinRuleReceivedInvocations: [JoinRule] {
        get { updateJoinRuleReceivedInvocationsLock.withLock { updateJoinRuleUnderlyingReceivedInvocations } }
        set { updateJoinRuleReceivedInvocationsLock.withLock { updateJoinRuleUnderlyingReceivedInvocations = newValue } }
    }

    private let updateJoinRuleReturnValueLock = NSLock()
    private var updateJoinRuleUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var updateJoinRuleReturnValue: Result<Void, RoomProxyError>! {
        get { updateJoinRuleReturnValueLock.withLock { updateJoinRuleUnderlyingReturnValue } }
        set { updateJoinRuleReturnValueLock.withLock { updateJoinRuleUnderlyingReturnValue = newValue } }
    }
    var updateJoinRuleClosure: ((JoinRule) async -> Result<Void, RoomProxyError>)?

    func updateJoinRule(_ rule: JoinRule) async -> Result<Void, RoomProxyError> {
        updateJoinRuleCallsCountLock.withLock { updateJoinRuleUnderlyingCallsCount += 1 }
        updateJoinRuleReceivedRule = rule
        updateJoinRuleReceivedInvocationsLock.withLock { updateJoinRuleUnderlyingReceivedInvocations.append(rule) }
        if let updateJoinRuleClosure = updateJoinRuleClosure {
            return await updateJoinRuleClosure(rule)
        } else {
            return updateJoinRuleReturnValue
        }
    }
    //MARK: - updateHistoryVisibility

    private let updateHistoryVisibilityCallsCountLock = NSLock()
    private var updateHistoryVisibilityUnderlyingCallsCount = 0
    var updateHistoryVisibilityCallsCount: Int {
        get { updateHistoryVisibilityCallsCountLock.withLock { updateHistoryVisibilityUnderlyingCallsCount } }
        set { updateHistoryVisibilityCallsCountLock.withLock { updateHistoryVisibilityUnderlyingCallsCount = newValue } }
    }
    var updateHistoryVisibilityCalled: Bool {
        return updateHistoryVisibilityCallsCount > 0
    }
    private let updateHistoryVisibilityReceivedVisibilityLock = NSLock()
    private var updateHistoryVisibilityUnderlyingReceivedVisibility: RoomHistoryVisibility?
    var updateHistoryVisibilityReceivedVisibility: RoomHistoryVisibility? {
        get { updateHistoryVisibilityReceivedVisibilityLock.withLock { updateHistoryVisibilityUnderlyingReceivedVisibility } }
        set { updateHistoryVisibilityReceivedVisibilityLock.withLock { updateHistoryVisibilityUnderlyingReceivedVisibility = newValue } }
    }
    private let updateHistoryVisibilityReceivedInvocationsLock = NSLock()
    private var updateHistoryVisibilityUnderlyingReceivedInvocations: [RoomHistoryVisibility] = []
    var updateHistoryVisibilityReceivedInvocations: [RoomHistoryVisibility] {
        get { updateHistoryVisibilityReceivedInvocationsLock.withLock { updateHistoryVisibilityUnderlyingReceivedInvocations } }
        set { updateHistoryVisibilityReceivedInvocationsLock.withLock { updateHistoryVisibilityUnderlyingReceivedInvocations = newValue } }
    }

    private let updateHistoryVisibilityReturnValueLock = NSLock()
    private var updateHistoryVisibilityUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var updateHistoryVisibilityReturnValue: Result<Void, RoomProxyError>! {
        get { updateHistoryVisibilityReturnValueLock.withLock { updateHistoryVisibilityUnderlyingReturnValue } }
        set { updateHistoryVisibilityReturnValueLock.withLock { updateHistoryVisibilityUnderlyingReturnValue = newValue } }
    }
    var updateHistoryVisibilityClosure: ((RoomHistoryVisibility) async -> Result<Void, RoomProxyError>)?

    func updateHistoryVisibility(_ visibility: RoomHistoryVisibility) async -> Result<Void, RoomProxyError> {
        updateHistoryVisibilityCallsCountLock.withLock { updateHistoryVisibilityUnderlyingCallsCount += 1 }
        updateHistoryVisibilityReceivedVisibility = visibility
        updateHistoryVisibilityReceivedInvocationsLock.withLock { updateHistoryVisibilityUnderlyingReceivedInvocations.append(visibility) }
        if let updateHistoryVisibilityClosure = updateHistoryVisibilityClosure {
            return await updateHistoryVisibilityClosure(visibility)
        } else {
            return updateHistoryVisibilityReturnValue
        }
    }
    //MARK: - isVisibleInRoomDirectory

    private let isVisibleInRoomDirectoryCallsCountLock = NSLock()
    private var isVisibleInRoomDirectoryUnderlyingCallsCount = 0
    var isVisibleInRoomDirectoryCallsCount: Int {
        get { isVisibleInRoomDirectoryCallsCountLock.withLock { isVisibleInRoomDirectoryUnderlyingCallsCount } }
        set { isVisibleInRoomDirectoryCallsCountLock.withLock { isVisibleInRoomDirectoryUnderlyingCallsCount = newValue } }
    }
    var isVisibleInRoomDirectoryCalled: Bool {
        return isVisibleInRoomDirectoryCallsCount > 0
    }

    private let isVisibleInRoomDirectoryReturnValueLock = NSLock()
    private var isVisibleInRoomDirectoryUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var isVisibleInRoomDirectoryReturnValue: Result<Bool, RoomProxyError>! {
        get { isVisibleInRoomDirectoryReturnValueLock.withLock { isVisibleInRoomDirectoryUnderlyingReturnValue } }
        set { isVisibleInRoomDirectoryReturnValueLock.withLock { isVisibleInRoomDirectoryUnderlyingReturnValue = newValue } }
    }
    var isVisibleInRoomDirectoryClosure: (() async -> Result<Bool, RoomProxyError>)?

    func isVisibleInRoomDirectory() async -> Result<Bool, RoomProxyError> {
        isVisibleInRoomDirectoryCallsCountLock.withLock { isVisibleInRoomDirectoryUnderlyingCallsCount += 1 }
        if let isVisibleInRoomDirectoryClosure = isVisibleInRoomDirectoryClosure {
            return await isVisibleInRoomDirectoryClosure()
        } else {
            return isVisibleInRoomDirectoryReturnValue
        }
    }
    //MARK: - updateRoomDirectoryVisibility

    private let updateRoomDirectoryVisibilityCallsCountLock = NSLock()
    private var updateRoomDirectoryVisibilityUnderlyingCallsCount = 0
    var updateRoomDirectoryVisibilityCallsCount: Int {
        get { updateRoomDirectoryVisibilityCallsCountLock.withLock { updateRoomDirectoryVisibilityUnderlyingCallsCount } }
        set { updateRoomDirectoryVisibilityCallsCountLock.withLock { updateRoomDirectoryVisibilityUnderlyingCallsCount = newValue } }
    }
    var updateRoomDirectoryVisibilityCalled: Bool {
        return updateRoomDirectoryVisibilityCallsCount > 0
    }
    private let updateRoomDirectoryVisibilityReceivedVisibilityLock = NSLock()
    private var updateRoomDirectoryVisibilityUnderlyingReceivedVisibility: RoomVisibility?
    var updateRoomDirectoryVisibilityReceivedVisibility: RoomVisibility? {
        get { updateRoomDirectoryVisibilityReceivedVisibilityLock.withLock { updateRoomDirectoryVisibilityUnderlyingReceivedVisibility } }
        set { updateRoomDirectoryVisibilityReceivedVisibilityLock.withLock { updateRoomDirectoryVisibilityUnderlyingReceivedVisibility = newValue } }
    }
    private let updateRoomDirectoryVisibilityReceivedInvocationsLock = NSLock()
    private var updateRoomDirectoryVisibilityUnderlyingReceivedInvocations: [RoomVisibility] = []
    var updateRoomDirectoryVisibilityReceivedInvocations: [RoomVisibility] {
        get { updateRoomDirectoryVisibilityReceivedInvocationsLock.withLock { updateRoomDirectoryVisibilityUnderlyingReceivedInvocations } }
        set { updateRoomDirectoryVisibilityReceivedInvocationsLock.withLock { updateRoomDirectoryVisibilityUnderlyingReceivedInvocations = newValue } }
    }

    private let updateRoomDirectoryVisibilityReturnValueLock = NSLock()
    private var updateRoomDirectoryVisibilityUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var updateRoomDirectoryVisibilityReturnValue: Result<Void, RoomProxyError>! {
        get { updateRoomDirectoryVisibilityReturnValueLock.withLock { updateRoomDirectoryVisibilityUnderlyingReturnValue } }
        set { updateRoomDirectoryVisibilityReturnValueLock.withLock { updateRoomDirectoryVisibilityUnderlyingReturnValue = newValue } }
    }
    var updateRoomDirectoryVisibilityClosure: ((RoomVisibility) async -> Result<Void, RoomProxyError>)?

    func updateRoomDirectoryVisibility(_ visibility: RoomVisibility) async -> Result<Void, RoomProxyError> {
        updateRoomDirectoryVisibilityCallsCountLock.withLock { updateRoomDirectoryVisibilityUnderlyingCallsCount += 1 }
        updateRoomDirectoryVisibilityReceivedVisibility = visibility
        updateRoomDirectoryVisibilityReceivedInvocationsLock.withLock { updateRoomDirectoryVisibilityUnderlyingReceivedInvocations.append(visibility) }
        if let updateRoomDirectoryVisibilityClosure = updateRoomDirectoryVisibilityClosure {
            return await updateRoomDirectoryVisibilityClosure(visibility)
        } else {
            return updateRoomDirectoryVisibilityReturnValue
        }
    }
    //MARK: - updateCanonicalAlias

    private let updateCanonicalAliasAltAliasesCallsCountLock = NSLock()
    private var updateCanonicalAliasAltAliasesUnderlyingCallsCount = 0
    var updateCanonicalAliasAltAliasesCallsCount: Int {
        get { updateCanonicalAliasAltAliasesCallsCountLock.withLock { updateCanonicalAliasAltAliasesUnderlyingCallsCount } }
        set { updateCanonicalAliasAltAliasesCallsCountLock.withLock { updateCanonicalAliasAltAliasesUnderlyingCallsCount = newValue } }
    }
    var updateCanonicalAliasAltAliasesCalled: Bool {
        return updateCanonicalAliasAltAliasesCallsCount > 0
    }
    private let updateCanonicalAliasAltAliasesReceivedArgumentsLock = NSLock()
    private var updateCanonicalAliasAltAliasesUnderlyingReceivedArguments: (alias: String?, altAliases: [String])?
    var updateCanonicalAliasAltAliasesReceivedArguments: (alias: String?, altAliases: [String])? {
        get { updateCanonicalAliasAltAliasesReceivedArgumentsLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReceivedArguments } }
        set { updateCanonicalAliasAltAliasesReceivedArgumentsLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReceivedArguments = newValue } }
    }
    private let updateCanonicalAliasAltAliasesReceivedInvocationsLock = NSLock()
    private var updateCanonicalAliasAltAliasesUnderlyingReceivedInvocations: [(alias: String?, altAliases: [String])] = []
    var updateCanonicalAliasAltAliasesReceivedInvocations: [(alias: String?, altAliases: [String])] {
        get { updateCanonicalAliasAltAliasesReceivedInvocationsLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReceivedInvocations } }
        set { updateCanonicalAliasAltAliasesReceivedInvocationsLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReceivedInvocations = newValue } }
    }

    private let updateCanonicalAliasAltAliasesReturnValueLock = NSLock()
    private var updateCanonicalAliasAltAliasesUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var updateCanonicalAliasAltAliasesReturnValue: Result<Void, RoomProxyError>! {
        get { updateCanonicalAliasAltAliasesReturnValueLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReturnValue } }
        set { updateCanonicalAliasAltAliasesReturnValueLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReturnValue = newValue } }
    }
    var updateCanonicalAliasAltAliasesClosure: ((String?, [String]) async -> Result<Void, RoomProxyError>)?

    func updateCanonicalAlias(_ alias: String?, altAliases: [String]) async -> Result<Void, RoomProxyError> {
        updateCanonicalAliasAltAliasesCallsCountLock.withLock { updateCanonicalAliasAltAliasesUnderlyingCallsCount += 1 }
        updateCanonicalAliasAltAliasesReceivedArguments = (alias: alias, altAliases: altAliases)
        updateCanonicalAliasAltAliasesReceivedInvocationsLock.withLock { updateCanonicalAliasAltAliasesUnderlyingReceivedInvocations.append((alias: alias, altAliases: altAliases)) }
        if let updateCanonicalAliasAltAliasesClosure = updateCanonicalAliasAltAliasesClosure {
            return await updateCanonicalAliasAltAliasesClosure(alias, altAliases)
        } else {
            return updateCanonicalAliasAltAliasesReturnValue
        }
    }
    //MARK: - publishRoomAliasInRoomDirectory

    private let publishRoomAliasInRoomDirectoryCallsCountLock = NSLock()
    private var publishRoomAliasInRoomDirectoryUnderlyingCallsCount = 0
    var publishRoomAliasInRoomDirectoryCallsCount: Int {
        get { publishRoomAliasInRoomDirectoryCallsCountLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingCallsCount } }
        set { publishRoomAliasInRoomDirectoryCallsCountLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingCallsCount = newValue } }
    }
    var publishRoomAliasInRoomDirectoryCalled: Bool {
        return publishRoomAliasInRoomDirectoryCallsCount > 0
    }
    private let publishRoomAliasInRoomDirectoryReceivedAliasLock = NSLock()
    private var publishRoomAliasInRoomDirectoryUnderlyingReceivedAlias: String?
    var publishRoomAliasInRoomDirectoryReceivedAlias: String? {
        get { publishRoomAliasInRoomDirectoryReceivedAliasLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReceivedAlias } }
        set { publishRoomAliasInRoomDirectoryReceivedAliasLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReceivedAlias = newValue } }
    }
    private let publishRoomAliasInRoomDirectoryReceivedInvocationsLock = NSLock()
    private var publishRoomAliasInRoomDirectoryUnderlyingReceivedInvocations: [String] = []
    var publishRoomAliasInRoomDirectoryReceivedInvocations: [String] {
        get { publishRoomAliasInRoomDirectoryReceivedInvocationsLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReceivedInvocations } }
        set { publishRoomAliasInRoomDirectoryReceivedInvocationsLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReceivedInvocations = newValue } }
    }

    private let publishRoomAliasInRoomDirectoryReturnValueLock = NSLock()
    private var publishRoomAliasInRoomDirectoryUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var publishRoomAliasInRoomDirectoryReturnValue: Result<Bool, RoomProxyError>! {
        get { publishRoomAliasInRoomDirectoryReturnValueLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReturnValue } }
        set { publishRoomAliasInRoomDirectoryReturnValueLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReturnValue = newValue } }
    }
    var publishRoomAliasInRoomDirectoryClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func publishRoomAliasInRoomDirectory(_ alias: String) async -> Result<Bool, RoomProxyError> {
        publishRoomAliasInRoomDirectoryCallsCountLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingCallsCount += 1 }
        publishRoomAliasInRoomDirectoryReceivedAlias = alias
        publishRoomAliasInRoomDirectoryReceivedInvocationsLock.withLock { publishRoomAliasInRoomDirectoryUnderlyingReceivedInvocations.append(alias) }
        if let publishRoomAliasInRoomDirectoryClosure = publishRoomAliasInRoomDirectoryClosure {
            return await publishRoomAliasInRoomDirectoryClosure(alias)
        } else {
            return publishRoomAliasInRoomDirectoryReturnValue
        }
    }
    //MARK: - removeRoomAliasFromRoomDirectory

    private let removeRoomAliasFromRoomDirectoryCallsCountLock = NSLock()
    private var removeRoomAliasFromRoomDirectoryUnderlyingCallsCount = 0
    var removeRoomAliasFromRoomDirectoryCallsCount: Int {
        get { removeRoomAliasFromRoomDirectoryCallsCountLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingCallsCount } }
        set { removeRoomAliasFromRoomDirectoryCallsCountLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingCallsCount = newValue } }
    }
    var removeRoomAliasFromRoomDirectoryCalled: Bool {
        return removeRoomAliasFromRoomDirectoryCallsCount > 0
    }
    private let removeRoomAliasFromRoomDirectoryReceivedAliasLock = NSLock()
    private var removeRoomAliasFromRoomDirectoryUnderlyingReceivedAlias: String?
    var removeRoomAliasFromRoomDirectoryReceivedAlias: String? {
        get { removeRoomAliasFromRoomDirectoryReceivedAliasLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReceivedAlias } }
        set { removeRoomAliasFromRoomDirectoryReceivedAliasLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReceivedAlias = newValue } }
    }
    private let removeRoomAliasFromRoomDirectoryReceivedInvocationsLock = NSLock()
    private var removeRoomAliasFromRoomDirectoryUnderlyingReceivedInvocations: [String] = []
    var removeRoomAliasFromRoomDirectoryReceivedInvocations: [String] {
        get { removeRoomAliasFromRoomDirectoryReceivedInvocationsLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReceivedInvocations } }
        set { removeRoomAliasFromRoomDirectoryReceivedInvocationsLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReceivedInvocations = newValue } }
    }

    private let removeRoomAliasFromRoomDirectoryReturnValueLock = NSLock()
    private var removeRoomAliasFromRoomDirectoryUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var removeRoomAliasFromRoomDirectoryReturnValue: Result<Bool, RoomProxyError>! {
        get { removeRoomAliasFromRoomDirectoryReturnValueLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReturnValue } }
        set { removeRoomAliasFromRoomDirectoryReturnValueLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReturnValue = newValue } }
    }
    var removeRoomAliasFromRoomDirectoryClosure: ((String) async -> Result<Bool, RoomProxyError>)?

    func removeRoomAliasFromRoomDirectory(_ alias: String) async -> Result<Bool, RoomProxyError> {
        removeRoomAliasFromRoomDirectoryCallsCountLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingCallsCount += 1 }
        removeRoomAliasFromRoomDirectoryReceivedAlias = alias
        removeRoomAliasFromRoomDirectoryReceivedInvocationsLock.withLock { removeRoomAliasFromRoomDirectoryUnderlyingReceivedInvocations.append(alias) }
        if let removeRoomAliasFromRoomDirectoryClosure = removeRoomAliasFromRoomDirectoryClosure {
            return await removeRoomAliasFromRoomDirectoryClosure(alias)
        } else {
            return removeRoomAliasFromRoomDirectoryReturnValue
        }
    }
    //MARK: - flagAsUnread

    private let flagAsUnreadCallsCountLock = NSLock()
    private var flagAsUnreadUnderlyingCallsCount = 0
    var flagAsUnreadCallsCount: Int {
        get { flagAsUnreadCallsCountLock.withLock { flagAsUnreadUnderlyingCallsCount } }
        set { flagAsUnreadCallsCountLock.withLock { flagAsUnreadUnderlyingCallsCount = newValue } }
    }
    var flagAsUnreadCalled: Bool {
        return flagAsUnreadCallsCount > 0
    }
    private let flagAsUnreadReceivedIsUnreadLock = NSLock()
    private var flagAsUnreadUnderlyingReceivedIsUnread: Bool?
    var flagAsUnreadReceivedIsUnread: Bool? {
        get { flagAsUnreadReceivedIsUnreadLock.withLock { flagAsUnreadUnderlyingReceivedIsUnread } }
        set { flagAsUnreadReceivedIsUnreadLock.withLock { flagAsUnreadUnderlyingReceivedIsUnread = newValue } }
    }
    private let flagAsUnreadReceivedInvocationsLock = NSLock()
    private var flagAsUnreadUnderlyingReceivedInvocations: [Bool] = []
    var flagAsUnreadReceivedInvocations: [Bool] {
        get { flagAsUnreadReceivedInvocationsLock.withLock { flagAsUnreadUnderlyingReceivedInvocations } }
        set { flagAsUnreadReceivedInvocationsLock.withLock { flagAsUnreadUnderlyingReceivedInvocations = newValue } }
    }

    private let flagAsUnreadReturnValueLock = NSLock()
    private var flagAsUnreadUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var flagAsUnreadReturnValue: Result<Void, RoomProxyError>! {
        get { flagAsUnreadReturnValueLock.withLock { flagAsUnreadUnderlyingReturnValue } }
        set { flagAsUnreadReturnValueLock.withLock { flagAsUnreadUnderlyingReturnValue = newValue } }
    }
    var flagAsUnreadClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    func flagAsUnread(_ isUnread: Bool) async -> Result<Void, RoomProxyError> {
        flagAsUnreadCallsCountLock.withLock { flagAsUnreadUnderlyingCallsCount += 1 }
        flagAsUnreadReceivedIsUnread = isUnread
        flagAsUnreadReceivedInvocationsLock.withLock { flagAsUnreadUnderlyingReceivedInvocations.append(isUnread) }
        if let flagAsUnreadClosure = flagAsUnreadClosure {
            return await flagAsUnreadClosure(isUnread)
        } else {
            return flagAsUnreadReturnValue
        }
    }
    //MARK: - flagAsFavourite

    private let flagAsFavouriteCallsCountLock = NSLock()
    private var flagAsFavouriteUnderlyingCallsCount = 0
    var flagAsFavouriteCallsCount: Int {
        get { flagAsFavouriteCallsCountLock.withLock { flagAsFavouriteUnderlyingCallsCount } }
        set { flagAsFavouriteCallsCountLock.withLock { flagAsFavouriteUnderlyingCallsCount = newValue } }
    }
    var flagAsFavouriteCalled: Bool {
        return flagAsFavouriteCallsCount > 0
    }
    private let flagAsFavouriteReceivedIsFavouriteLock = NSLock()
    private var flagAsFavouriteUnderlyingReceivedIsFavourite: Bool?
    var flagAsFavouriteReceivedIsFavourite: Bool? {
        get { flagAsFavouriteReceivedIsFavouriteLock.withLock { flagAsFavouriteUnderlyingReceivedIsFavourite } }
        set { flagAsFavouriteReceivedIsFavouriteLock.withLock { flagAsFavouriteUnderlyingReceivedIsFavourite = newValue } }
    }
    private let flagAsFavouriteReceivedInvocationsLock = NSLock()
    private var flagAsFavouriteUnderlyingReceivedInvocations: [Bool] = []
    var flagAsFavouriteReceivedInvocations: [Bool] {
        get { flagAsFavouriteReceivedInvocationsLock.withLock { flagAsFavouriteUnderlyingReceivedInvocations } }
        set { flagAsFavouriteReceivedInvocationsLock.withLock { flagAsFavouriteUnderlyingReceivedInvocations = newValue } }
    }

    private let flagAsFavouriteReturnValueLock = NSLock()
    private var flagAsFavouriteUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var flagAsFavouriteReturnValue: Result<Void, RoomProxyError>! {
        get { flagAsFavouriteReturnValueLock.withLock { flagAsFavouriteUnderlyingReturnValue } }
        set { flagAsFavouriteReturnValueLock.withLock { flagAsFavouriteUnderlyingReturnValue = newValue } }
    }
    var flagAsFavouriteClosure: ((Bool) async -> Result<Void, RoomProxyError>)?

    func flagAsFavourite(_ isFavourite: Bool) async -> Result<Void, RoomProxyError> {
        flagAsFavouriteCallsCountLock.withLock { flagAsFavouriteUnderlyingCallsCount += 1 }
        flagAsFavouriteReceivedIsFavourite = isFavourite
        flagAsFavouriteReceivedInvocationsLock.withLock { flagAsFavouriteUnderlyingReceivedInvocations.append(isFavourite) }
        if let flagAsFavouriteClosure = flagAsFavouriteClosure {
            return await flagAsFavouriteClosure(isFavourite)
        } else {
            return flagAsFavouriteReturnValue
        }
    }
    //MARK: - powerLevels

    private let powerLevelsCallsCountLock = NSLock()
    private var powerLevelsUnderlyingCallsCount = 0
    var powerLevelsCallsCount: Int {
        get { powerLevelsCallsCountLock.withLock { powerLevelsUnderlyingCallsCount } }
        set { powerLevelsCallsCountLock.withLock { powerLevelsUnderlyingCallsCount = newValue } }
    }
    var powerLevelsCalled: Bool {
        return powerLevelsCallsCount > 0
    }

    private let powerLevelsReturnValueLock = NSLock()
    private var powerLevelsUnderlyingReturnValue: Result<RoomPowerLevelsProxyProtocol?, RoomProxyError>!
    var powerLevelsReturnValue: Result<RoomPowerLevelsProxyProtocol?, RoomProxyError>! {
        get { powerLevelsReturnValueLock.withLock { powerLevelsUnderlyingReturnValue } }
        set { powerLevelsReturnValueLock.withLock { powerLevelsUnderlyingReturnValue = newValue } }
    }
    var powerLevelsClosure: (() async -> Result<RoomPowerLevelsProxyProtocol?, RoomProxyError>)?

    func powerLevels() async -> Result<RoomPowerLevelsProxyProtocol?, RoomProxyError> {
        powerLevelsCallsCountLock.withLock { powerLevelsUnderlyingCallsCount += 1 }
        if let powerLevelsClosure = powerLevelsClosure {
            return await powerLevelsClosure()
        } else {
            return powerLevelsReturnValue
        }
    }
    //MARK: - applyPowerLevelChanges

    private let applyPowerLevelChangesCallsCountLock = NSLock()
    private var applyPowerLevelChangesUnderlyingCallsCount = 0
    var applyPowerLevelChangesCallsCount: Int {
        get { applyPowerLevelChangesCallsCountLock.withLock { applyPowerLevelChangesUnderlyingCallsCount } }
        set { applyPowerLevelChangesCallsCountLock.withLock { applyPowerLevelChangesUnderlyingCallsCount = newValue } }
    }
    var applyPowerLevelChangesCalled: Bool {
        return applyPowerLevelChangesCallsCount > 0
    }
    private let applyPowerLevelChangesReceivedChangesLock = NSLock()
    private var applyPowerLevelChangesUnderlyingReceivedChanges: RoomPowerLevelChanges?
    var applyPowerLevelChangesReceivedChanges: RoomPowerLevelChanges? {
        get { applyPowerLevelChangesReceivedChangesLock.withLock { applyPowerLevelChangesUnderlyingReceivedChanges } }
        set { applyPowerLevelChangesReceivedChangesLock.withLock { applyPowerLevelChangesUnderlyingReceivedChanges = newValue } }
    }
    private let applyPowerLevelChangesReceivedInvocationsLock = NSLock()
    private var applyPowerLevelChangesUnderlyingReceivedInvocations: [RoomPowerLevelChanges] = []
    var applyPowerLevelChangesReceivedInvocations: [RoomPowerLevelChanges] {
        get { applyPowerLevelChangesReceivedInvocationsLock.withLock { applyPowerLevelChangesUnderlyingReceivedInvocations } }
        set { applyPowerLevelChangesReceivedInvocationsLock.withLock { applyPowerLevelChangesUnderlyingReceivedInvocations = newValue } }
    }

    private let applyPowerLevelChangesReturnValueLock = NSLock()
    private var applyPowerLevelChangesUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var applyPowerLevelChangesReturnValue: Result<Void, RoomProxyError>! {
        get { applyPowerLevelChangesReturnValueLock.withLock { applyPowerLevelChangesUnderlyingReturnValue } }
        set { applyPowerLevelChangesReturnValueLock.withLock { applyPowerLevelChangesUnderlyingReturnValue = newValue } }
    }
    var applyPowerLevelChangesClosure: ((RoomPowerLevelChanges) async -> Result<Void, RoomProxyError>)?

    func applyPowerLevelChanges(_ changes: RoomPowerLevelChanges) async -> Result<Void, RoomProxyError> {
        applyPowerLevelChangesCallsCountLock.withLock { applyPowerLevelChangesUnderlyingCallsCount += 1 }
        applyPowerLevelChangesReceivedChanges = changes
        applyPowerLevelChangesReceivedInvocationsLock.withLock { applyPowerLevelChangesUnderlyingReceivedInvocations.append(changes) }
        if let applyPowerLevelChangesClosure = applyPowerLevelChangesClosure {
            return await applyPowerLevelChangesClosure(changes)
        } else {
            return applyPowerLevelChangesReturnValue
        }
    }
    //MARK: - resetPowerLevels

    private let resetPowerLevelsCallsCountLock = NSLock()
    private var resetPowerLevelsUnderlyingCallsCount = 0
    var resetPowerLevelsCallsCount: Int {
        get { resetPowerLevelsCallsCountLock.withLock { resetPowerLevelsUnderlyingCallsCount } }
        set { resetPowerLevelsCallsCountLock.withLock { resetPowerLevelsUnderlyingCallsCount = newValue } }
    }
    var resetPowerLevelsCalled: Bool {
        return resetPowerLevelsCallsCount > 0
    }

    private let resetPowerLevelsReturnValueLock = NSLock()
    private var resetPowerLevelsUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var resetPowerLevelsReturnValue: Result<Void, RoomProxyError>! {
        get { resetPowerLevelsReturnValueLock.withLock { resetPowerLevelsUnderlyingReturnValue } }
        set { resetPowerLevelsReturnValueLock.withLock { resetPowerLevelsUnderlyingReturnValue = newValue } }
    }
    var resetPowerLevelsClosure: (() async -> Result<Void, RoomProxyError>)?

    func resetPowerLevels() async -> Result<Void, RoomProxyError> {
        resetPowerLevelsCallsCountLock.withLock { resetPowerLevelsUnderlyingCallsCount += 1 }
        if let resetPowerLevelsClosure = resetPowerLevelsClosure {
            return await resetPowerLevelsClosure()
        } else {
            return resetPowerLevelsReturnValue
        }
    }
    //MARK: - suggestedRole

    private let suggestedRoleForCallsCountLock = NSLock()
    private var suggestedRoleForUnderlyingCallsCount = 0
    var suggestedRoleForCallsCount: Int {
        get { suggestedRoleForCallsCountLock.withLock { suggestedRoleForUnderlyingCallsCount } }
        set { suggestedRoleForCallsCountLock.withLock { suggestedRoleForUnderlyingCallsCount = newValue } }
    }
    var suggestedRoleForCalled: Bool {
        return suggestedRoleForCallsCount > 0
    }
    private let suggestedRoleForReceivedUserIDLock = NSLock()
    private var suggestedRoleForUnderlyingReceivedUserID: String?
    var suggestedRoleForReceivedUserID: String? {
        get { suggestedRoleForReceivedUserIDLock.withLock { suggestedRoleForUnderlyingReceivedUserID } }
        set { suggestedRoleForReceivedUserIDLock.withLock { suggestedRoleForUnderlyingReceivedUserID = newValue } }
    }
    private let suggestedRoleForReceivedInvocationsLock = NSLock()
    private var suggestedRoleForUnderlyingReceivedInvocations: [String] = []
    var suggestedRoleForReceivedInvocations: [String] {
        get { suggestedRoleForReceivedInvocationsLock.withLock { suggestedRoleForUnderlyingReceivedInvocations } }
        set { suggestedRoleForReceivedInvocationsLock.withLock { suggestedRoleForUnderlyingReceivedInvocations = newValue } }
    }

    private let suggestedRoleForReturnValueLock = NSLock()
    private var suggestedRoleForUnderlyingReturnValue: Result<RoomMemberRole, RoomProxyError>!
    var suggestedRoleForReturnValue: Result<RoomMemberRole, RoomProxyError>! {
        get { suggestedRoleForReturnValueLock.withLock { suggestedRoleForUnderlyingReturnValue } }
        set { suggestedRoleForReturnValueLock.withLock { suggestedRoleForUnderlyingReturnValue = newValue } }
    }
    var suggestedRoleForClosure: ((String) async -> Result<RoomMemberRole, RoomProxyError>)?

    func suggestedRole(for userID: String) async -> Result<RoomMemberRole, RoomProxyError> {
        suggestedRoleForCallsCountLock.withLock { suggestedRoleForUnderlyingCallsCount += 1 }
        suggestedRoleForReceivedUserID = userID
        suggestedRoleForReceivedInvocationsLock.withLock { suggestedRoleForUnderlyingReceivedInvocations.append(userID) }
        if let suggestedRoleForClosure = suggestedRoleForClosure {
            return await suggestedRoleForClosure(userID)
        } else {
            return suggestedRoleForReturnValue
        }
    }
    //MARK: - updatePowerLevelsForUsers

    private let updatePowerLevelsForUsersCallsCountLock = NSLock()
    private var updatePowerLevelsForUsersUnderlyingCallsCount = 0
    var updatePowerLevelsForUsersCallsCount: Int {
        get { updatePowerLevelsForUsersCallsCountLock.withLock { updatePowerLevelsForUsersUnderlyingCallsCount } }
        set { updatePowerLevelsForUsersCallsCountLock.withLock { updatePowerLevelsForUsersUnderlyingCallsCount = newValue } }
    }
    var updatePowerLevelsForUsersCalled: Bool {
        return updatePowerLevelsForUsersCallsCount > 0
    }
    private let updatePowerLevelsForUsersReceivedUpdatesLock = NSLock()
    private var updatePowerLevelsForUsersUnderlyingReceivedUpdates: [(userID: String, powerLevel: Int64)]?
    var updatePowerLevelsForUsersReceivedUpdates: [(userID: String, powerLevel: Int64)]? {
        get { updatePowerLevelsForUsersReceivedUpdatesLock.withLock { updatePowerLevelsForUsersUnderlyingReceivedUpdates } }
        set { updatePowerLevelsForUsersReceivedUpdatesLock.withLock { updatePowerLevelsForUsersUnderlyingReceivedUpdates = newValue } }
    }
    private let updatePowerLevelsForUsersReceivedInvocationsLock = NSLock()
    private var updatePowerLevelsForUsersUnderlyingReceivedInvocations: [[(userID: String, powerLevel: Int64)]] = []
    var updatePowerLevelsForUsersReceivedInvocations: [[(userID: String, powerLevel: Int64)]] {
        get { updatePowerLevelsForUsersReceivedInvocationsLock.withLock { updatePowerLevelsForUsersUnderlyingReceivedInvocations } }
        set { updatePowerLevelsForUsersReceivedInvocationsLock.withLock { updatePowerLevelsForUsersUnderlyingReceivedInvocations = newValue } }
    }

    private let updatePowerLevelsForUsersReturnValueLock = NSLock()
    private var updatePowerLevelsForUsersUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var updatePowerLevelsForUsersReturnValue: Result<Void, RoomProxyError>! {
        get { updatePowerLevelsForUsersReturnValueLock.withLock { updatePowerLevelsForUsersUnderlyingReturnValue } }
        set { updatePowerLevelsForUsersReturnValueLock.withLock { updatePowerLevelsForUsersUnderlyingReturnValue = newValue } }
    }
    var updatePowerLevelsForUsersClosure: (([(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError>)?

    func updatePowerLevelsForUsers(_ updates: [(userID: String, powerLevel: Int64)]) async -> Result<Void, RoomProxyError> {
        updatePowerLevelsForUsersCallsCountLock.withLock { updatePowerLevelsForUsersUnderlyingCallsCount += 1 }
        updatePowerLevelsForUsersReceivedUpdates = updates
        updatePowerLevelsForUsersReceivedInvocationsLock.withLock { updatePowerLevelsForUsersUnderlyingReceivedInvocations.append(updates) }
        if let updatePowerLevelsForUsersClosure = updatePowerLevelsForUsersClosure {
            return await updatePowerLevelsForUsersClosure(updates)
        } else {
            return updatePowerLevelsForUsersReturnValue
        }
    }
    //MARK: - kickUser

    private let kickUserReasonCallsCountLock = NSLock()
    private var kickUserReasonUnderlyingCallsCount = 0
    var kickUserReasonCallsCount: Int {
        get { kickUserReasonCallsCountLock.withLock { kickUserReasonUnderlyingCallsCount } }
        set { kickUserReasonCallsCountLock.withLock { kickUserReasonUnderlyingCallsCount = newValue } }
    }
    var kickUserReasonCalled: Bool {
        return kickUserReasonCallsCount > 0
    }
    private let kickUserReasonReceivedArgumentsLock = NSLock()
    private var kickUserReasonUnderlyingReceivedArguments: (userID: String, reason: String?)?
    var kickUserReasonReceivedArguments: (userID: String, reason: String?)? {
        get { kickUserReasonReceivedArgumentsLock.withLock { kickUserReasonUnderlyingReceivedArguments } }
        set { kickUserReasonReceivedArgumentsLock.withLock { kickUserReasonUnderlyingReceivedArguments = newValue } }
    }
    private let kickUserReasonReceivedInvocationsLock = NSLock()
    private var kickUserReasonUnderlyingReceivedInvocations: [(userID: String, reason: String?)] = []
    var kickUserReasonReceivedInvocations: [(userID: String, reason: String?)] {
        get { kickUserReasonReceivedInvocationsLock.withLock { kickUserReasonUnderlyingReceivedInvocations } }
        set { kickUserReasonReceivedInvocationsLock.withLock { kickUserReasonUnderlyingReceivedInvocations = newValue } }
    }

    private let kickUserReasonReturnValueLock = NSLock()
    private var kickUserReasonUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var kickUserReasonReturnValue: Result<Void, RoomProxyError>! {
        get { kickUserReasonReturnValueLock.withLock { kickUserReasonUnderlyingReturnValue } }
        set { kickUserReasonReturnValueLock.withLock { kickUserReasonUnderlyingReturnValue = newValue } }
    }
    var kickUserReasonClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func kickUser(_ userID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        kickUserReasonCallsCountLock.withLock { kickUserReasonUnderlyingCallsCount += 1 }
        kickUserReasonReceivedArguments = (userID: userID, reason: reason)
        kickUserReasonReceivedInvocationsLock.withLock { kickUserReasonUnderlyingReceivedInvocations.append((userID: userID, reason: reason)) }
        if let kickUserReasonClosure = kickUserReasonClosure {
            return await kickUserReasonClosure(userID, reason)
        } else {
            return kickUserReasonReturnValue
        }
    }
    //MARK: - banUser

    private let banUserReasonCallsCountLock = NSLock()
    private var banUserReasonUnderlyingCallsCount = 0
    var banUserReasonCallsCount: Int {
        get { banUserReasonCallsCountLock.withLock { banUserReasonUnderlyingCallsCount } }
        set { banUserReasonCallsCountLock.withLock { banUserReasonUnderlyingCallsCount = newValue } }
    }
    var banUserReasonCalled: Bool {
        return banUserReasonCallsCount > 0
    }
    private let banUserReasonReceivedArgumentsLock = NSLock()
    private var banUserReasonUnderlyingReceivedArguments: (userID: String, reason: String?)?
    var banUserReasonReceivedArguments: (userID: String, reason: String?)? {
        get { banUserReasonReceivedArgumentsLock.withLock { banUserReasonUnderlyingReceivedArguments } }
        set { banUserReasonReceivedArgumentsLock.withLock { banUserReasonUnderlyingReceivedArguments = newValue } }
    }
    private let banUserReasonReceivedInvocationsLock = NSLock()
    private var banUserReasonUnderlyingReceivedInvocations: [(userID: String, reason: String?)] = []
    var banUserReasonReceivedInvocations: [(userID: String, reason: String?)] {
        get { banUserReasonReceivedInvocationsLock.withLock { banUserReasonUnderlyingReceivedInvocations } }
        set { banUserReasonReceivedInvocationsLock.withLock { banUserReasonUnderlyingReceivedInvocations = newValue } }
    }

    private let banUserReasonReturnValueLock = NSLock()
    private var banUserReasonUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var banUserReasonReturnValue: Result<Void, RoomProxyError>! {
        get { banUserReasonReturnValueLock.withLock { banUserReasonUnderlyingReturnValue } }
        set { banUserReasonReturnValueLock.withLock { banUserReasonUnderlyingReturnValue = newValue } }
    }
    var banUserReasonClosure: ((String, String?) async -> Result<Void, RoomProxyError>)?

    func banUser(_ userID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        banUserReasonCallsCountLock.withLock { banUserReasonUnderlyingCallsCount += 1 }
        banUserReasonReceivedArguments = (userID: userID, reason: reason)
        banUserReasonReceivedInvocationsLock.withLock { banUserReasonUnderlyingReceivedInvocations.append((userID: userID, reason: reason)) }
        if let banUserReasonClosure = banUserReasonClosure {
            return await banUserReasonClosure(userID, reason)
        } else {
            return banUserReasonReturnValue
        }
    }
    //MARK: - unbanUser

    private let unbanUserCallsCountLock = NSLock()
    private var unbanUserUnderlyingCallsCount = 0
    var unbanUserCallsCount: Int {
        get { unbanUserCallsCountLock.withLock { unbanUserUnderlyingCallsCount } }
        set { unbanUserCallsCountLock.withLock { unbanUserUnderlyingCallsCount = newValue } }
    }
    var unbanUserCalled: Bool {
        return unbanUserCallsCount > 0
    }
    private let unbanUserReceivedUserIDLock = NSLock()
    private var unbanUserUnderlyingReceivedUserID: String?
    var unbanUserReceivedUserID: String? {
        get { unbanUserReceivedUserIDLock.withLock { unbanUserUnderlyingReceivedUserID } }
        set { unbanUserReceivedUserIDLock.withLock { unbanUserUnderlyingReceivedUserID = newValue } }
    }
    private let unbanUserReceivedInvocationsLock = NSLock()
    private var unbanUserUnderlyingReceivedInvocations: [String] = []
    var unbanUserReceivedInvocations: [String] {
        get { unbanUserReceivedInvocationsLock.withLock { unbanUserUnderlyingReceivedInvocations } }
        set { unbanUserReceivedInvocationsLock.withLock { unbanUserUnderlyingReceivedInvocations = newValue } }
    }

    private let unbanUserReturnValueLock = NSLock()
    private var unbanUserUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var unbanUserReturnValue: Result<Void, RoomProxyError>! {
        get { unbanUserReturnValueLock.withLock { unbanUserUnderlyingReturnValue } }
        set { unbanUserReturnValueLock.withLock { unbanUserUnderlyingReturnValue = newValue } }
    }
    var unbanUserClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func unbanUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        unbanUserCallsCountLock.withLock { unbanUserUnderlyingCallsCount += 1 }
        unbanUserReceivedUserID = userID
        unbanUserReceivedInvocationsLock.withLock { unbanUserUnderlyingReceivedInvocations.append(userID) }
        if let unbanUserClosure = unbanUserClosure {
            return await unbanUserClosure(userID)
        } else {
            return unbanUserReturnValue
        }
    }
    //MARK: - elementCallWidgetDriver

    private let elementCallWidgetDriverDeviceIDCallsCountLock = NSLock()
    private var elementCallWidgetDriverDeviceIDUnderlyingCallsCount = 0
    var elementCallWidgetDriverDeviceIDCallsCount: Int {
        get { elementCallWidgetDriverDeviceIDCallsCountLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingCallsCount } }
        set { elementCallWidgetDriverDeviceIDCallsCountLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingCallsCount = newValue } }
    }
    var elementCallWidgetDriverDeviceIDCalled: Bool {
        return elementCallWidgetDriverDeviceIDCallsCount > 0
    }
    private let elementCallWidgetDriverDeviceIDReceivedDeviceIDLock = NSLock()
    private var elementCallWidgetDriverDeviceIDUnderlyingReceivedDeviceID: String?
    var elementCallWidgetDriverDeviceIDReceivedDeviceID: String? {
        get { elementCallWidgetDriverDeviceIDReceivedDeviceIDLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReceivedDeviceID } }
        set { elementCallWidgetDriverDeviceIDReceivedDeviceIDLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReceivedDeviceID = newValue } }
    }
    private let elementCallWidgetDriverDeviceIDReceivedInvocationsLock = NSLock()
    private var elementCallWidgetDriverDeviceIDUnderlyingReceivedInvocations: [String] = []
    var elementCallWidgetDriverDeviceIDReceivedInvocations: [String] {
        get { elementCallWidgetDriverDeviceIDReceivedInvocationsLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReceivedInvocations } }
        set { elementCallWidgetDriverDeviceIDReceivedInvocationsLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReceivedInvocations = newValue } }
    }

    private let elementCallWidgetDriverDeviceIDReturnValueLock = NSLock()
    private var elementCallWidgetDriverDeviceIDUnderlyingReturnValue: ElementCallWidgetDriverProtocol!
    var elementCallWidgetDriverDeviceIDReturnValue: ElementCallWidgetDriverProtocol! {
        get { elementCallWidgetDriverDeviceIDReturnValueLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReturnValue } }
        set { elementCallWidgetDriverDeviceIDReturnValueLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReturnValue = newValue } }
    }
    var elementCallWidgetDriverDeviceIDClosure: ((String) -> ElementCallWidgetDriverProtocol)?

    func elementCallWidgetDriver(deviceID: String) -> ElementCallWidgetDriverProtocol {
        elementCallWidgetDriverDeviceIDCallsCountLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingCallsCount += 1 }
        elementCallWidgetDriverDeviceIDReceivedDeviceID = deviceID
        elementCallWidgetDriverDeviceIDReceivedInvocationsLock.withLock { elementCallWidgetDriverDeviceIDUnderlyingReceivedInvocations.append(deviceID) }
        if let elementCallWidgetDriverDeviceIDClosure = elementCallWidgetDriverDeviceIDClosure {
            return elementCallWidgetDriverDeviceIDClosure(deviceID)
        } else {
            return elementCallWidgetDriverDeviceIDReturnValue
        }
    }
    //MARK: - declineCall

    private let declineCallNotificationIDCallsCountLock = NSLock()
    private var declineCallNotificationIDUnderlyingCallsCount = 0
    var declineCallNotificationIDCallsCount: Int {
        get { declineCallNotificationIDCallsCountLock.withLock { declineCallNotificationIDUnderlyingCallsCount } }
        set { declineCallNotificationIDCallsCountLock.withLock { declineCallNotificationIDUnderlyingCallsCount = newValue } }
    }
    var declineCallNotificationIDCalled: Bool {
        return declineCallNotificationIDCallsCount > 0
    }
    private let declineCallNotificationIDReceivedNotificationIDLock = NSLock()
    private var declineCallNotificationIDUnderlyingReceivedNotificationID: String?
    var declineCallNotificationIDReceivedNotificationID: String? {
        get { declineCallNotificationIDReceivedNotificationIDLock.withLock { declineCallNotificationIDUnderlyingReceivedNotificationID } }
        set { declineCallNotificationIDReceivedNotificationIDLock.withLock { declineCallNotificationIDUnderlyingReceivedNotificationID = newValue } }
    }
    private let declineCallNotificationIDReceivedInvocationsLock = NSLock()
    private var declineCallNotificationIDUnderlyingReceivedInvocations: [String] = []
    var declineCallNotificationIDReceivedInvocations: [String] {
        get { declineCallNotificationIDReceivedInvocationsLock.withLock { declineCallNotificationIDUnderlyingReceivedInvocations } }
        set { declineCallNotificationIDReceivedInvocationsLock.withLock { declineCallNotificationIDUnderlyingReceivedInvocations = newValue } }
    }

    private let declineCallNotificationIDReturnValueLock = NSLock()
    private var declineCallNotificationIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var declineCallNotificationIDReturnValue: Result<Void, RoomProxyError>! {
        get { declineCallNotificationIDReturnValueLock.withLock { declineCallNotificationIDUnderlyingReturnValue } }
        set { declineCallNotificationIDReturnValueLock.withLock { declineCallNotificationIDUnderlyingReturnValue = newValue } }
    }
    var declineCallNotificationIDClosure: ((String) async -> Result<Void, RoomProxyError>)?

    func declineCall(notificationID: String) async -> Result<Void, RoomProxyError> {
        declineCallNotificationIDCallsCountLock.withLock { declineCallNotificationIDUnderlyingCallsCount += 1 }
        declineCallNotificationIDReceivedNotificationID = notificationID
        declineCallNotificationIDReceivedInvocationsLock.withLock { declineCallNotificationIDUnderlyingReceivedInvocations.append(notificationID) }
        if let declineCallNotificationIDClosure = declineCallNotificationIDClosure {
            return await declineCallNotificationIDClosure(notificationID)
        } else {
            return declineCallNotificationIDReturnValue
        }
    }
    //MARK: - subscribeToCallDeclineEvents

    private let subscribeToCallDeclineEventsRtcNotificationEventIDListenerCallsCountLock = NSLock()
    private var subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingCallsCount = 0
    var subscribeToCallDeclineEventsRtcNotificationEventIDListenerCallsCount: Int {
        get { subscribeToCallDeclineEventsRtcNotificationEventIDListenerCallsCountLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingCallsCount } }
        set { subscribeToCallDeclineEventsRtcNotificationEventIDListenerCallsCountLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingCallsCount = newValue } }
    }
    var subscribeToCallDeclineEventsRtcNotificationEventIDListenerCalled: Bool {
        return subscribeToCallDeclineEventsRtcNotificationEventIDListenerCallsCount > 0
    }
    private let subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArgumentsLock = NSLock()
    private var subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedArguments: (rtcNotificationEventID: String, listener: CallDeclineListener)?
    var subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArguments: (rtcNotificationEventID: String, listener: CallDeclineListener)? {
        get { subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArgumentsLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedArguments } }
        set { subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArgumentsLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedArguments = newValue } }
    }
    private let subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedInvocationsLock = NSLock()
    private var subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedInvocations: [(rtcNotificationEventID: String, listener: CallDeclineListener)] = []
    var subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedInvocations: [(rtcNotificationEventID: String, listener: CallDeclineListener)] {
        get { subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedInvocationsLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedInvocations } }
        set { subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedInvocationsLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedInvocations = newValue } }
    }

    private let subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValueLock = NSLock()
    private var subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReturnValue: Result<TaskHandle, RoomProxyError>!
    var subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValue: Result<TaskHandle, RoomProxyError>! {
        get { subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValueLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReturnValue } }
        set { subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValueLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReturnValue = newValue } }
    }
    var subscribeToCallDeclineEventsRtcNotificationEventIDListenerClosure: ((String, CallDeclineListener) -> Result<TaskHandle, RoomProxyError>)?

    func subscribeToCallDeclineEvents(rtcNotificationEventID: String, listener: CallDeclineListener) -> Result<TaskHandle, RoomProxyError> {
        subscribeToCallDeclineEventsRtcNotificationEventIDListenerCallsCountLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingCallsCount += 1 }
        subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedArguments = (rtcNotificationEventID: rtcNotificationEventID, listener: listener)
        subscribeToCallDeclineEventsRtcNotificationEventIDListenerReceivedInvocationsLock.withLock { subscribeToCallDeclineEventsRtcNotificationEventIDListenerUnderlyingReceivedInvocations.append((rtcNotificationEventID: rtcNotificationEventID, listener: listener)) }
        if let subscribeToCallDeclineEventsRtcNotificationEventIDListenerClosure = subscribeToCallDeclineEventsRtcNotificationEventIDListenerClosure {
            return subscribeToCallDeclineEventsRtcNotificationEventIDListenerClosure(rtcNotificationEventID, listener)
        } else {
            return subscribeToCallDeclineEventsRtcNotificationEventIDListenerReturnValue
        }
    }
    //MARK: - matrixToPermalink

    private let matrixToPermalinkCallsCountLock = NSLock()
    private var matrixToPermalinkUnderlyingCallsCount = 0
    var matrixToPermalinkCallsCount: Int {
        get { matrixToPermalinkCallsCountLock.withLock { matrixToPermalinkUnderlyingCallsCount } }
        set { matrixToPermalinkCallsCountLock.withLock { matrixToPermalinkUnderlyingCallsCount = newValue } }
    }
    var matrixToPermalinkCalled: Bool {
        return matrixToPermalinkCallsCount > 0
    }

    private let matrixToPermalinkReturnValueLock = NSLock()
    private var matrixToPermalinkUnderlyingReturnValue: Result<URL, RoomProxyError>!
    var matrixToPermalinkReturnValue: Result<URL, RoomProxyError>! {
        get { matrixToPermalinkReturnValueLock.withLock { matrixToPermalinkUnderlyingReturnValue } }
        set { matrixToPermalinkReturnValueLock.withLock { matrixToPermalinkUnderlyingReturnValue = newValue } }
    }
    var matrixToPermalinkClosure: (() async -> Result<URL, RoomProxyError>)?

    func matrixToPermalink() async -> Result<URL, RoomProxyError> {
        matrixToPermalinkCallsCountLock.withLock { matrixToPermalinkUnderlyingCallsCount += 1 }
        if let matrixToPermalinkClosure = matrixToPermalinkClosure {
            return await matrixToPermalinkClosure()
        } else {
            return matrixToPermalinkReturnValue
        }
    }
    //MARK: - matrixToEventPermalink

    private let matrixToEventPermalinkCallsCountLock = NSLock()
    private var matrixToEventPermalinkUnderlyingCallsCount = 0
    var matrixToEventPermalinkCallsCount: Int {
        get { matrixToEventPermalinkCallsCountLock.withLock { matrixToEventPermalinkUnderlyingCallsCount } }
        set { matrixToEventPermalinkCallsCountLock.withLock { matrixToEventPermalinkUnderlyingCallsCount = newValue } }
    }
    var matrixToEventPermalinkCalled: Bool {
        return matrixToEventPermalinkCallsCount > 0
    }
    private let matrixToEventPermalinkReceivedEventIDLock = NSLock()
    private var matrixToEventPermalinkUnderlyingReceivedEventID: String?
    var matrixToEventPermalinkReceivedEventID: String? {
        get { matrixToEventPermalinkReceivedEventIDLock.withLock { matrixToEventPermalinkUnderlyingReceivedEventID } }
        set { matrixToEventPermalinkReceivedEventIDLock.withLock { matrixToEventPermalinkUnderlyingReceivedEventID = newValue } }
    }
    private let matrixToEventPermalinkReceivedInvocationsLock = NSLock()
    private var matrixToEventPermalinkUnderlyingReceivedInvocations: [String] = []
    var matrixToEventPermalinkReceivedInvocations: [String] {
        get { matrixToEventPermalinkReceivedInvocationsLock.withLock { matrixToEventPermalinkUnderlyingReceivedInvocations } }
        set { matrixToEventPermalinkReceivedInvocationsLock.withLock { matrixToEventPermalinkUnderlyingReceivedInvocations = newValue } }
    }

    private let matrixToEventPermalinkReturnValueLock = NSLock()
    private var matrixToEventPermalinkUnderlyingReturnValue: Result<URL, RoomProxyError>!
    var matrixToEventPermalinkReturnValue: Result<URL, RoomProxyError>! {
        get { matrixToEventPermalinkReturnValueLock.withLock { matrixToEventPermalinkUnderlyingReturnValue } }
        set { matrixToEventPermalinkReturnValueLock.withLock { matrixToEventPermalinkUnderlyingReturnValue = newValue } }
    }
    var matrixToEventPermalinkClosure: ((String) async -> Result<URL, RoomProxyError>)?

    func matrixToEventPermalink(_ eventID: String) async -> Result<URL, RoomProxyError> {
        matrixToEventPermalinkCallsCountLock.withLock { matrixToEventPermalinkUnderlyingCallsCount += 1 }
        matrixToEventPermalinkReceivedEventID = eventID
        matrixToEventPermalinkReceivedInvocationsLock.withLock { matrixToEventPermalinkUnderlyingReceivedInvocations.append(eventID) }
        if let matrixToEventPermalinkClosure = matrixToEventPermalinkClosure {
            return await matrixToEventPermalinkClosure(eventID)
        } else {
            return matrixToEventPermalinkReturnValue
        }
    }
    //MARK: - saveDraft

    private let saveDraftThreadRootEventIDCallsCountLock = NSLock()
    private var saveDraftThreadRootEventIDUnderlyingCallsCount = 0
    var saveDraftThreadRootEventIDCallsCount: Int {
        get { saveDraftThreadRootEventIDCallsCountLock.withLock { saveDraftThreadRootEventIDUnderlyingCallsCount } }
        set { saveDraftThreadRootEventIDCallsCountLock.withLock { saveDraftThreadRootEventIDUnderlyingCallsCount = newValue } }
    }
    var saveDraftThreadRootEventIDCalled: Bool {
        return saveDraftThreadRootEventIDCallsCount > 0
    }
    private let saveDraftThreadRootEventIDReceivedArgumentsLock = NSLock()
    private var saveDraftThreadRootEventIDUnderlyingReceivedArguments: (draft: ComposerDraft, threadRootEventID: String?)?
    var saveDraftThreadRootEventIDReceivedArguments: (draft: ComposerDraft, threadRootEventID: String?)? {
        get { saveDraftThreadRootEventIDReceivedArgumentsLock.withLock { saveDraftThreadRootEventIDUnderlyingReceivedArguments } }
        set { saveDraftThreadRootEventIDReceivedArgumentsLock.withLock { saveDraftThreadRootEventIDUnderlyingReceivedArguments = newValue } }
    }
    private let saveDraftThreadRootEventIDReceivedInvocationsLock = NSLock()
    private var saveDraftThreadRootEventIDUnderlyingReceivedInvocations: [(draft: ComposerDraft, threadRootEventID: String?)] = []
    var saveDraftThreadRootEventIDReceivedInvocations: [(draft: ComposerDraft, threadRootEventID: String?)] {
        get { saveDraftThreadRootEventIDReceivedInvocationsLock.withLock { saveDraftThreadRootEventIDUnderlyingReceivedInvocations } }
        set { saveDraftThreadRootEventIDReceivedInvocationsLock.withLock { saveDraftThreadRootEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let saveDraftThreadRootEventIDReturnValueLock = NSLock()
    private var saveDraftThreadRootEventIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var saveDraftThreadRootEventIDReturnValue: Result<Void, RoomProxyError>! {
        get { saveDraftThreadRootEventIDReturnValueLock.withLock { saveDraftThreadRootEventIDUnderlyingReturnValue } }
        set { saveDraftThreadRootEventIDReturnValueLock.withLock { saveDraftThreadRootEventIDUnderlyingReturnValue = newValue } }
    }
    var saveDraftThreadRootEventIDClosure: ((ComposerDraft, String?) async -> Result<Void, RoomProxyError>)?

    func saveDraft(_ draft: ComposerDraft, threadRootEventID: String?) async -> Result<Void, RoomProxyError> {
        saveDraftThreadRootEventIDCallsCountLock.withLock { saveDraftThreadRootEventIDUnderlyingCallsCount += 1 }
        saveDraftThreadRootEventIDReceivedArguments = (draft: draft, threadRootEventID: threadRootEventID)
        saveDraftThreadRootEventIDReceivedInvocationsLock.withLock { saveDraftThreadRootEventIDUnderlyingReceivedInvocations.append((draft: draft, threadRootEventID: threadRootEventID)) }
        if let saveDraftThreadRootEventIDClosure = saveDraftThreadRootEventIDClosure {
            return await saveDraftThreadRootEventIDClosure(draft, threadRootEventID)
        } else {
            return saveDraftThreadRootEventIDReturnValue
        }
    }
    //MARK: - loadDraft

    private let loadDraftThreadRootEventIDCallsCountLock = NSLock()
    private var loadDraftThreadRootEventIDUnderlyingCallsCount = 0
    var loadDraftThreadRootEventIDCallsCount: Int {
        get { loadDraftThreadRootEventIDCallsCountLock.withLock { loadDraftThreadRootEventIDUnderlyingCallsCount } }
        set { loadDraftThreadRootEventIDCallsCountLock.withLock { loadDraftThreadRootEventIDUnderlyingCallsCount = newValue } }
    }
    var loadDraftThreadRootEventIDCalled: Bool {
        return loadDraftThreadRootEventIDCallsCount > 0
    }
    private let loadDraftThreadRootEventIDReceivedThreadRootEventIDLock = NSLock()
    private var loadDraftThreadRootEventIDUnderlyingReceivedThreadRootEventID: String?
    var loadDraftThreadRootEventIDReceivedThreadRootEventID: String? {
        get { loadDraftThreadRootEventIDReceivedThreadRootEventIDLock.withLock { loadDraftThreadRootEventIDUnderlyingReceivedThreadRootEventID } }
        set { loadDraftThreadRootEventIDReceivedThreadRootEventIDLock.withLock { loadDraftThreadRootEventIDUnderlyingReceivedThreadRootEventID = newValue } }
    }
    private let loadDraftThreadRootEventIDReceivedInvocationsLock = NSLock()
    private var loadDraftThreadRootEventIDUnderlyingReceivedInvocations: [String?] = []
    var loadDraftThreadRootEventIDReceivedInvocations: [String?] {
        get { loadDraftThreadRootEventIDReceivedInvocationsLock.withLock { loadDraftThreadRootEventIDUnderlyingReceivedInvocations } }
        set { loadDraftThreadRootEventIDReceivedInvocationsLock.withLock { loadDraftThreadRootEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let loadDraftThreadRootEventIDReturnValueLock = NSLock()
    private var loadDraftThreadRootEventIDUnderlyingReturnValue: Result<ComposerDraft?, RoomProxyError>!
    var loadDraftThreadRootEventIDReturnValue: Result<ComposerDraft?, RoomProxyError>! {
        get { loadDraftThreadRootEventIDReturnValueLock.withLock { loadDraftThreadRootEventIDUnderlyingReturnValue } }
        set { loadDraftThreadRootEventIDReturnValueLock.withLock { loadDraftThreadRootEventIDUnderlyingReturnValue = newValue } }
    }
    var loadDraftThreadRootEventIDClosure: ((String?) async -> Result<ComposerDraft?, RoomProxyError>)?

    func loadDraft(threadRootEventID: String?) async -> Result<ComposerDraft?, RoomProxyError> {
        loadDraftThreadRootEventIDCallsCountLock.withLock { loadDraftThreadRootEventIDUnderlyingCallsCount += 1 }
        loadDraftThreadRootEventIDReceivedThreadRootEventID = threadRootEventID
        loadDraftThreadRootEventIDReceivedInvocationsLock.withLock { loadDraftThreadRootEventIDUnderlyingReceivedInvocations.append(threadRootEventID) }
        if let loadDraftThreadRootEventIDClosure = loadDraftThreadRootEventIDClosure {
            return await loadDraftThreadRootEventIDClosure(threadRootEventID)
        } else {
            return loadDraftThreadRootEventIDReturnValue
        }
    }
    //MARK: - clearDraft

    private let clearDraftThreadRootEventIDCallsCountLock = NSLock()
    private var clearDraftThreadRootEventIDUnderlyingCallsCount = 0
    var clearDraftThreadRootEventIDCallsCount: Int {
        get { clearDraftThreadRootEventIDCallsCountLock.withLock { clearDraftThreadRootEventIDUnderlyingCallsCount } }
        set { clearDraftThreadRootEventIDCallsCountLock.withLock { clearDraftThreadRootEventIDUnderlyingCallsCount = newValue } }
    }
    var clearDraftThreadRootEventIDCalled: Bool {
        return clearDraftThreadRootEventIDCallsCount > 0
    }
    private let clearDraftThreadRootEventIDReceivedThreadRootEventIDLock = NSLock()
    private var clearDraftThreadRootEventIDUnderlyingReceivedThreadRootEventID: String?
    var clearDraftThreadRootEventIDReceivedThreadRootEventID: String? {
        get { clearDraftThreadRootEventIDReceivedThreadRootEventIDLock.withLock { clearDraftThreadRootEventIDUnderlyingReceivedThreadRootEventID } }
        set { clearDraftThreadRootEventIDReceivedThreadRootEventIDLock.withLock { clearDraftThreadRootEventIDUnderlyingReceivedThreadRootEventID = newValue } }
    }
    private let clearDraftThreadRootEventIDReceivedInvocationsLock = NSLock()
    private var clearDraftThreadRootEventIDUnderlyingReceivedInvocations: [String?] = []
    var clearDraftThreadRootEventIDReceivedInvocations: [String?] {
        get { clearDraftThreadRootEventIDReceivedInvocationsLock.withLock { clearDraftThreadRootEventIDUnderlyingReceivedInvocations } }
        set { clearDraftThreadRootEventIDReceivedInvocationsLock.withLock { clearDraftThreadRootEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let clearDraftThreadRootEventIDReturnValueLock = NSLock()
    private var clearDraftThreadRootEventIDUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var clearDraftThreadRootEventIDReturnValue: Result<Void, RoomProxyError>! {
        get { clearDraftThreadRootEventIDReturnValueLock.withLock { clearDraftThreadRootEventIDUnderlyingReturnValue } }
        set { clearDraftThreadRootEventIDReturnValueLock.withLock { clearDraftThreadRootEventIDUnderlyingReturnValue = newValue } }
    }
    var clearDraftThreadRootEventIDClosure: ((String?) async -> Result<Void, RoomProxyError>)?

    func clearDraft(threadRootEventID: String?) async -> Result<Void, RoomProxyError> {
        clearDraftThreadRootEventIDCallsCountLock.withLock { clearDraftThreadRootEventIDUnderlyingCallsCount += 1 }
        clearDraftThreadRootEventIDReceivedThreadRootEventID = threadRootEventID
        clearDraftThreadRootEventIDReceivedInvocationsLock.withLock { clearDraftThreadRootEventIDUnderlyingReceivedInvocations.append(threadRootEventID) }
        if let clearDraftThreadRootEventIDClosure = clearDraftThreadRootEventIDClosure {
            return await clearDraftThreadRootEventIDClosure(threadRootEventID)
        } else {
            return clearDraftThreadRootEventIDReturnValue
        }
    }
    //MARK: - makeLiveLocationService

    private let makeLiveLocationServiceCallsCountLock = NSLock()
    private var makeLiveLocationServiceUnderlyingCallsCount = 0
    var makeLiveLocationServiceCallsCount: Int {
        get { makeLiveLocationServiceCallsCountLock.withLock { makeLiveLocationServiceUnderlyingCallsCount } }
        set { makeLiveLocationServiceCallsCountLock.withLock { makeLiveLocationServiceUnderlyingCallsCount = newValue } }
    }
    var makeLiveLocationServiceCalled: Bool {
        return makeLiveLocationServiceCallsCount > 0
    }

    private let makeLiveLocationServiceReturnValueLock = NSLock()
    private var makeLiveLocationServiceUnderlyingReturnValue: RoomLiveLocationServiceProtocol!
    var makeLiveLocationServiceReturnValue: RoomLiveLocationServiceProtocol! {
        get { makeLiveLocationServiceReturnValueLock.withLock { makeLiveLocationServiceUnderlyingReturnValue } }
        set { makeLiveLocationServiceReturnValueLock.withLock { makeLiveLocationServiceUnderlyingReturnValue = newValue } }
    }
    var makeLiveLocationServiceClosure: (() async -> RoomLiveLocationServiceProtocol)?

    func makeLiveLocationService() async -> RoomLiveLocationServiceProtocol {
        makeLiveLocationServiceCallsCountLock.withLock { makeLiveLocationServiceUnderlyingCallsCount += 1 }
        if let makeLiveLocationServiceClosure = makeLiveLocationServiceClosure {
            return await makeLiveLocationServiceClosure()
        } else {
            return makeLiveLocationServiceReturnValue
        }
    }
    //MARK: - startLiveLocationShare

    private let startLiveLocationShareDurationCallsCountLock = NSLock()
    private var startLiveLocationShareDurationUnderlyingCallsCount = 0
    var startLiveLocationShareDurationCallsCount: Int {
        get { startLiveLocationShareDurationCallsCountLock.withLock { startLiveLocationShareDurationUnderlyingCallsCount } }
        set { startLiveLocationShareDurationCallsCountLock.withLock { startLiveLocationShareDurationUnderlyingCallsCount = newValue } }
    }
    var startLiveLocationShareDurationCalled: Bool {
        return startLiveLocationShareDurationCallsCount > 0
    }
    private let startLiveLocationShareDurationReceivedDurationLock = NSLock()
    private var startLiveLocationShareDurationUnderlyingReceivedDuration: Duration?
    var startLiveLocationShareDurationReceivedDuration: Duration? {
        get { startLiveLocationShareDurationReceivedDurationLock.withLock { startLiveLocationShareDurationUnderlyingReceivedDuration } }
        set { startLiveLocationShareDurationReceivedDurationLock.withLock { startLiveLocationShareDurationUnderlyingReceivedDuration = newValue } }
    }
    private let startLiveLocationShareDurationReceivedInvocationsLock = NSLock()
    private var startLiveLocationShareDurationUnderlyingReceivedInvocations: [Duration] = []
    var startLiveLocationShareDurationReceivedInvocations: [Duration] {
        get { startLiveLocationShareDurationReceivedInvocationsLock.withLock { startLiveLocationShareDurationUnderlyingReceivedInvocations } }
        set { startLiveLocationShareDurationReceivedInvocationsLock.withLock { startLiveLocationShareDurationUnderlyingReceivedInvocations = newValue } }
    }

    private let startLiveLocationShareDurationReturnValueLock = NSLock()
    private var startLiveLocationShareDurationUnderlyingReturnValue: Result<String, RoomProxyError>!
    var startLiveLocationShareDurationReturnValue: Result<String, RoomProxyError>! {
        get { startLiveLocationShareDurationReturnValueLock.withLock { startLiveLocationShareDurationUnderlyingReturnValue } }
        set { startLiveLocationShareDurationReturnValueLock.withLock { startLiveLocationShareDurationUnderlyingReturnValue = newValue } }
    }
    var startLiveLocationShareDurationClosure: ((Duration) async -> Result<String, RoomProxyError>)?

    func startLiveLocationShare(duration: Duration) async -> Result<String, RoomProxyError> {
        startLiveLocationShareDurationCallsCountLock.withLock { startLiveLocationShareDurationUnderlyingCallsCount += 1 }
        startLiveLocationShareDurationReceivedDuration = duration
        startLiveLocationShareDurationReceivedInvocationsLock.withLock { startLiveLocationShareDurationUnderlyingReceivedInvocations.append(duration) }
        if let startLiveLocationShareDurationClosure = startLiveLocationShareDurationClosure {
            return await startLiveLocationShareDurationClosure(duration)
        } else {
            return startLiveLocationShareDurationReturnValue
        }
    }
    //MARK: - sendLiveLocation

    private let sendLiveLocationGeoURICallsCountLock = NSLock()
    private var sendLiveLocationGeoURIUnderlyingCallsCount = 0
    var sendLiveLocationGeoURICallsCount: Int {
        get { sendLiveLocationGeoURICallsCountLock.withLock { sendLiveLocationGeoURIUnderlyingCallsCount } }
        set { sendLiveLocationGeoURICallsCountLock.withLock { sendLiveLocationGeoURIUnderlyingCallsCount = newValue } }
    }
    var sendLiveLocationGeoURICalled: Bool {
        return sendLiveLocationGeoURICallsCount > 0
    }
    private let sendLiveLocationGeoURIReceivedGeoURILock = NSLock()
    private var sendLiveLocationGeoURIUnderlyingReceivedGeoURI: GeoURI?
    var sendLiveLocationGeoURIReceivedGeoURI: GeoURI? {
        get { sendLiveLocationGeoURIReceivedGeoURILock.withLock { sendLiveLocationGeoURIUnderlyingReceivedGeoURI } }
        set { sendLiveLocationGeoURIReceivedGeoURILock.withLock { sendLiveLocationGeoURIUnderlyingReceivedGeoURI = newValue } }
    }
    private let sendLiveLocationGeoURIReceivedInvocationsLock = NSLock()
    private var sendLiveLocationGeoURIUnderlyingReceivedInvocations: [GeoURI] = []
    var sendLiveLocationGeoURIReceivedInvocations: [GeoURI] {
        get { sendLiveLocationGeoURIReceivedInvocationsLock.withLock { sendLiveLocationGeoURIUnderlyingReceivedInvocations } }
        set { sendLiveLocationGeoURIReceivedInvocationsLock.withLock { sendLiveLocationGeoURIUnderlyingReceivedInvocations = newValue } }
    }

    private let sendLiveLocationGeoURIReturnValueLock = NSLock()
    private var sendLiveLocationGeoURIUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var sendLiveLocationGeoURIReturnValue: Result<Void, RoomProxyError>! {
        get { sendLiveLocationGeoURIReturnValueLock.withLock { sendLiveLocationGeoURIUnderlyingReturnValue } }
        set { sendLiveLocationGeoURIReturnValueLock.withLock { sendLiveLocationGeoURIUnderlyingReturnValue = newValue } }
    }
    var sendLiveLocationGeoURIClosure: ((GeoURI) async -> Result<Void, RoomProxyError>)?

    func sendLiveLocation(geoURI: GeoURI) async -> Result<Void, RoomProxyError> {
        sendLiveLocationGeoURICallsCountLock.withLock { sendLiveLocationGeoURIUnderlyingCallsCount += 1 }
        sendLiveLocationGeoURIReceivedGeoURI = geoURI
        sendLiveLocationGeoURIReceivedInvocationsLock.withLock { sendLiveLocationGeoURIUnderlyingReceivedInvocations.append(geoURI) }
        if let sendLiveLocationGeoURIClosure = sendLiveLocationGeoURIClosure {
            return await sendLiveLocationGeoURIClosure(geoURI)
        } else {
            return sendLiveLocationGeoURIReturnValue
        }
    }
    //MARK: - stopLiveLocationShare

    private let stopLiveLocationShareCallsCountLock = NSLock()
    private var stopLiveLocationShareUnderlyingCallsCount = 0
    var stopLiveLocationShareCallsCount: Int {
        get { stopLiveLocationShareCallsCountLock.withLock { stopLiveLocationShareUnderlyingCallsCount } }
        set { stopLiveLocationShareCallsCountLock.withLock { stopLiveLocationShareUnderlyingCallsCount = newValue } }
    }
    var stopLiveLocationShareCalled: Bool {
        return stopLiveLocationShareCallsCount > 0
    }

    private let stopLiveLocationShareReturnValueLock = NSLock()
    private var stopLiveLocationShareUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var stopLiveLocationShareReturnValue: Result<Void, RoomProxyError>! {
        get { stopLiveLocationShareReturnValueLock.withLock { stopLiveLocationShareUnderlyingReturnValue } }
        set { stopLiveLocationShareReturnValueLock.withLock { stopLiveLocationShareUnderlyingReturnValue = newValue } }
    }
    var stopLiveLocationShareClosure: (() async -> Result<Void, RoomProxyError>)?

    func stopLiveLocationShare() async -> Result<Void, RoomProxyError> {
        stopLiveLocationShareCallsCountLock.withLock { stopLiveLocationShareUnderlyingCallsCount += 1 }
        if let stopLiveLocationShareClosure = stopLiveLocationShareClosure {
            return await stopLiveLocationShareClosure()
        } else {
            return stopLiveLocationShareReturnValue
        }
    }
}
class KeychainControllerMock: KeychainControllerProtocol, @unchecked Sendable {

    //MARK: - setRestorationToken

    private let setRestorationTokenForUsernameCallsCountLock = NSLock()
    private var setRestorationTokenForUsernameUnderlyingCallsCount = 0
    var setRestorationTokenForUsernameCallsCount: Int {
        get { setRestorationTokenForUsernameCallsCountLock.withLock { setRestorationTokenForUsernameUnderlyingCallsCount } }
        set { setRestorationTokenForUsernameCallsCountLock.withLock { setRestorationTokenForUsernameUnderlyingCallsCount = newValue } }
    }
    var setRestorationTokenForUsernameCalled: Bool {
        return setRestorationTokenForUsernameCallsCount > 0
    }
    private let setRestorationTokenForUsernameReceivedArgumentsLock = NSLock()
    private var setRestorationTokenForUsernameUnderlyingReceivedArguments: (restorationToken: RestorationToken, forUsername: String)?
    var setRestorationTokenForUsernameReceivedArguments: (restorationToken: RestorationToken, forUsername: String)? {
        get { setRestorationTokenForUsernameReceivedArgumentsLock.withLock { setRestorationTokenForUsernameUnderlyingReceivedArguments } }
        set { setRestorationTokenForUsernameReceivedArgumentsLock.withLock { setRestorationTokenForUsernameUnderlyingReceivedArguments = newValue } }
    }
    private let setRestorationTokenForUsernameReceivedInvocationsLock = NSLock()
    private var setRestorationTokenForUsernameUnderlyingReceivedInvocations: [(restorationToken: RestorationToken, forUsername: String)] = []
    var setRestorationTokenForUsernameReceivedInvocations: [(restorationToken: RestorationToken, forUsername: String)] {
        get { setRestorationTokenForUsernameReceivedInvocationsLock.withLock { setRestorationTokenForUsernameUnderlyingReceivedInvocations } }
        set { setRestorationTokenForUsernameReceivedInvocationsLock.withLock { setRestorationTokenForUsernameUnderlyingReceivedInvocations = newValue } }
    }
    var setRestorationTokenForUsernameClosure: ((RestorationToken, String) -> Void)?

    func setRestorationToken(_ restorationToken: RestorationToken, forUsername: String) {
        setRestorationTokenForUsernameCallsCountLock.withLock { setRestorationTokenForUsernameUnderlyingCallsCount += 1 }
        setRestorationTokenForUsernameReceivedArguments = (restorationToken: restorationToken, forUsername: forUsername)
        setRestorationTokenForUsernameReceivedInvocationsLock.withLock { setRestorationTokenForUsernameUnderlyingReceivedInvocations.append((restorationToken: restorationToken, forUsername: forUsername)) }
        setRestorationTokenForUsernameClosure?(restorationToken, forUsername)
    }
    //MARK: - restorationTokens

    private let restorationTokensCallsCountLock = NSLock()
    private var restorationTokensUnderlyingCallsCount = 0
    var restorationTokensCallsCount: Int {
        get { restorationTokensCallsCountLock.withLock { restorationTokensUnderlyingCallsCount } }
        set { restorationTokensCallsCountLock.withLock { restorationTokensUnderlyingCallsCount = newValue } }
    }
    var restorationTokensCalled: Bool {
        return restorationTokensCallsCount > 0
    }

    private let restorationTokensReturnValueLock = NSLock()
    private var restorationTokensUnderlyingReturnValue: [KeychainCredentials]!
    var restorationTokensReturnValue: [KeychainCredentials]! {
        get { restorationTokensReturnValueLock.withLock { restorationTokensUnderlyingReturnValue } }
        set { restorationTokensReturnValueLock.withLock { restorationTokensUnderlyingReturnValue = newValue } }
    }
    var restorationTokensClosure: (() -> [KeychainCredentials])?

    func restorationTokens() -> [KeychainCredentials] {
        restorationTokensCallsCountLock.withLock { restorationTokensUnderlyingCallsCount += 1 }
        if let restorationTokensClosure = restorationTokensClosure {
            return restorationTokensClosure()
        } else {
            return restorationTokensReturnValue
        }
    }
    //MARK: - removeRestorationTokenForUsername

    private let removeRestorationTokenForUsernameCallsCountLock = NSLock()
    private var removeRestorationTokenForUsernameUnderlyingCallsCount = 0
    var removeRestorationTokenForUsernameCallsCount: Int {
        get { removeRestorationTokenForUsernameCallsCountLock.withLock { removeRestorationTokenForUsernameUnderlyingCallsCount } }
        set { removeRestorationTokenForUsernameCallsCountLock.withLock { removeRestorationTokenForUsernameUnderlyingCallsCount = newValue } }
    }
    var removeRestorationTokenForUsernameCalled: Bool {
        return removeRestorationTokenForUsernameCallsCount > 0
    }
    private let removeRestorationTokenForUsernameReceivedUsernameLock = NSLock()
    private var removeRestorationTokenForUsernameUnderlyingReceivedUsername: String?
    var removeRestorationTokenForUsernameReceivedUsername: String? {
        get { removeRestorationTokenForUsernameReceivedUsernameLock.withLock { removeRestorationTokenForUsernameUnderlyingReceivedUsername } }
        set { removeRestorationTokenForUsernameReceivedUsernameLock.withLock { removeRestorationTokenForUsernameUnderlyingReceivedUsername = newValue } }
    }
    private let removeRestorationTokenForUsernameReceivedInvocationsLock = NSLock()
    private var removeRestorationTokenForUsernameUnderlyingReceivedInvocations: [String] = []
    var removeRestorationTokenForUsernameReceivedInvocations: [String] {
        get { removeRestorationTokenForUsernameReceivedInvocationsLock.withLock { removeRestorationTokenForUsernameUnderlyingReceivedInvocations } }
        set { removeRestorationTokenForUsernameReceivedInvocationsLock.withLock { removeRestorationTokenForUsernameUnderlyingReceivedInvocations = newValue } }
    }
    var removeRestorationTokenForUsernameClosure: ((String) -> Void)?

    func removeRestorationTokenForUsername(_ username: String) {
        removeRestorationTokenForUsernameCallsCountLock.withLock { removeRestorationTokenForUsernameUnderlyingCallsCount += 1 }
        removeRestorationTokenForUsernameReceivedUsername = username
        removeRestorationTokenForUsernameReceivedInvocationsLock.withLock { removeRestorationTokenForUsernameUnderlyingReceivedInvocations.append(username) }
        removeRestorationTokenForUsernameClosure?(username)
    }
    //MARK: - removeAllRestorationTokens

    private let removeAllRestorationTokensCallsCountLock = NSLock()
    private var removeAllRestorationTokensUnderlyingCallsCount = 0
    var removeAllRestorationTokensCallsCount: Int {
        get { removeAllRestorationTokensCallsCountLock.withLock { removeAllRestorationTokensUnderlyingCallsCount } }
        set { removeAllRestorationTokensCallsCountLock.withLock { removeAllRestorationTokensUnderlyingCallsCount = newValue } }
    }
    var removeAllRestorationTokensCalled: Bool {
        return removeAllRestorationTokensCallsCount > 0
    }
    var removeAllRestorationTokensClosure: (() -> Void)?

    func removeAllRestorationTokens() {
        removeAllRestorationTokensCallsCountLock.withLock { removeAllRestorationTokensUnderlyingCallsCount += 1 }
        removeAllRestorationTokensClosure?()
    }
    //MARK: - containsPINCode

    var containsPINCodeThrowableError: Error?
    private let containsPINCodeCallsCountLock = NSLock()
    private var containsPINCodeUnderlyingCallsCount = 0
    var containsPINCodeCallsCount: Int {
        get { containsPINCodeCallsCountLock.withLock { containsPINCodeUnderlyingCallsCount } }
        set { containsPINCodeCallsCountLock.withLock { containsPINCodeUnderlyingCallsCount = newValue } }
    }
    var containsPINCodeCalled: Bool {
        return containsPINCodeCallsCount > 0
    }

    private let containsPINCodeReturnValueLock = NSLock()
    private var containsPINCodeUnderlyingReturnValue: Bool!
    var containsPINCodeReturnValue: Bool! {
        get { containsPINCodeReturnValueLock.withLock { containsPINCodeUnderlyingReturnValue } }
        set { containsPINCodeReturnValueLock.withLock { containsPINCodeUnderlyingReturnValue = newValue } }
    }
    var containsPINCodeClosure: (() throws -> Bool)?

    func containsPINCode() throws -> Bool {
        if let error = containsPINCodeThrowableError {
            throw error
        }
        containsPINCodeCallsCountLock.withLock { containsPINCodeUnderlyingCallsCount += 1 }
        if let containsPINCodeClosure = containsPINCodeClosure {
            return try containsPINCodeClosure()
        } else {
            return containsPINCodeReturnValue
        }
    }
    //MARK: - setPINCode

    var setPINCodeThrowableError: Error?
    private let setPINCodeCallsCountLock = NSLock()
    private var setPINCodeUnderlyingCallsCount = 0
    var setPINCodeCallsCount: Int {
        get { setPINCodeCallsCountLock.withLock { setPINCodeUnderlyingCallsCount } }
        set { setPINCodeCallsCountLock.withLock { setPINCodeUnderlyingCallsCount = newValue } }
    }
    var setPINCodeCalled: Bool {
        return setPINCodeCallsCount > 0
    }
    private let setPINCodeReceivedPinCodeLock = NSLock()
    private var setPINCodeUnderlyingReceivedPinCode: String?
    var setPINCodeReceivedPinCode: String? {
        get { setPINCodeReceivedPinCodeLock.withLock { setPINCodeUnderlyingReceivedPinCode } }
        set { setPINCodeReceivedPinCodeLock.withLock { setPINCodeUnderlyingReceivedPinCode = newValue } }
    }
    private let setPINCodeReceivedInvocationsLock = NSLock()
    private var setPINCodeUnderlyingReceivedInvocations: [String] = []
    var setPINCodeReceivedInvocations: [String] {
        get { setPINCodeReceivedInvocationsLock.withLock { setPINCodeUnderlyingReceivedInvocations } }
        set { setPINCodeReceivedInvocationsLock.withLock { setPINCodeUnderlyingReceivedInvocations = newValue } }
    }
    var setPINCodeClosure: ((String) throws -> Void)?

    func setPINCode(_ pinCode: String) throws {
        if let error = setPINCodeThrowableError {
            throw error
        }
        setPINCodeCallsCountLock.withLock { setPINCodeUnderlyingCallsCount += 1 }
        setPINCodeReceivedPinCode = pinCode
        setPINCodeReceivedInvocationsLock.withLock { setPINCodeUnderlyingReceivedInvocations.append(pinCode) }
        try setPINCodeClosure?(pinCode)
    }
    //MARK: - pinCode

    private let pinCodeCallsCountLock = NSLock()
    private var pinCodeUnderlyingCallsCount = 0
    var pinCodeCallsCount: Int {
        get { pinCodeCallsCountLock.withLock { pinCodeUnderlyingCallsCount } }
        set { pinCodeCallsCountLock.withLock { pinCodeUnderlyingCallsCount = newValue } }
    }
    var pinCodeCalled: Bool {
        return pinCodeCallsCount > 0
    }

    private let pinCodeReturnValueLock = NSLock()
    private var pinCodeUnderlyingReturnValue: String?
    var pinCodeReturnValue: String? {
        get { pinCodeReturnValueLock.withLock { pinCodeUnderlyingReturnValue } }
        set { pinCodeReturnValueLock.withLock { pinCodeUnderlyingReturnValue = newValue } }
    }
    var pinCodeClosure: (() -> String?)?

    func pinCode() -> String? {
        pinCodeCallsCountLock.withLock { pinCodeUnderlyingCallsCount += 1 }
        if let pinCodeClosure = pinCodeClosure {
            return pinCodeClosure()
        } else {
            return pinCodeReturnValue
        }
    }
    //MARK: - removePINCode

    private let removePINCodeCallsCountLock = NSLock()
    private var removePINCodeUnderlyingCallsCount = 0
    var removePINCodeCallsCount: Int {
        get { removePINCodeCallsCountLock.withLock { removePINCodeUnderlyingCallsCount } }
        set { removePINCodeCallsCountLock.withLock { removePINCodeUnderlyingCallsCount = newValue } }
    }
    var removePINCodeCalled: Bool {
        return removePINCodeCallsCount > 0
    }
    var removePINCodeClosure: (() -> Void)?

    func removePINCode() {
        removePINCodeCallsCountLock.withLock { removePINCodeUnderlyingCallsCount += 1 }
        removePINCodeClosure?()
    }
    //MARK: - containsPINCodeBiometricState

    private let containsPINCodeBiometricStateCallsCountLock = NSLock()
    private var containsPINCodeBiometricStateUnderlyingCallsCount = 0
    var containsPINCodeBiometricStateCallsCount: Int {
        get { containsPINCodeBiometricStateCallsCountLock.withLock { containsPINCodeBiometricStateUnderlyingCallsCount } }
        set { containsPINCodeBiometricStateCallsCountLock.withLock { containsPINCodeBiometricStateUnderlyingCallsCount = newValue } }
    }
    var containsPINCodeBiometricStateCalled: Bool {
        return containsPINCodeBiometricStateCallsCount > 0
    }

    private let containsPINCodeBiometricStateReturnValueLock = NSLock()
    private var containsPINCodeBiometricStateUnderlyingReturnValue: Bool!
    var containsPINCodeBiometricStateReturnValue: Bool! {
        get { containsPINCodeBiometricStateReturnValueLock.withLock { containsPINCodeBiometricStateUnderlyingReturnValue } }
        set { containsPINCodeBiometricStateReturnValueLock.withLock { containsPINCodeBiometricStateUnderlyingReturnValue = newValue } }
    }
    var containsPINCodeBiometricStateClosure: (() -> Bool)?

    func containsPINCodeBiometricState() -> Bool {
        containsPINCodeBiometricStateCallsCountLock.withLock { containsPINCodeBiometricStateUnderlyingCallsCount += 1 }
        if let containsPINCodeBiometricStateClosure = containsPINCodeBiometricStateClosure {
            return containsPINCodeBiometricStateClosure()
        } else {
            return containsPINCodeBiometricStateReturnValue
        }
    }
    //MARK: - setPINCodeBiometricState

    var setPINCodeBiometricStateThrowableError: Error?
    private let setPINCodeBiometricStateCallsCountLock = NSLock()
    private var setPINCodeBiometricStateUnderlyingCallsCount = 0
    var setPINCodeBiometricStateCallsCount: Int {
        get { setPINCodeBiometricStateCallsCountLock.withLock { setPINCodeBiometricStateUnderlyingCallsCount } }
        set { setPINCodeBiometricStateCallsCountLock.withLock { setPINCodeBiometricStateUnderlyingCallsCount = newValue } }
    }
    var setPINCodeBiometricStateCalled: Bool {
        return setPINCodeBiometricStateCallsCount > 0
    }
    private let setPINCodeBiometricStateReceivedStateLock = NSLock()
    private var setPINCodeBiometricStateUnderlyingReceivedState: Data?
    var setPINCodeBiometricStateReceivedState: Data? {
        get { setPINCodeBiometricStateReceivedStateLock.withLock { setPINCodeBiometricStateUnderlyingReceivedState } }
        set { setPINCodeBiometricStateReceivedStateLock.withLock { setPINCodeBiometricStateUnderlyingReceivedState = newValue } }
    }
    private let setPINCodeBiometricStateReceivedInvocationsLock = NSLock()
    private var setPINCodeBiometricStateUnderlyingReceivedInvocations: [Data] = []
    var setPINCodeBiometricStateReceivedInvocations: [Data] {
        get { setPINCodeBiometricStateReceivedInvocationsLock.withLock { setPINCodeBiometricStateUnderlyingReceivedInvocations } }
        set { setPINCodeBiometricStateReceivedInvocationsLock.withLock { setPINCodeBiometricStateUnderlyingReceivedInvocations = newValue } }
    }
    var setPINCodeBiometricStateClosure: ((Data) throws -> Void)?

    func setPINCodeBiometricState(_ state: Data) throws {
        if let error = setPINCodeBiometricStateThrowableError {
            throw error
        }
        setPINCodeBiometricStateCallsCountLock.withLock { setPINCodeBiometricStateUnderlyingCallsCount += 1 }
        setPINCodeBiometricStateReceivedState = state
        setPINCodeBiometricStateReceivedInvocationsLock.withLock { setPINCodeBiometricStateUnderlyingReceivedInvocations.append(state) }
        try setPINCodeBiometricStateClosure?(state)
    }
    //MARK: - pinCodeBiometricState

    private let pinCodeBiometricStateCallsCountLock = NSLock()
    private var pinCodeBiometricStateUnderlyingCallsCount = 0
    var pinCodeBiometricStateCallsCount: Int {
        get { pinCodeBiometricStateCallsCountLock.withLock { pinCodeBiometricStateUnderlyingCallsCount } }
        set { pinCodeBiometricStateCallsCountLock.withLock { pinCodeBiometricStateUnderlyingCallsCount = newValue } }
    }
    var pinCodeBiometricStateCalled: Bool {
        return pinCodeBiometricStateCallsCount > 0
    }

    private let pinCodeBiometricStateReturnValueLock = NSLock()
    private var pinCodeBiometricStateUnderlyingReturnValue: Data?
    var pinCodeBiometricStateReturnValue: Data? {
        get { pinCodeBiometricStateReturnValueLock.withLock { pinCodeBiometricStateUnderlyingReturnValue } }
        set { pinCodeBiometricStateReturnValueLock.withLock { pinCodeBiometricStateUnderlyingReturnValue = newValue } }
    }
    var pinCodeBiometricStateClosure: (() -> Data?)?

    func pinCodeBiometricState() -> Data? {
        pinCodeBiometricStateCallsCountLock.withLock { pinCodeBiometricStateUnderlyingCallsCount += 1 }
        if let pinCodeBiometricStateClosure = pinCodeBiometricStateClosure {
            return pinCodeBiometricStateClosure()
        } else {
            return pinCodeBiometricStateReturnValue
        }
    }
    //MARK: - removePINCodeBiometricState

    private let removePINCodeBiometricStateCallsCountLock = NSLock()
    private var removePINCodeBiometricStateUnderlyingCallsCount = 0
    var removePINCodeBiometricStateCallsCount: Int {
        get { removePINCodeBiometricStateCallsCountLock.withLock { removePINCodeBiometricStateUnderlyingCallsCount } }
        set { removePINCodeBiometricStateCallsCountLock.withLock { removePINCodeBiometricStateUnderlyingCallsCount = newValue } }
    }
    var removePINCodeBiometricStateCalled: Bool {
        return removePINCodeBiometricStateCallsCount > 0
    }
    var removePINCodeBiometricStateClosure: (() -> Void)?

    func removePINCodeBiometricState() {
        removePINCodeBiometricStateCallsCountLock.withLock { removePINCodeBiometricStateUnderlyingCallsCount += 1 }
        removePINCodeBiometricStateClosure?()
    }
}
class KnockRequestProxyMock: KnockRequestProxyProtocol, @unchecked Sendable {
    var eventID: String {
        get { return underlyingEventID }
        set(value) { underlyingEventID = value }
    }
    var underlyingEventID: String!
    var userID: String {
        get { return underlyingUserID }
        set(value) { underlyingUserID = value }
    }
    var underlyingUserID: String!
    var displayName: String?
    var avatarURL: URL?
    var reason: String?
    var formattedTimestamp: String?
    var isSeen: Bool {
        get { return underlyingIsSeen }
        set(value) { underlyingIsSeen = value }
    }
    var underlyingIsSeen: Bool!

    //MARK: - accept

    private let acceptCallsCountLock = NSLock()
    private var acceptUnderlyingCallsCount = 0
    var acceptCallsCount: Int {
        get { acceptCallsCountLock.withLock { acceptUnderlyingCallsCount } }
        set { acceptCallsCountLock.withLock { acceptUnderlyingCallsCount = newValue } }
    }
    var acceptCalled: Bool {
        return acceptCallsCount > 0
    }

    private let acceptReturnValueLock = NSLock()
    private var acceptUnderlyingReturnValue: Result<Void, KnockRequestProxyError>!
    var acceptReturnValue: Result<Void, KnockRequestProxyError>! {
        get { acceptReturnValueLock.withLock { acceptUnderlyingReturnValue } }
        set { acceptReturnValueLock.withLock { acceptUnderlyingReturnValue = newValue } }
    }
    var acceptClosure: (() async -> Result<Void, KnockRequestProxyError>)?

    func accept() async -> Result<Void, KnockRequestProxyError> {
        acceptCallsCountLock.withLock { acceptUnderlyingCallsCount += 1 }
        if let acceptClosure = acceptClosure {
            return await acceptClosure()
        } else {
            return acceptReturnValue
        }
    }
    //MARK: - decline

    private let declineCallsCountLock = NSLock()
    private var declineUnderlyingCallsCount = 0
    var declineCallsCount: Int {
        get { declineCallsCountLock.withLock { declineUnderlyingCallsCount } }
        set { declineCallsCountLock.withLock { declineUnderlyingCallsCount = newValue } }
    }
    var declineCalled: Bool {
        return declineCallsCount > 0
    }

    private let declineReturnValueLock = NSLock()
    private var declineUnderlyingReturnValue: Result<Void, KnockRequestProxyError>!
    var declineReturnValue: Result<Void, KnockRequestProxyError>! {
        get { declineReturnValueLock.withLock { declineUnderlyingReturnValue } }
        set { declineReturnValueLock.withLock { declineUnderlyingReturnValue = newValue } }
    }
    var declineClosure: (() async -> Result<Void, KnockRequestProxyError>)?

    func decline() async -> Result<Void, KnockRequestProxyError> {
        declineCallsCountLock.withLock { declineUnderlyingCallsCount += 1 }
        if let declineClosure = declineClosure {
            return await declineClosure()
        } else {
            return declineReturnValue
        }
    }
    //MARK: - ban

    private let banCallsCountLock = NSLock()
    private var banUnderlyingCallsCount = 0
    var banCallsCount: Int {
        get { banCallsCountLock.withLock { banUnderlyingCallsCount } }
        set { banCallsCountLock.withLock { banUnderlyingCallsCount = newValue } }
    }
    var banCalled: Bool {
        return banCallsCount > 0
    }

    private let banReturnValueLock = NSLock()
    private var banUnderlyingReturnValue: Result<Void, KnockRequestProxyError>!
    var banReturnValue: Result<Void, KnockRequestProxyError>! {
        get { banReturnValueLock.withLock { banUnderlyingReturnValue } }
        set { banReturnValueLock.withLock { banUnderlyingReturnValue = newValue } }
    }
    var banClosure: (() async -> Result<Void, KnockRequestProxyError>)?

    func ban() async -> Result<Void, KnockRequestProxyError> {
        banCallsCountLock.withLock { banUnderlyingCallsCount += 1 }
        if let banClosure = banClosure {
            return await banClosure()
        } else {
            return banReturnValue
        }
    }
    //MARK: - markAsSeen

    private let markAsSeenCallsCountLock = NSLock()
    private var markAsSeenUnderlyingCallsCount = 0
    var markAsSeenCallsCount: Int {
        get { markAsSeenCallsCountLock.withLock { markAsSeenUnderlyingCallsCount } }
        set { markAsSeenCallsCountLock.withLock { markAsSeenUnderlyingCallsCount = newValue } }
    }
    var markAsSeenCalled: Bool {
        return markAsSeenCallsCount > 0
    }

    private let markAsSeenReturnValueLock = NSLock()
    private var markAsSeenUnderlyingReturnValue: Result<Void, KnockRequestProxyError>!
    var markAsSeenReturnValue: Result<Void, KnockRequestProxyError>! {
        get { markAsSeenReturnValueLock.withLock { markAsSeenUnderlyingReturnValue } }
        set { markAsSeenReturnValueLock.withLock { markAsSeenUnderlyingReturnValue = newValue } }
    }
    var markAsSeenClosure: (() async -> Result<Void, KnockRequestProxyError>)?

    func markAsSeen() async -> Result<Void, KnockRequestProxyError> {
        markAsSeenCallsCountLock.withLock { markAsSeenUnderlyingCallsCount += 1 }
        if let markAsSeenClosure = markAsSeenClosure {
            return await markAsSeenClosure()
        } else {
            return markAsSeenReturnValue
        }
    }
}
class KnockedRoomProxyMock: KnockedRoomProxyProtocol, @unchecked Sendable {
    var info: BaseRoomInfoProxyProtocol {
        get { return underlyingInfo }
        set(value) { underlyingInfo = value }
    }
    var underlyingInfo: BaseRoomInfoProxyProtocol!
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!

    //MARK: - cancelKnock

    private let cancelKnockCallsCountLock = NSLock()
    private var cancelKnockUnderlyingCallsCount = 0
    var cancelKnockCallsCount: Int {
        get { cancelKnockCallsCountLock.withLock { cancelKnockUnderlyingCallsCount } }
        set { cancelKnockCallsCountLock.withLock { cancelKnockUnderlyingCallsCount = newValue } }
    }
    var cancelKnockCalled: Bool {
        return cancelKnockCallsCount > 0
    }

    private let cancelKnockReturnValueLock = NSLock()
    private var cancelKnockUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var cancelKnockReturnValue: Result<Void, RoomProxyError>! {
        get { cancelKnockReturnValueLock.withLock { cancelKnockUnderlyingReturnValue } }
        set { cancelKnockReturnValueLock.withLock { cancelKnockUnderlyingReturnValue = newValue } }
    }
    var cancelKnockClosure: (() async -> Result<Void, RoomProxyError>)?

    func cancelKnock() async -> Result<Void, RoomProxyError> {
        cancelKnockCallsCountLock.withLock { cancelKnockUnderlyingCallsCount += 1 }
        if let cancelKnockClosure = cancelKnockClosure {
            return await cancelKnockClosure()
        } else {
            return cancelKnockReturnValue
        }
    }
}
class LinkNewDeviceServiceMock: LinkNewDeviceServiceProtocol, @unchecked Sendable {

    //MARK: - linkMobileDevice

    private let linkMobileDeviceCallsCountLock = NSLock()
    private var linkMobileDeviceUnderlyingCallsCount = 0
    var linkMobileDeviceCallsCount: Int {
        get { linkMobileDeviceCallsCountLock.withLock { linkMobileDeviceUnderlyingCallsCount } }
        set { linkMobileDeviceCallsCountLock.withLock { linkMobileDeviceUnderlyingCallsCount = newValue } }
    }
    var linkMobileDeviceCalled: Bool {
        return linkMobileDeviceCallsCount > 0
    }

    private let linkMobileDeviceReturnValueLock = NSLock()
    private var linkMobileDeviceUnderlyingReturnValue: LinkNewDeviceService.LinkMobileProgressPublisher!
    var linkMobileDeviceReturnValue: LinkNewDeviceService.LinkMobileProgressPublisher! {
        get { linkMobileDeviceReturnValueLock.withLock { linkMobileDeviceUnderlyingReturnValue } }
        set { linkMobileDeviceReturnValueLock.withLock { linkMobileDeviceUnderlyingReturnValue = newValue } }
    }
    var linkMobileDeviceClosure: (() -> LinkNewDeviceService.LinkMobileProgressPublisher)?

    func linkMobileDevice() -> LinkNewDeviceService.LinkMobileProgressPublisher {
        linkMobileDeviceCallsCountLock.withLock { linkMobileDeviceUnderlyingCallsCount += 1 }
        if let linkMobileDeviceClosure = linkMobileDeviceClosure {
            return linkMobileDeviceClosure()
        } else {
            return linkMobileDeviceReturnValue
        }
    }
    //MARK: - linkDesktopDevice

    private let linkDesktopDeviceWithCallsCountLock = NSLock()
    private var linkDesktopDeviceWithUnderlyingCallsCount = 0
    var linkDesktopDeviceWithCallsCount: Int {
        get { linkDesktopDeviceWithCallsCountLock.withLock { linkDesktopDeviceWithUnderlyingCallsCount } }
        set { linkDesktopDeviceWithCallsCountLock.withLock { linkDesktopDeviceWithUnderlyingCallsCount = newValue } }
    }
    var linkDesktopDeviceWithCalled: Bool {
        return linkDesktopDeviceWithCallsCount > 0
    }
    private let linkDesktopDeviceWithReceivedScannedQRDataLock = NSLock()
    private var linkDesktopDeviceWithUnderlyingReceivedScannedQRData: Data?
    var linkDesktopDeviceWithReceivedScannedQRData: Data? {
        get { linkDesktopDeviceWithReceivedScannedQRDataLock.withLock { linkDesktopDeviceWithUnderlyingReceivedScannedQRData } }
        set { linkDesktopDeviceWithReceivedScannedQRDataLock.withLock { linkDesktopDeviceWithUnderlyingReceivedScannedQRData = newValue } }
    }
    private let linkDesktopDeviceWithReceivedInvocationsLock = NSLock()
    private var linkDesktopDeviceWithUnderlyingReceivedInvocations: [Data] = []
    var linkDesktopDeviceWithReceivedInvocations: [Data] {
        get { linkDesktopDeviceWithReceivedInvocationsLock.withLock { linkDesktopDeviceWithUnderlyingReceivedInvocations } }
        set { linkDesktopDeviceWithReceivedInvocationsLock.withLock { linkDesktopDeviceWithUnderlyingReceivedInvocations = newValue } }
    }

    private let linkDesktopDeviceWithReturnValueLock = NSLock()
    private var linkDesktopDeviceWithUnderlyingReturnValue: LinkNewDeviceService.LinkDesktopProgressPublisher!
    var linkDesktopDeviceWithReturnValue: LinkNewDeviceService.LinkDesktopProgressPublisher! {
        get { linkDesktopDeviceWithReturnValueLock.withLock { linkDesktopDeviceWithUnderlyingReturnValue } }
        set { linkDesktopDeviceWithReturnValueLock.withLock { linkDesktopDeviceWithUnderlyingReturnValue = newValue } }
    }
    var linkDesktopDeviceWithClosure: ((Data) -> LinkNewDeviceService.LinkDesktopProgressPublisher)?

    func linkDesktopDevice(with scannedQRData: Data) -> LinkNewDeviceService.LinkDesktopProgressPublisher {
        linkDesktopDeviceWithCallsCountLock.withLock { linkDesktopDeviceWithUnderlyingCallsCount += 1 }
        linkDesktopDeviceWithReceivedScannedQRData = scannedQRData
        linkDesktopDeviceWithReceivedInvocationsLock.withLock { linkDesktopDeviceWithUnderlyingReceivedInvocations.append(scannedQRData) }
        if let linkDesktopDeviceWithClosure = linkDesktopDeviceWithClosure {
            return linkDesktopDeviceWithClosure(scannedQRData)
        } else {
            return linkDesktopDeviceWithReturnValue
        }
    }
}
class LiveLocationManagerMock: LiveLocationManagerProtocol, @unchecked Sendable {
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> {
        get { return underlyingAuthorizationStatus }
        set(value) { underlyingAuthorizationStatus = value }
    }
    var underlyingAuthorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never>!

    //MARK: - requestAlwaysAuthorizationIfPossible

    private let requestAlwaysAuthorizationIfPossibleCallsCountLock = NSLock()
    private var requestAlwaysAuthorizationIfPossibleUnderlyingCallsCount = 0
    var requestAlwaysAuthorizationIfPossibleCallsCount: Int {
        get { requestAlwaysAuthorizationIfPossibleCallsCountLock.withLock { requestAlwaysAuthorizationIfPossibleUnderlyingCallsCount } }
        set { requestAlwaysAuthorizationIfPossibleCallsCountLock.withLock { requestAlwaysAuthorizationIfPossibleUnderlyingCallsCount = newValue } }
    }
    var requestAlwaysAuthorizationIfPossibleCalled: Bool {
        return requestAlwaysAuthorizationIfPossibleCallsCount > 0
    }

    private let requestAlwaysAuthorizationIfPossibleReturnValueLock = NSLock()
    private var requestAlwaysAuthorizationIfPossibleUnderlyingReturnValue: Bool!
    var requestAlwaysAuthorizationIfPossibleReturnValue: Bool! {
        get { requestAlwaysAuthorizationIfPossibleReturnValueLock.withLock { requestAlwaysAuthorizationIfPossibleUnderlyingReturnValue } }
        set { requestAlwaysAuthorizationIfPossibleReturnValueLock.withLock { requestAlwaysAuthorizationIfPossibleUnderlyingReturnValue = newValue } }
    }
    var requestAlwaysAuthorizationIfPossibleClosure: (() -> Bool)?

    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool {
        requestAlwaysAuthorizationIfPossibleCallsCountLock.withLock { requestAlwaysAuthorizationIfPossibleUnderlyingCallsCount += 1 }
        if let requestAlwaysAuthorizationIfPossibleClosure = requestAlwaysAuthorizationIfPossibleClosure {
            return requestAlwaysAuthorizationIfPossibleClosure()
        } else {
            return requestAlwaysAuthorizationIfPossibleReturnValue
        }
    }
    //MARK: - startLiveLocation

    private let startLiveLocationRoomIDDurationCallsCountLock = NSLock()
    private var startLiveLocationRoomIDDurationUnderlyingCallsCount = 0
    var startLiveLocationRoomIDDurationCallsCount: Int {
        get { startLiveLocationRoomIDDurationCallsCountLock.withLock { startLiveLocationRoomIDDurationUnderlyingCallsCount } }
        set { startLiveLocationRoomIDDurationCallsCountLock.withLock { startLiveLocationRoomIDDurationUnderlyingCallsCount = newValue } }
    }
    var startLiveLocationRoomIDDurationCalled: Bool {
        return startLiveLocationRoomIDDurationCallsCount > 0
    }
    private let startLiveLocationRoomIDDurationReceivedArgumentsLock = NSLock()
    private var startLiveLocationRoomIDDurationUnderlyingReceivedArguments: (roomID: String, duration: Duration)?
    var startLiveLocationRoomIDDurationReceivedArguments: (roomID: String, duration: Duration)? {
        get { startLiveLocationRoomIDDurationReceivedArgumentsLock.withLock { startLiveLocationRoomIDDurationUnderlyingReceivedArguments } }
        set { startLiveLocationRoomIDDurationReceivedArgumentsLock.withLock { startLiveLocationRoomIDDurationUnderlyingReceivedArguments = newValue } }
    }
    private let startLiveLocationRoomIDDurationReceivedInvocationsLock = NSLock()
    private var startLiveLocationRoomIDDurationUnderlyingReceivedInvocations: [(roomID: String, duration: Duration)] = []
    var startLiveLocationRoomIDDurationReceivedInvocations: [(roomID: String, duration: Duration)] {
        get { startLiveLocationRoomIDDurationReceivedInvocationsLock.withLock { startLiveLocationRoomIDDurationUnderlyingReceivedInvocations } }
        set { startLiveLocationRoomIDDurationReceivedInvocationsLock.withLock { startLiveLocationRoomIDDurationUnderlyingReceivedInvocations = newValue } }
    }

    private let startLiveLocationRoomIDDurationReturnValueLock = NSLock()
    private var startLiveLocationRoomIDDurationUnderlyingReturnValue: Result<Void, LiveLocationManagerError>!
    var startLiveLocationRoomIDDurationReturnValue: Result<Void, LiveLocationManagerError>! {
        get { startLiveLocationRoomIDDurationReturnValueLock.withLock { startLiveLocationRoomIDDurationUnderlyingReturnValue } }
        set { startLiveLocationRoomIDDurationReturnValueLock.withLock { startLiveLocationRoomIDDurationUnderlyingReturnValue = newValue } }
    }
    var startLiveLocationRoomIDDurationClosure: ((String, Duration) async -> Result<Void, LiveLocationManagerError>)?

    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationManagerError> {
        startLiveLocationRoomIDDurationCallsCountLock.withLock { startLiveLocationRoomIDDurationUnderlyingCallsCount += 1 }
        startLiveLocationRoomIDDurationReceivedArguments = (roomID: roomID, duration: duration)
        startLiveLocationRoomIDDurationReceivedInvocationsLock.withLock { startLiveLocationRoomIDDurationUnderlyingReceivedInvocations.append((roomID: roomID, duration: duration)) }
        if let startLiveLocationRoomIDDurationClosure = startLiveLocationRoomIDDurationClosure {
            return await startLiveLocationRoomIDDurationClosure(roomID, duration)
        } else {
            return startLiveLocationRoomIDDurationReturnValue
        }
    }
    //MARK: - stopLiveLocation

    private let stopLiveLocationRoomIDCallsCountLock = NSLock()
    private var stopLiveLocationRoomIDUnderlyingCallsCount = 0
    var stopLiveLocationRoomIDCallsCount: Int {
        get { stopLiveLocationRoomIDCallsCountLock.withLock { stopLiveLocationRoomIDUnderlyingCallsCount } }
        set { stopLiveLocationRoomIDCallsCountLock.withLock { stopLiveLocationRoomIDUnderlyingCallsCount = newValue } }
    }
    var stopLiveLocationRoomIDCalled: Bool {
        return stopLiveLocationRoomIDCallsCount > 0
    }
    private let stopLiveLocationRoomIDReceivedRoomIDLock = NSLock()
    private var stopLiveLocationRoomIDUnderlyingReceivedRoomID: String?
    var stopLiveLocationRoomIDReceivedRoomID: String? {
        get { stopLiveLocationRoomIDReceivedRoomIDLock.withLock { stopLiveLocationRoomIDUnderlyingReceivedRoomID } }
        set { stopLiveLocationRoomIDReceivedRoomIDLock.withLock { stopLiveLocationRoomIDUnderlyingReceivedRoomID = newValue } }
    }
    private let stopLiveLocationRoomIDReceivedInvocationsLock = NSLock()
    private var stopLiveLocationRoomIDUnderlyingReceivedInvocations: [String] = []
    var stopLiveLocationRoomIDReceivedInvocations: [String] {
        get { stopLiveLocationRoomIDReceivedInvocationsLock.withLock { stopLiveLocationRoomIDUnderlyingReceivedInvocations } }
        set { stopLiveLocationRoomIDReceivedInvocationsLock.withLock { stopLiveLocationRoomIDUnderlyingReceivedInvocations = newValue } }
    }
    var stopLiveLocationRoomIDClosure: ((String) async -> Void)?

    func stopLiveLocation(roomID: String) async {
        stopLiveLocationRoomIDCallsCountLock.withLock { stopLiveLocationRoomIDUnderlyingCallsCount += 1 }
        stopLiveLocationRoomIDReceivedRoomID = roomID
        stopLiveLocationRoomIDReceivedInvocationsLock.withLock { stopLiveLocationRoomIDUnderlyingReceivedInvocations.append(roomID) }
        await stopLiveLocationRoomIDClosure?(roomID)
    }
}
class MediaLoaderMock: MediaLoaderProtocol, @unchecked Sendable {

    //MARK: - loadMediaContentForSource

    var loadMediaContentForSourceThrowableError: Error?
    private let loadMediaContentForSourceCallsCountLock = NSLock()
    private var loadMediaContentForSourceUnderlyingCallsCount = 0
    var loadMediaContentForSourceCallsCount: Int {
        get { loadMediaContentForSourceCallsCountLock.withLock { loadMediaContentForSourceUnderlyingCallsCount } }
        set { loadMediaContentForSourceCallsCountLock.withLock { loadMediaContentForSourceUnderlyingCallsCount = newValue } }
    }
    var loadMediaContentForSourceCalled: Bool {
        return loadMediaContentForSourceCallsCount > 0
    }
    private let loadMediaContentForSourceReceivedSourceLock = NSLock()
    private var loadMediaContentForSourceUnderlyingReceivedSource: MediaSourceProxy?
    var loadMediaContentForSourceReceivedSource: MediaSourceProxy? {
        get { loadMediaContentForSourceReceivedSourceLock.withLock { loadMediaContentForSourceUnderlyingReceivedSource } }
        set { loadMediaContentForSourceReceivedSourceLock.withLock { loadMediaContentForSourceUnderlyingReceivedSource = newValue } }
    }
    private let loadMediaContentForSourceReceivedInvocationsLock = NSLock()
    private var loadMediaContentForSourceUnderlyingReceivedInvocations: [MediaSourceProxy] = []
    var loadMediaContentForSourceReceivedInvocations: [MediaSourceProxy] {
        get { loadMediaContentForSourceReceivedInvocationsLock.withLock { loadMediaContentForSourceUnderlyingReceivedInvocations } }
        set { loadMediaContentForSourceReceivedInvocationsLock.withLock { loadMediaContentForSourceUnderlyingReceivedInvocations = newValue } }
    }

    private let loadMediaContentForSourceReturnValueLock = NSLock()
    private var loadMediaContentForSourceUnderlyingReturnValue: Data!
    var loadMediaContentForSourceReturnValue: Data! {
        get { loadMediaContentForSourceReturnValueLock.withLock { loadMediaContentForSourceUnderlyingReturnValue } }
        set { loadMediaContentForSourceReturnValueLock.withLock { loadMediaContentForSourceUnderlyingReturnValue = newValue } }
    }
    var loadMediaContentForSourceClosure: ((MediaSourceProxy) async throws -> Data)?

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        if let error = loadMediaContentForSourceThrowableError {
            throw error
        }
        loadMediaContentForSourceCallsCountLock.withLock { loadMediaContentForSourceUnderlyingCallsCount += 1 }
        loadMediaContentForSourceReceivedSource = source
        loadMediaContentForSourceReceivedInvocationsLock.withLock { loadMediaContentForSourceUnderlyingReceivedInvocations.append(source) }
        if let loadMediaContentForSourceClosure = loadMediaContentForSourceClosure {
            return try await loadMediaContentForSourceClosure(source)
        } else {
            return loadMediaContentForSourceReturnValue
        }
    }
    //MARK: - loadMediaThumbnailForSource

    var loadMediaThumbnailForSourceWidthHeightThrowableError: Error?
    private let loadMediaThumbnailForSourceWidthHeightCallsCountLock = NSLock()
    private var loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = 0
    var loadMediaThumbnailForSourceWidthHeightCallsCount: Int {
        get { loadMediaThumbnailForSourceWidthHeightCallsCountLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount } }
        set { loadMediaThumbnailForSourceWidthHeightCallsCountLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount = newValue } }
    }
    var loadMediaThumbnailForSourceWidthHeightCalled: Bool {
        return loadMediaThumbnailForSourceWidthHeightCallsCount > 0
    }
    private let loadMediaThumbnailForSourceWidthHeightReceivedArgumentsLock = NSLock()
    private var loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedArguments: (source: MediaSourceProxy, width: UInt, height: UInt)?
    var loadMediaThumbnailForSourceWidthHeightReceivedArguments: (source: MediaSourceProxy, width: UInt, height: UInt)? {
        get { loadMediaThumbnailForSourceWidthHeightReceivedArgumentsLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedArguments } }
        set { loadMediaThumbnailForSourceWidthHeightReceivedArgumentsLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedArguments = newValue } }
    }
    private let loadMediaThumbnailForSourceWidthHeightReceivedInvocationsLock = NSLock()
    private var loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedInvocations: [(source: MediaSourceProxy, width: UInt, height: UInt)] = []
    var loadMediaThumbnailForSourceWidthHeightReceivedInvocations: [(source: MediaSourceProxy, width: UInt, height: UInt)] {
        get { loadMediaThumbnailForSourceWidthHeightReceivedInvocationsLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedInvocations } }
        set { loadMediaThumbnailForSourceWidthHeightReceivedInvocationsLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedInvocations = newValue } }
    }

    private let loadMediaThumbnailForSourceWidthHeightReturnValueLock = NSLock()
    private var loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue: Data!
    var loadMediaThumbnailForSourceWidthHeightReturnValue: Data! {
        get { loadMediaThumbnailForSourceWidthHeightReturnValueLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue } }
        set { loadMediaThumbnailForSourceWidthHeightReturnValueLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReturnValue = newValue } }
    }
    var loadMediaThumbnailForSourceWidthHeightClosure: ((MediaSourceProxy, UInt, UInt) async throws -> Data)?

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        if let error = loadMediaThumbnailForSourceWidthHeightThrowableError {
            throw error
        }
        loadMediaThumbnailForSourceWidthHeightCallsCountLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingCallsCount += 1 }
        loadMediaThumbnailForSourceWidthHeightReceivedArguments = (source: source, width: width, height: height)
        loadMediaThumbnailForSourceWidthHeightReceivedInvocationsLock.withLock { loadMediaThumbnailForSourceWidthHeightUnderlyingReceivedInvocations.append((source: source, width: width, height: height)) }
        if let loadMediaThumbnailForSourceWidthHeightClosure = loadMediaThumbnailForSourceWidthHeightClosure {
            return try await loadMediaThumbnailForSourceWidthHeightClosure(source, width, height)
        } else {
            return loadMediaThumbnailForSourceWidthHeightReturnValue
        }
    }
    //MARK: - loadMediaFileForSource

    var loadMediaFileForSourceFilenameThrowableError: Error?
    private let loadMediaFileForSourceFilenameCallsCountLock = NSLock()
    private var loadMediaFileForSourceFilenameUnderlyingCallsCount = 0
    var loadMediaFileForSourceFilenameCallsCount: Int {
        get { loadMediaFileForSourceFilenameCallsCountLock.withLock { loadMediaFileForSourceFilenameUnderlyingCallsCount } }
        set { loadMediaFileForSourceFilenameCallsCountLock.withLock { loadMediaFileForSourceFilenameUnderlyingCallsCount = newValue } }
    }
    var loadMediaFileForSourceFilenameCalled: Bool {
        return loadMediaFileForSourceFilenameCallsCount > 0
    }
    private let loadMediaFileForSourceFilenameReceivedArgumentsLock = NSLock()
    private var loadMediaFileForSourceFilenameUnderlyingReceivedArguments: (source: MediaSourceProxy, filename: String?)?
    var loadMediaFileForSourceFilenameReceivedArguments: (source: MediaSourceProxy, filename: String?)? {
        get { loadMediaFileForSourceFilenameReceivedArgumentsLock.withLock { loadMediaFileForSourceFilenameUnderlyingReceivedArguments } }
        set { loadMediaFileForSourceFilenameReceivedArgumentsLock.withLock { loadMediaFileForSourceFilenameUnderlyingReceivedArguments = newValue } }
    }
    private let loadMediaFileForSourceFilenameReceivedInvocationsLock = NSLock()
    private var loadMediaFileForSourceFilenameUnderlyingReceivedInvocations: [(source: MediaSourceProxy, filename: String?)] = []
    var loadMediaFileForSourceFilenameReceivedInvocations: [(source: MediaSourceProxy, filename: String?)] {
        get { loadMediaFileForSourceFilenameReceivedInvocationsLock.withLock { loadMediaFileForSourceFilenameUnderlyingReceivedInvocations } }
        set { loadMediaFileForSourceFilenameReceivedInvocationsLock.withLock { loadMediaFileForSourceFilenameUnderlyingReceivedInvocations = newValue } }
    }

    private let loadMediaFileForSourceFilenameReturnValueLock = NSLock()
    private var loadMediaFileForSourceFilenameUnderlyingReturnValue: MediaFileHandleProxy!
    var loadMediaFileForSourceFilenameReturnValue: MediaFileHandleProxy! {
        get { loadMediaFileForSourceFilenameReturnValueLock.withLock { loadMediaFileForSourceFilenameUnderlyingReturnValue } }
        set { loadMediaFileForSourceFilenameReturnValueLock.withLock { loadMediaFileForSourceFilenameUnderlyingReturnValue = newValue } }
    }
    var loadMediaFileForSourceFilenameClosure: ((MediaSourceProxy, String?) async throws -> MediaFileHandleProxy)?

    func loadMediaFileForSource(_ source: MediaSourceProxy, filename: String?) async throws -> MediaFileHandleProxy {
        if let error = loadMediaFileForSourceFilenameThrowableError {
            throw error
        }
        loadMediaFileForSourceFilenameCallsCountLock.withLock { loadMediaFileForSourceFilenameUnderlyingCallsCount += 1 }
        loadMediaFileForSourceFilenameReceivedArguments = (source: source, filename: filename)
        loadMediaFileForSourceFilenameReceivedInvocationsLock.withLock { loadMediaFileForSourceFilenameUnderlyingReceivedInvocations.append((source: source, filename: filename)) }
        if let loadMediaFileForSourceFilenameClosure = loadMediaFileForSourceFilenameClosure {
            return try await loadMediaFileForSourceFilenameClosure(source, filename)
        } else {
            return loadMediaFileForSourceFilenameReturnValue
        }
    }
}
class MediaPlayerProviderMock: MediaPlayerProviderProtocol, @unchecked Sendable {
    var player: AudioPlayerProtocol {
        get { return underlyingPlayer }
        set(value) { underlyingPlayer = value }
    }
    var underlyingPlayer: AudioPlayerProtocol!

    //MARK: - playerState

    private let playerStateForCallsCountLock = NSLock()
    private var playerStateForUnderlyingCallsCount = 0
    var playerStateForCallsCount: Int {
        get { playerStateForCallsCountLock.withLock { playerStateForUnderlyingCallsCount } }
        set { playerStateForCallsCountLock.withLock { playerStateForUnderlyingCallsCount = newValue } }
    }
    var playerStateForCalled: Bool {
        return playerStateForCallsCount > 0
    }
    private let playerStateForReceivedIdLock = NSLock()
    private var playerStateForUnderlyingReceivedId: AudioPlayerStateIdentifier?
    var playerStateForReceivedId: AudioPlayerStateIdentifier? {
        get { playerStateForReceivedIdLock.withLock { playerStateForUnderlyingReceivedId } }
        set { playerStateForReceivedIdLock.withLock { playerStateForUnderlyingReceivedId = newValue } }
    }
    private let playerStateForReceivedInvocationsLock = NSLock()
    private var playerStateForUnderlyingReceivedInvocations: [AudioPlayerStateIdentifier] = []
    var playerStateForReceivedInvocations: [AudioPlayerStateIdentifier] {
        get { playerStateForReceivedInvocationsLock.withLock { playerStateForUnderlyingReceivedInvocations } }
        set { playerStateForReceivedInvocationsLock.withLock { playerStateForUnderlyingReceivedInvocations = newValue } }
    }

    private let playerStateForReturnValueLock = NSLock()
    private var playerStateForUnderlyingReturnValue: AudioPlayerState?
    var playerStateForReturnValue: AudioPlayerState? {
        get { playerStateForReturnValueLock.withLock { playerStateForUnderlyingReturnValue } }
        set { playerStateForReturnValueLock.withLock { playerStateForUnderlyingReturnValue = newValue } }
    }
    var playerStateForClosure: ((AudioPlayerStateIdentifier) -> AudioPlayerState?)?

    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState? {
        playerStateForCallsCountLock.withLock { playerStateForUnderlyingCallsCount += 1 }
        playerStateForReceivedId = id
        playerStateForReceivedInvocationsLock.withLock { playerStateForUnderlyingReceivedInvocations.append(id) }
        if let playerStateForClosure = playerStateForClosure {
            return playerStateForClosure(id)
        } else {
            return playerStateForReturnValue
        }
    }
    //MARK: - register

    private let registerAudioPlayerStateCallsCountLock = NSLock()
    private var registerAudioPlayerStateUnderlyingCallsCount = 0
    var registerAudioPlayerStateCallsCount: Int {
        get { registerAudioPlayerStateCallsCountLock.withLock { registerAudioPlayerStateUnderlyingCallsCount } }
        set { registerAudioPlayerStateCallsCountLock.withLock { registerAudioPlayerStateUnderlyingCallsCount = newValue } }
    }
    var registerAudioPlayerStateCalled: Bool {
        return registerAudioPlayerStateCallsCount > 0
    }
    private let registerAudioPlayerStateReceivedAudioPlayerStateLock = NSLock()
    private var registerAudioPlayerStateUnderlyingReceivedAudioPlayerState: AudioPlayerState?
    var registerAudioPlayerStateReceivedAudioPlayerState: AudioPlayerState? {
        get { registerAudioPlayerStateReceivedAudioPlayerStateLock.withLock { registerAudioPlayerStateUnderlyingReceivedAudioPlayerState } }
        set { registerAudioPlayerStateReceivedAudioPlayerStateLock.withLock { registerAudioPlayerStateUnderlyingReceivedAudioPlayerState = newValue } }
    }
    private let registerAudioPlayerStateReceivedInvocationsLock = NSLock()
    private var registerAudioPlayerStateUnderlyingReceivedInvocations: [AudioPlayerState] = []
    var registerAudioPlayerStateReceivedInvocations: [AudioPlayerState] {
        get { registerAudioPlayerStateReceivedInvocationsLock.withLock { registerAudioPlayerStateUnderlyingReceivedInvocations } }
        set { registerAudioPlayerStateReceivedInvocationsLock.withLock { registerAudioPlayerStateUnderlyingReceivedInvocations = newValue } }
    }
    var registerAudioPlayerStateClosure: ((AudioPlayerState) -> Void)?

    func register(audioPlayerState: AudioPlayerState) {
        registerAudioPlayerStateCallsCountLock.withLock { registerAudioPlayerStateUnderlyingCallsCount += 1 }
        registerAudioPlayerStateReceivedAudioPlayerState = audioPlayerState
        registerAudioPlayerStateReceivedInvocationsLock.withLock { registerAudioPlayerStateUnderlyingReceivedInvocations.append(audioPlayerState) }
        registerAudioPlayerStateClosure?(audioPlayerState)
    }
    //MARK: - unregister

    private let unregisterAudioPlayerStateCallsCountLock = NSLock()
    private var unregisterAudioPlayerStateUnderlyingCallsCount = 0
    var unregisterAudioPlayerStateCallsCount: Int {
        get { unregisterAudioPlayerStateCallsCountLock.withLock { unregisterAudioPlayerStateUnderlyingCallsCount } }
        set { unregisterAudioPlayerStateCallsCountLock.withLock { unregisterAudioPlayerStateUnderlyingCallsCount = newValue } }
    }
    var unregisterAudioPlayerStateCalled: Bool {
        return unregisterAudioPlayerStateCallsCount > 0
    }
    private let unregisterAudioPlayerStateReceivedAudioPlayerStateLock = NSLock()
    private var unregisterAudioPlayerStateUnderlyingReceivedAudioPlayerState: AudioPlayerState?
    var unregisterAudioPlayerStateReceivedAudioPlayerState: AudioPlayerState? {
        get { unregisterAudioPlayerStateReceivedAudioPlayerStateLock.withLock { unregisterAudioPlayerStateUnderlyingReceivedAudioPlayerState } }
        set { unregisterAudioPlayerStateReceivedAudioPlayerStateLock.withLock { unregisterAudioPlayerStateUnderlyingReceivedAudioPlayerState = newValue } }
    }
    private let unregisterAudioPlayerStateReceivedInvocationsLock = NSLock()
    private var unregisterAudioPlayerStateUnderlyingReceivedInvocations: [AudioPlayerState] = []
    var unregisterAudioPlayerStateReceivedInvocations: [AudioPlayerState] {
        get { unregisterAudioPlayerStateReceivedInvocationsLock.withLock { unregisterAudioPlayerStateUnderlyingReceivedInvocations } }
        set { unregisterAudioPlayerStateReceivedInvocationsLock.withLock { unregisterAudioPlayerStateUnderlyingReceivedInvocations = newValue } }
    }
    var unregisterAudioPlayerStateClosure: ((AudioPlayerState) -> Void)?

    func unregister(audioPlayerState: AudioPlayerState) {
        unregisterAudioPlayerStateCallsCountLock.withLock { unregisterAudioPlayerStateUnderlyingCallsCount += 1 }
        unregisterAudioPlayerStateReceivedAudioPlayerState = audioPlayerState
        unregisterAudioPlayerStateReceivedInvocationsLock.withLock { unregisterAudioPlayerStateUnderlyingReceivedInvocations.append(audioPlayerState) }
        unregisterAudioPlayerStateClosure?(audioPlayerState)
    }
    //MARK: - detachAllStates

    private let detachAllStatesExceptCallsCountLock = NSLock()
    private var detachAllStatesExceptUnderlyingCallsCount = 0
    var detachAllStatesExceptCallsCount: Int {
        get { detachAllStatesExceptCallsCountLock.withLock { detachAllStatesExceptUnderlyingCallsCount } }
        set { detachAllStatesExceptCallsCountLock.withLock { detachAllStatesExceptUnderlyingCallsCount = newValue } }
    }
    var detachAllStatesExceptCalled: Bool {
        return detachAllStatesExceptCallsCount > 0
    }
    private let detachAllStatesExceptReceivedExceptionLock = NSLock()
    private var detachAllStatesExceptUnderlyingReceivedException: AudioPlayerState?
    var detachAllStatesExceptReceivedException: AudioPlayerState? {
        get { detachAllStatesExceptReceivedExceptionLock.withLock { detachAllStatesExceptUnderlyingReceivedException } }
        set { detachAllStatesExceptReceivedExceptionLock.withLock { detachAllStatesExceptUnderlyingReceivedException = newValue } }
    }
    private let detachAllStatesExceptReceivedInvocationsLock = NSLock()
    private var detachAllStatesExceptUnderlyingReceivedInvocations: [AudioPlayerState?] = []
    var detachAllStatesExceptReceivedInvocations: [AudioPlayerState?] {
        get { detachAllStatesExceptReceivedInvocationsLock.withLock { detachAllStatesExceptUnderlyingReceivedInvocations } }
        set { detachAllStatesExceptReceivedInvocationsLock.withLock { detachAllStatesExceptUnderlyingReceivedInvocations = newValue } }
    }
    var detachAllStatesExceptClosure: ((AudioPlayerState?) async -> Void)?

    func detachAllStates(except exception: AudioPlayerState?) async {
        detachAllStatesExceptCallsCountLock.withLock { detachAllStatesExceptUnderlyingCallsCount += 1 }
        detachAllStatesExceptReceivedException = exception
        detachAllStatesExceptReceivedInvocationsLock.withLock { detachAllStatesExceptUnderlyingReceivedInvocations.append(exception) }
        await detachAllStatesExceptClosure?(exception)
    }
}
class MediaProviderMock: MediaProviderProtocol, @unchecked Sendable {

    //MARK: - imageFromSource

    private let imageFromSourceSizeCallsCountLock = NSLock()
    private var imageFromSourceSizeUnderlyingCallsCount = 0
    var imageFromSourceSizeCallsCount: Int {
        get { imageFromSourceSizeCallsCountLock.withLock { imageFromSourceSizeUnderlyingCallsCount } }
        set { imageFromSourceSizeCallsCountLock.withLock { imageFromSourceSizeUnderlyingCallsCount = newValue } }
    }
    var imageFromSourceSizeCalled: Bool {
        return imageFromSourceSizeCallsCount > 0
    }
    private let imageFromSourceSizeReceivedArgumentsLock = NSLock()
    private var imageFromSourceSizeUnderlyingReceivedArguments: (source: MediaSourceProxy?, size: CGSize?)?
    var imageFromSourceSizeReceivedArguments: (source: MediaSourceProxy?, size: CGSize?)? {
        get { imageFromSourceSizeReceivedArgumentsLock.withLock { imageFromSourceSizeUnderlyingReceivedArguments } }
        set { imageFromSourceSizeReceivedArgumentsLock.withLock { imageFromSourceSizeUnderlyingReceivedArguments = newValue } }
    }
    private let imageFromSourceSizeReceivedInvocationsLock = NSLock()
    private var imageFromSourceSizeUnderlyingReceivedInvocations: [(source: MediaSourceProxy?, size: CGSize?)] = []
    var imageFromSourceSizeReceivedInvocations: [(source: MediaSourceProxy?, size: CGSize?)] {
        get { imageFromSourceSizeReceivedInvocationsLock.withLock { imageFromSourceSizeUnderlyingReceivedInvocations } }
        set { imageFromSourceSizeReceivedInvocationsLock.withLock { imageFromSourceSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let imageFromSourceSizeReturnValueLock = NSLock()
    private var imageFromSourceSizeUnderlyingReturnValue: UIImage?
    var imageFromSourceSizeReturnValue: UIImage? {
        get { imageFromSourceSizeReturnValueLock.withLock { imageFromSourceSizeUnderlyingReturnValue } }
        set { imageFromSourceSizeReturnValueLock.withLock { imageFromSourceSizeUnderlyingReturnValue = newValue } }
    }
    var imageFromSourceSizeClosure: ((MediaSourceProxy?, CGSize?) -> UIImage?)?

    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? {
        imageFromSourceSizeCallsCountLock.withLock { imageFromSourceSizeUnderlyingCallsCount += 1 }
        imageFromSourceSizeReceivedArguments = (source: source, size: size)
        imageFromSourceSizeReceivedInvocationsLock.withLock { imageFromSourceSizeUnderlyingReceivedInvocations.append((source: source, size: size)) }
        if let imageFromSourceSizeClosure = imageFromSourceSizeClosure {
            return imageFromSourceSizeClosure(source, size)
        } else {
            return imageFromSourceSizeReturnValue
        }
    }
    //MARK: - loadImageFromSource

    private let loadImageFromSourceSizeCallsCountLock = NSLock()
    private var loadImageFromSourceSizeUnderlyingCallsCount = 0
    var loadImageFromSourceSizeCallsCount: Int {
        get { loadImageFromSourceSizeCallsCountLock.withLock { loadImageFromSourceSizeUnderlyingCallsCount } }
        set { loadImageFromSourceSizeCallsCountLock.withLock { loadImageFromSourceSizeUnderlyingCallsCount = newValue } }
    }
    var loadImageFromSourceSizeCalled: Bool {
        return loadImageFromSourceSizeCallsCount > 0
    }
    private let loadImageFromSourceSizeReceivedArgumentsLock = NSLock()
    private var loadImageFromSourceSizeUnderlyingReceivedArguments: (source: MediaSourceProxy, size: CGSize?)?
    var loadImageFromSourceSizeReceivedArguments: (source: MediaSourceProxy, size: CGSize?)? {
        get { loadImageFromSourceSizeReceivedArgumentsLock.withLock { loadImageFromSourceSizeUnderlyingReceivedArguments } }
        set { loadImageFromSourceSizeReceivedArgumentsLock.withLock { loadImageFromSourceSizeUnderlyingReceivedArguments = newValue } }
    }
    private let loadImageFromSourceSizeReceivedInvocationsLock = NSLock()
    private var loadImageFromSourceSizeUnderlyingReceivedInvocations: [(source: MediaSourceProxy, size: CGSize?)] = []
    var loadImageFromSourceSizeReceivedInvocations: [(source: MediaSourceProxy, size: CGSize?)] {
        get { loadImageFromSourceSizeReceivedInvocationsLock.withLock { loadImageFromSourceSizeUnderlyingReceivedInvocations } }
        set { loadImageFromSourceSizeReceivedInvocationsLock.withLock { loadImageFromSourceSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let loadImageFromSourceSizeReturnValueLock = NSLock()
    private var loadImageFromSourceSizeUnderlyingReturnValue: Result<UIImage, MediaProviderError>!
    var loadImageFromSourceSizeReturnValue: Result<UIImage, MediaProviderError>! {
        get { loadImageFromSourceSizeReturnValueLock.withLock { loadImageFromSourceSizeUnderlyingReturnValue } }
        set { loadImageFromSourceSizeReturnValueLock.withLock { loadImageFromSourceSizeUnderlyingReturnValue = newValue } }
    }
    var loadImageFromSourceSizeClosure: ((MediaSourceProxy, CGSize?) async -> Result<UIImage, MediaProviderError>)?

    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        loadImageFromSourceSizeCallsCountLock.withLock { loadImageFromSourceSizeUnderlyingCallsCount += 1 }
        loadImageFromSourceSizeReceivedArguments = (source: source, size: size)
        loadImageFromSourceSizeReceivedInvocationsLock.withLock { loadImageFromSourceSizeUnderlyingReceivedInvocations.append((source: source, size: size)) }
        if let loadImageFromSourceSizeClosure = loadImageFromSourceSizeClosure {
            return await loadImageFromSourceSizeClosure(source, size)
        } else {
            return loadImageFromSourceSizeReturnValue
        }
    }
    //MARK: - loadImageDataFromSource

    private let loadImageDataFromSourceCallsCountLock = NSLock()
    private var loadImageDataFromSourceUnderlyingCallsCount = 0
    var loadImageDataFromSourceCallsCount: Int {
        get { loadImageDataFromSourceCallsCountLock.withLock { loadImageDataFromSourceUnderlyingCallsCount } }
        set { loadImageDataFromSourceCallsCountLock.withLock { loadImageDataFromSourceUnderlyingCallsCount = newValue } }
    }
    var loadImageDataFromSourceCalled: Bool {
        return loadImageDataFromSourceCallsCount > 0
    }
    private let loadImageDataFromSourceReceivedSourceLock = NSLock()
    private var loadImageDataFromSourceUnderlyingReceivedSource: MediaSourceProxy?
    var loadImageDataFromSourceReceivedSource: MediaSourceProxy? {
        get { loadImageDataFromSourceReceivedSourceLock.withLock { loadImageDataFromSourceUnderlyingReceivedSource } }
        set { loadImageDataFromSourceReceivedSourceLock.withLock { loadImageDataFromSourceUnderlyingReceivedSource = newValue } }
    }
    private let loadImageDataFromSourceReceivedInvocationsLock = NSLock()
    private var loadImageDataFromSourceUnderlyingReceivedInvocations: [MediaSourceProxy] = []
    var loadImageDataFromSourceReceivedInvocations: [MediaSourceProxy] {
        get { loadImageDataFromSourceReceivedInvocationsLock.withLock { loadImageDataFromSourceUnderlyingReceivedInvocations } }
        set { loadImageDataFromSourceReceivedInvocationsLock.withLock { loadImageDataFromSourceUnderlyingReceivedInvocations = newValue } }
    }

    private let loadImageDataFromSourceReturnValueLock = NSLock()
    private var loadImageDataFromSourceUnderlyingReturnValue: Result<Data, MediaProviderError>!
    var loadImageDataFromSourceReturnValue: Result<Data, MediaProviderError>! {
        get { loadImageDataFromSourceReturnValueLock.withLock { loadImageDataFromSourceUnderlyingReturnValue } }
        set { loadImageDataFromSourceReturnValueLock.withLock { loadImageDataFromSourceUnderlyingReturnValue = newValue } }
    }
    var loadImageDataFromSourceClosure: ((MediaSourceProxy) async -> Result<Data, MediaProviderError>)?

    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError> {
        loadImageDataFromSourceCallsCountLock.withLock { loadImageDataFromSourceUnderlyingCallsCount += 1 }
        loadImageDataFromSourceReceivedSource = source
        loadImageDataFromSourceReceivedInvocationsLock.withLock { loadImageDataFromSourceUnderlyingReceivedInvocations.append(source) }
        if let loadImageDataFromSourceClosure = loadImageDataFromSourceClosure {
            return await loadImageDataFromSourceClosure(source)
        } else {
            return loadImageDataFromSourceReturnValue
        }
    }
    //MARK: - loadImageRetryingOnReconnection

    private let loadImageRetryingOnReconnectionSizeCallsCountLock = NSLock()
    private var loadImageRetryingOnReconnectionSizeUnderlyingCallsCount = 0
    var loadImageRetryingOnReconnectionSizeCallsCount: Int {
        get { loadImageRetryingOnReconnectionSizeCallsCountLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingCallsCount } }
        set { loadImageRetryingOnReconnectionSizeCallsCountLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingCallsCount = newValue } }
    }
    var loadImageRetryingOnReconnectionSizeCalled: Bool {
        return loadImageRetryingOnReconnectionSizeCallsCount > 0
    }
    private let loadImageRetryingOnReconnectionSizeReceivedArgumentsLock = NSLock()
    private var loadImageRetryingOnReconnectionSizeUnderlyingReceivedArguments: (source: MediaSourceProxy, size: CGSize?)?
    var loadImageRetryingOnReconnectionSizeReceivedArguments: (source: MediaSourceProxy, size: CGSize?)? {
        get { loadImageRetryingOnReconnectionSizeReceivedArgumentsLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReceivedArguments } }
        set { loadImageRetryingOnReconnectionSizeReceivedArgumentsLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReceivedArguments = newValue } }
    }
    private let loadImageRetryingOnReconnectionSizeReceivedInvocationsLock = NSLock()
    private var loadImageRetryingOnReconnectionSizeUnderlyingReceivedInvocations: [(source: MediaSourceProxy, size: CGSize?)] = []
    var loadImageRetryingOnReconnectionSizeReceivedInvocations: [(source: MediaSourceProxy, size: CGSize?)] {
        get { loadImageRetryingOnReconnectionSizeReceivedInvocationsLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReceivedInvocations } }
        set { loadImageRetryingOnReconnectionSizeReceivedInvocationsLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let loadImageRetryingOnReconnectionSizeReturnValueLock = NSLock()
    private var loadImageRetryingOnReconnectionSizeUnderlyingReturnValue: Task<UIImage, Error>!
    var loadImageRetryingOnReconnectionSizeReturnValue: Task<UIImage, Error>! {
        get { loadImageRetryingOnReconnectionSizeReturnValueLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReturnValue } }
        set { loadImageRetryingOnReconnectionSizeReturnValueLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReturnValue = newValue } }
    }
    var loadImageRetryingOnReconnectionSizeClosure: ((MediaSourceProxy, CGSize?) -> Task<UIImage, Error>)?

    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy, size: CGSize?) -> Task<UIImage, Error> {
        loadImageRetryingOnReconnectionSizeCallsCountLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingCallsCount += 1 }
        loadImageRetryingOnReconnectionSizeReceivedArguments = (source: source, size: size)
        loadImageRetryingOnReconnectionSizeReceivedInvocationsLock.withLock { loadImageRetryingOnReconnectionSizeUnderlyingReceivedInvocations.append((source: source, size: size)) }
        if let loadImageRetryingOnReconnectionSizeClosure = loadImageRetryingOnReconnectionSizeClosure {
            return loadImageRetryingOnReconnectionSizeClosure(source, size)
        } else {
            return loadImageRetryingOnReconnectionSizeReturnValue
        }
    }
    //MARK: - loadThumbnailForSource

    private let loadThumbnailForSourceSourceSizeCallsCountLock = NSLock()
    private var loadThumbnailForSourceSourceSizeUnderlyingCallsCount = 0
    var loadThumbnailForSourceSourceSizeCallsCount: Int {
        get { loadThumbnailForSourceSourceSizeCallsCountLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingCallsCount } }
        set { loadThumbnailForSourceSourceSizeCallsCountLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingCallsCount = newValue } }
    }
    var loadThumbnailForSourceSourceSizeCalled: Bool {
        return loadThumbnailForSourceSourceSizeCallsCount > 0
    }
    private let loadThumbnailForSourceSourceSizeReceivedArgumentsLock = NSLock()
    private var loadThumbnailForSourceSourceSizeUnderlyingReceivedArguments: (source: MediaSourceProxy, size: CGSize)?
    var loadThumbnailForSourceSourceSizeReceivedArguments: (source: MediaSourceProxy, size: CGSize)? {
        get { loadThumbnailForSourceSourceSizeReceivedArgumentsLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReceivedArguments } }
        set { loadThumbnailForSourceSourceSizeReceivedArgumentsLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReceivedArguments = newValue } }
    }
    private let loadThumbnailForSourceSourceSizeReceivedInvocationsLock = NSLock()
    private var loadThumbnailForSourceSourceSizeUnderlyingReceivedInvocations: [(source: MediaSourceProxy, size: CGSize)] = []
    var loadThumbnailForSourceSourceSizeReceivedInvocations: [(source: MediaSourceProxy, size: CGSize)] {
        get { loadThumbnailForSourceSourceSizeReceivedInvocationsLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReceivedInvocations } }
        set { loadThumbnailForSourceSourceSizeReceivedInvocationsLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let loadThumbnailForSourceSourceSizeReturnValueLock = NSLock()
    private var loadThumbnailForSourceSourceSizeUnderlyingReturnValue: Result<Data, MediaProviderError>!
    var loadThumbnailForSourceSourceSizeReturnValue: Result<Data, MediaProviderError>! {
        get { loadThumbnailForSourceSourceSizeReturnValueLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReturnValue } }
        set { loadThumbnailForSourceSourceSizeReturnValueLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReturnValue = newValue } }
    }
    var loadThumbnailForSourceSourceSizeClosure: ((MediaSourceProxy, CGSize) async -> Result<Data, MediaProviderError>)?

    func loadThumbnailForSource(source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError> {
        loadThumbnailForSourceSourceSizeCallsCountLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingCallsCount += 1 }
        loadThumbnailForSourceSourceSizeReceivedArguments = (source: source, size: size)
        loadThumbnailForSourceSourceSizeReceivedInvocationsLock.withLock { loadThumbnailForSourceSourceSizeUnderlyingReceivedInvocations.append((source: source, size: size)) }
        if let loadThumbnailForSourceSourceSizeClosure = loadThumbnailForSourceSourceSizeClosure {
            return await loadThumbnailForSourceSourceSizeClosure(source, size)
        } else {
            return loadThumbnailForSourceSourceSizeReturnValue
        }
    }
    //MARK: - loadFileFromSource

    private let loadFileFromSourceFilenameCallsCountLock = NSLock()
    private var loadFileFromSourceFilenameUnderlyingCallsCount = 0
    var loadFileFromSourceFilenameCallsCount: Int {
        get { loadFileFromSourceFilenameCallsCountLock.withLock { loadFileFromSourceFilenameUnderlyingCallsCount } }
        set { loadFileFromSourceFilenameCallsCountLock.withLock { loadFileFromSourceFilenameUnderlyingCallsCount = newValue } }
    }
    var loadFileFromSourceFilenameCalled: Bool {
        return loadFileFromSourceFilenameCallsCount > 0
    }
    private let loadFileFromSourceFilenameReceivedArgumentsLock = NSLock()
    private var loadFileFromSourceFilenameUnderlyingReceivedArguments: (source: MediaSourceProxy, filename: String?)?
    var loadFileFromSourceFilenameReceivedArguments: (source: MediaSourceProxy, filename: String?)? {
        get { loadFileFromSourceFilenameReceivedArgumentsLock.withLock { loadFileFromSourceFilenameUnderlyingReceivedArguments } }
        set { loadFileFromSourceFilenameReceivedArgumentsLock.withLock { loadFileFromSourceFilenameUnderlyingReceivedArguments = newValue } }
    }
    private let loadFileFromSourceFilenameReceivedInvocationsLock = NSLock()
    private var loadFileFromSourceFilenameUnderlyingReceivedInvocations: [(source: MediaSourceProxy, filename: String?)] = []
    var loadFileFromSourceFilenameReceivedInvocations: [(source: MediaSourceProxy, filename: String?)] {
        get { loadFileFromSourceFilenameReceivedInvocationsLock.withLock { loadFileFromSourceFilenameUnderlyingReceivedInvocations } }
        set { loadFileFromSourceFilenameReceivedInvocationsLock.withLock { loadFileFromSourceFilenameUnderlyingReceivedInvocations = newValue } }
    }

    private let loadFileFromSourceFilenameReturnValueLock = NSLock()
    private var loadFileFromSourceFilenameUnderlyingReturnValue: Result<MediaFileHandleProxy, MediaProviderError>!
    var loadFileFromSourceFilenameReturnValue: Result<MediaFileHandleProxy, MediaProviderError>! {
        get { loadFileFromSourceFilenameReturnValueLock.withLock { loadFileFromSourceFilenameUnderlyingReturnValue } }
        set { loadFileFromSourceFilenameReturnValueLock.withLock { loadFileFromSourceFilenameUnderlyingReturnValue = newValue } }
    }
    var loadFileFromSourceFilenameClosure: ((MediaSourceProxy, String?) async -> Result<MediaFileHandleProxy, MediaProviderError>)?

    func loadFileFromSource(_ source: MediaSourceProxy, filename: String?) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        loadFileFromSourceFilenameCallsCountLock.withLock { loadFileFromSourceFilenameUnderlyingCallsCount += 1 }
        loadFileFromSourceFilenameReceivedArguments = (source: source, filename: filename)
        loadFileFromSourceFilenameReceivedInvocationsLock.withLock { loadFileFromSourceFilenameUnderlyingReceivedInvocations.append((source: source, filename: filename)) }
        if let loadFileFromSourceFilenameClosure = loadFileFromSourceFilenameClosure {
            return await loadFileFromSourceFilenameClosure(source, filename)
        } else {
            return loadFileFromSourceFilenameReturnValue
        }
    }
}
class NSEUserSessionMock: NSEUserSessionProtocol, @unchecked Sendable {
    var inviteAvatarsVisibilityCallsCount = 0
    var inviteAvatarsVisibilityCalled: Bool {
        return inviteAvatarsVisibilityCallsCount > 0
    }

    var inviteAvatarsVisibility: InviteAvatars {
        get async {
            inviteAvatarsVisibilityCallsCount += 1
            if let inviteAvatarsVisibilityClosure = inviteAvatarsVisibilityClosure {
                return await inviteAvatarsVisibilityClosure()
            } else {
                return underlyingInviteAvatarsVisibility
            }
        }
    }
    var underlyingInviteAvatarsVisibility: InviteAvatars!
    var inviteAvatarsVisibilityClosure: (() async -> InviteAvatars)?
    var mediaPreviewVisibilityCallsCount = 0
    var mediaPreviewVisibilityCalled: Bool {
        return mediaPreviewVisibilityCallsCount > 0
    }

    var mediaPreviewVisibility: MediaPreviews {
        get async {
            mediaPreviewVisibilityCallsCount += 1
            if let mediaPreviewVisibilityClosure = mediaPreviewVisibilityClosure {
                return await mediaPreviewVisibilityClosure()
            } else {
                return underlyingMediaPreviewVisibility
            }
        }
    }
    var underlyingMediaPreviewVisibility: MediaPreviews!
    var mediaPreviewVisibilityClosure: (() async -> MediaPreviews)?
    var threadsEnabled: Bool {
        get { return underlyingThreadsEnabled }
        set(value) { underlyingThreadsEnabled = value }
    }
    var underlyingThreadsEnabled: Bool!

    //MARK: - notificationItemProxy

    private let notificationItemProxyRoomIDEventIDCallsCountLock = NSLock()
    private var notificationItemProxyRoomIDEventIDUnderlyingCallsCount = 0
    var notificationItemProxyRoomIDEventIDCallsCount: Int {
        get { notificationItemProxyRoomIDEventIDCallsCountLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingCallsCount } }
        set { notificationItemProxyRoomIDEventIDCallsCountLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingCallsCount = newValue } }
    }
    var notificationItemProxyRoomIDEventIDCalled: Bool {
        return notificationItemProxyRoomIDEventIDCallsCount > 0
    }
    private let notificationItemProxyRoomIDEventIDReceivedArgumentsLock = NSLock()
    private var notificationItemProxyRoomIDEventIDUnderlyingReceivedArguments: (roomID: String, eventID: String)?
    var notificationItemProxyRoomIDEventIDReceivedArguments: (roomID: String, eventID: String)? {
        get { notificationItemProxyRoomIDEventIDReceivedArgumentsLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReceivedArguments } }
        set { notificationItemProxyRoomIDEventIDReceivedArgumentsLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReceivedArguments = newValue } }
    }
    private let notificationItemProxyRoomIDEventIDReceivedInvocationsLock = NSLock()
    private var notificationItemProxyRoomIDEventIDUnderlyingReceivedInvocations: [(roomID: String, eventID: String)] = []
    var notificationItemProxyRoomIDEventIDReceivedInvocations: [(roomID: String, eventID: String)] {
        get { notificationItemProxyRoomIDEventIDReceivedInvocationsLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReceivedInvocations } }
        set { notificationItemProxyRoomIDEventIDReceivedInvocationsLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let notificationItemProxyRoomIDEventIDReturnValueLock = NSLock()
    private var notificationItemProxyRoomIDEventIDUnderlyingReturnValue: NotificationItemProxyProtocol?
    var notificationItemProxyRoomIDEventIDReturnValue: NotificationItemProxyProtocol? {
        get { notificationItemProxyRoomIDEventIDReturnValueLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReturnValue } }
        set { notificationItemProxyRoomIDEventIDReturnValueLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReturnValue = newValue } }
    }
    var notificationItemProxyRoomIDEventIDClosure: ((String, String) async -> NotificationItemProxyProtocol?)?

    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        notificationItemProxyRoomIDEventIDCallsCountLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingCallsCount += 1 }
        notificationItemProxyRoomIDEventIDReceivedArguments = (roomID: roomID, eventID: eventID)
        notificationItemProxyRoomIDEventIDReceivedInvocationsLock.withLock { notificationItemProxyRoomIDEventIDUnderlyingReceivedInvocations.append((roomID: roomID, eventID: eventID)) }
        if let notificationItemProxyRoomIDEventIDClosure = notificationItemProxyRoomIDEventIDClosure {
            return await notificationItemProxyRoomIDEventIDClosure(roomID, eventID)
        } else {
            return notificationItemProxyRoomIDEventIDReturnValue
        }
    }
    //MARK: - roomForIdentifier

    private let roomForIdentifierCallsCountLock = NSLock()
    private var roomForIdentifierUnderlyingCallsCount = 0
    var roomForIdentifierCallsCount: Int {
        get { roomForIdentifierCallsCountLock.withLock { roomForIdentifierUnderlyingCallsCount } }
        set { roomForIdentifierCallsCountLock.withLock { roomForIdentifierUnderlyingCallsCount = newValue } }
    }
    var roomForIdentifierCalled: Bool {
        return roomForIdentifierCallsCount > 0
    }
    private let roomForIdentifierReceivedRoomIDLock = NSLock()
    private var roomForIdentifierUnderlyingReceivedRoomID: String?
    var roomForIdentifierReceivedRoomID: String? {
        get { roomForIdentifierReceivedRoomIDLock.withLock { roomForIdentifierUnderlyingReceivedRoomID } }
        set { roomForIdentifierReceivedRoomIDLock.withLock { roomForIdentifierUnderlyingReceivedRoomID = newValue } }
    }
    private let roomForIdentifierReceivedInvocationsLock = NSLock()
    private var roomForIdentifierUnderlyingReceivedInvocations: [String] = []
    var roomForIdentifierReceivedInvocations: [String] {
        get { roomForIdentifierReceivedInvocationsLock.withLock { roomForIdentifierUnderlyingReceivedInvocations } }
        set { roomForIdentifierReceivedInvocationsLock.withLock { roomForIdentifierUnderlyingReceivedInvocations = newValue } }
    }

    private let roomForIdentifierReturnValueLock = NSLock()
    private var roomForIdentifierUnderlyingReturnValue: Room?
    var roomForIdentifierReturnValue: Room? {
        get { roomForIdentifierReturnValueLock.withLock { roomForIdentifierUnderlyingReturnValue } }
        set { roomForIdentifierReturnValueLock.withLock { roomForIdentifierUnderlyingReturnValue = newValue } }
    }
    var roomForIdentifierClosure: ((String) -> Room?)?

    func roomForIdentifier(_ roomID: String) -> Room? {
        roomForIdentifierCallsCountLock.withLock { roomForIdentifierUnderlyingCallsCount += 1 }
        roomForIdentifierReceivedRoomID = roomID
        roomForIdentifierReceivedInvocationsLock.withLock { roomForIdentifierUnderlyingReceivedInvocations.append(roomID) }
        if let roomForIdentifierClosure = roomForIdentifierClosure {
            return roomForIdentifierClosure(roomID)
        } else {
            return roomForIdentifierReturnValue
        }
    }
}
class NetworkMonitorMock: NetworkMonitorProtocol, @unchecked Sendable {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> {
        get { return underlyingReachabilityPublisher }
        set(value) { underlyingReachabilityPublisher = value }
    }
    var underlyingReachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never>!

}
class NotificationItemProxyMock: NotificationItemProxyProtocol, @unchecked Sendable {
    var event: NotificationEvent?
    var senderID: String {
        get { return underlyingSenderID }
        set(value) { underlyingSenderID = value }
    }
    var underlyingSenderID: String!
    var roomID: String {
        get { return underlyingRoomID }
        set(value) { underlyingRoomID = value }
    }
    var underlyingRoomID: String!
    var receiverID: String {
        get { return underlyingReceiverID }
        set(value) { underlyingReceiverID = value }
    }
    var underlyingReceiverID: String!
    var senderDisplayName: String?
    var senderAvatarMediaSource: MediaSourceProxy?
    var roomDisplayName: String {
        get { return underlyingRoomDisplayName }
        set(value) { underlyingRoomDisplayName = value }
    }
    var underlyingRoomDisplayName: String!
    var roomAvatarMediaSource: MediaSourceProxy?
    var roomJoinedMembers: Int {
        get { return underlyingRoomJoinedMembers }
        set(value) { underlyingRoomJoinedMembers = value }
    }
    var underlyingRoomJoinedMembers: Int!
    var isRoomSpace: Bool {
        get { return underlyingIsRoomSpace }
        set(value) { underlyingIsRoomSpace = value }
    }
    var underlyingIsRoomSpace: Bool!
    var isRoomDirect: Bool {
        get { return underlyingIsRoomDirect }
        set(value) { underlyingIsRoomDirect = value }
    }
    var underlyingIsRoomDirect: Bool!
    var isRoomPrivate: Bool {
        get { return underlyingIsRoomPrivate }
        set(value) { underlyingIsRoomPrivate = value }
    }
    var underlyingIsRoomPrivate: Bool!
    var isDM: Bool {
        get { return underlyingIsDM }
        set(value) { underlyingIsDM = value }
    }
    var underlyingIsDM: Bool!
    var isNoisy: Bool {
        get { return underlyingIsNoisy }
        set(value) { underlyingIsNoisy = value }
    }
    var underlyingIsNoisy: Bool!
    var hasMention: Bool {
        get { return underlyingHasMention }
        set(value) { underlyingHasMention = value }
    }
    var underlyingHasMention: Bool!
    var threadRootEventID: String?

}
class NotificationManagerMock: NotificationManagerProtocol, @unchecked Sendable {
    weak var delegate: NotificationManagerDelegate?

    //MARK: - start

    private let startCallsCountLock = NSLock()
    private var startUnderlyingCallsCount = 0
    var startCallsCount: Int {
        get { startCallsCountLock.withLock { startUnderlyingCallsCount } }
        set { startCallsCountLock.withLock { startUnderlyingCallsCount = newValue } }
    }
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCountLock.withLock { startUnderlyingCallsCount += 1 }
        startClosure?()
    }
    //MARK: - register

    private let registerWithCallsCountLock = NSLock()
    private var registerWithUnderlyingCallsCount = 0
    var registerWithCallsCount: Int {
        get { registerWithCallsCountLock.withLock { registerWithUnderlyingCallsCount } }
        set { registerWithCallsCountLock.withLock { registerWithUnderlyingCallsCount = newValue } }
    }
    var registerWithCalled: Bool {
        return registerWithCallsCount > 0
    }
    private let registerWithReceivedDeviceTokenLock = NSLock()
    private var registerWithUnderlyingReceivedDeviceToken: Data?
    var registerWithReceivedDeviceToken: Data? {
        get { registerWithReceivedDeviceTokenLock.withLock { registerWithUnderlyingReceivedDeviceToken } }
        set { registerWithReceivedDeviceTokenLock.withLock { registerWithUnderlyingReceivedDeviceToken = newValue } }
    }
    private let registerWithReceivedInvocationsLock = NSLock()
    private var registerWithUnderlyingReceivedInvocations: [Data] = []
    var registerWithReceivedInvocations: [Data] {
        get { registerWithReceivedInvocationsLock.withLock { registerWithUnderlyingReceivedInvocations } }
        set { registerWithReceivedInvocationsLock.withLock { registerWithUnderlyingReceivedInvocations = newValue } }
    }

    private let registerWithReturnValueLock = NSLock()
    private var registerWithUnderlyingReturnValue: Bool!
    var registerWithReturnValue: Bool! {
        get { registerWithReturnValueLock.withLock { registerWithUnderlyingReturnValue } }
        set { registerWithReturnValueLock.withLock { registerWithUnderlyingReturnValue = newValue } }
    }
    var registerWithClosure: ((Data) async -> Bool)?

    func register(with deviceToken: Data) async -> Bool {
        registerWithCallsCountLock.withLock { registerWithUnderlyingCallsCount += 1 }
        registerWithReceivedDeviceToken = deviceToken
        registerWithReceivedInvocationsLock.withLock { registerWithUnderlyingReceivedInvocations.append(deviceToken) }
        if let registerWithClosure = registerWithClosure {
            return await registerWithClosure(deviceToken)
        } else {
            return registerWithReturnValue
        }
    }
    //MARK: - registrationFailed

    private let registrationFailedWithCallsCountLock = NSLock()
    private var registrationFailedWithUnderlyingCallsCount = 0
    var registrationFailedWithCallsCount: Int {
        get { registrationFailedWithCallsCountLock.withLock { registrationFailedWithUnderlyingCallsCount } }
        set { registrationFailedWithCallsCountLock.withLock { registrationFailedWithUnderlyingCallsCount = newValue } }
    }
    var registrationFailedWithCalled: Bool {
        return registrationFailedWithCallsCount > 0
    }
    private let registrationFailedWithReceivedErrorLock = NSLock()
    private var registrationFailedWithUnderlyingReceivedError: Error?
    var registrationFailedWithReceivedError: Error? {
        get { registrationFailedWithReceivedErrorLock.withLock { registrationFailedWithUnderlyingReceivedError } }
        set { registrationFailedWithReceivedErrorLock.withLock { registrationFailedWithUnderlyingReceivedError = newValue } }
    }
    private let registrationFailedWithReceivedInvocationsLock = NSLock()
    private var registrationFailedWithUnderlyingReceivedInvocations: [Error] = []
    var registrationFailedWithReceivedInvocations: [Error] {
        get { registrationFailedWithReceivedInvocationsLock.withLock { registrationFailedWithUnderlyingReceivedInvocations } }
        set { registrationFailedWithReceivedInvocationsLock.withLock { registrationFailedWithUnderlyingReceivedInvocations = newValue } }
    }
    var registrationFailedWithClosure: ((Error) -> Void)?

    func registrationFailed(with error: Error) {
        registrationFailedWithCallsCountLock.withLock { registrationFailedWithUnderlyingCallsCount += 1 }
        registrationFailedWithReceivedError = error
        registrationFailedWithReceivedInvocationsLock.withLock { registrationFailedWithUnderlyingReceivedInvocations.append(error) }
        registrationFailedWithClosure?(error)
    }
    //MARK: - showLocalNotification

    private let showLocalNotificationWithSubtitleCallsCountLock = NSLock()
    private var showLocalNotificationWithSubtitleUnderlyingCallsCount = 0
    var showLocalNotificationWithSubtitleCallsCount: Int {
        get { showLocalNotificationWithSubtitleCallsCountLock.withLock { showLocalNotificationWithSubtitleUnderlyingCallsCount } }
        set { showLocalNotificationWithSubtitleCallsCountLock.withLock { showLocalNotificationWithSubtitleUnderlyingCallsCount = newValue } }
    }
    var showLocalNotificationWithSubtitleCalled: Bool {
        return showLocalNotificationWithSubtitleCallsCount > 0
    }
    private let showLocalNotificationWithSubtitleReceivedArgumentsLock = NSLock()
    private var showLocalNotificationWithSubtitleUnderlyingReceivedArguments: (title: String, subtitle: String?)?
    var showLocalNotificationWithSubtitleReceivedArguments: (title: String, subtitle: String?)? {
        get { showLocalNotificationWithSubtitleReceivedArgumentsLock.withLock { showLocalNotificationWithSubtitleUnderlyingReceivedArguments } }
        set { showLocalNotificationWithSubtitleReceivedArgumentsLock.withLock { showLocalNotificationWithSubtitleUnderlyingReceivedArguments = newValue } }
    }
    private let showLocalNotificationWithSubtitleReceivedInvocationsLock = NSLock()
    private var showLocalNotificationWithSubtitleUnderlyingReceivedInvocations: [(title: String, subtitle: String?)] = []
    var showLocalNotificationWithSubtitleReceivedInvocations: [(title: String, subtitle: String?)] {
        get { showLocalNotificationWithSubtitleReceivedInvocationsLock.withLock { showLocalNotificationWithSubtitleUnderlyingReceivedInvocations } }
        set { showLocalNotificationWithSubtitleReceivedInvocationsLock.withLock { showLocalNotificationWithSubtitleUnderlyingReceivedInvocations = newValue } }
    }
    var showLocalNotificationWithSubtitleClosure: ((String, String?) async -> Void)?

    func showLocalNotification(with title: String, subtitle: String?) async {
        showLocalNotificationWithSubtitleCallsCountLock.withLock { showLocalNotificationWithSubtitleUnderlyingCallsCount += 1 }
        showLocalNotificationWithSubtitleReceivedArguments = (title: title, subtitle: subtitle)
        showLocalNotificationWithSubtitleReceivedInvocationsLock.withLock { showLocalNotificationWithSubtitleUnderlyingReceivedInvocations.append((title: title, subtitle: subtitle)) }
        await showLocalNotificationWithSubtitleClosure?(title, subtitle)
    }
    //MARK: - setUserSession

    private let setUserSessionCallsCountLock = NSLock()
    private var setUserSessionUnderlyingCallsCount = 0
    var setUserSessionCallsCount: Int {
        get { setUserSessionCallsCountLock.withLock { setUserSessionUnderlyingCallsCount } }
        set { setUserSessionCallsCountLock.withLock { setUserSessionUnderlyingCallsCount = newValue } }
    }
    var setUserSessionCalled: Bool {
        return setUserSessionCallsCount > 0
    }
    private let setUserSessionReceivedUserSessionLock = NSLock()
    private var setUserSessionUnderlyingReceivedUserSession: UserSessionProtocol?
    var setUserSessionReceivedUserSession: UserSessionProtocol? {
        get { setUserSessionReceivedUserSessionLock.withLock { setUserSessionUnderlyingReceivedUserSession } }
        set { setUserSessionReceivedUserSessionLock.withLock { setUserSessionUnderlyingReceivedUserSession = newValue } }
    }
    private let setUserSessionReceivedInvocationsLock = NSLock()
    private var setUserSessionUnderlyingReceivedInvocations: [UserSessionProtocol?] = []
    var setUserSessionReceivedInvocations: [UserSessionProtocol?] {
        get { setUserSessionReceivedInvocationsLock.withLock { setUserSessionUnderlyingReceivedInvocations } }
        set { setUserSessionReceivedInvocationsLock.withLock { setUserSessionUnderlyingReceivedInvocations = newValue } }
    }
    var setUserSessionClosure: ((UserSessionProtocol?) -> Void)?

    func setUserSession(_ userSession: UserSessionProtocol?) {
        setUserSessionCallsCountLock.withLock { setUserSessionUnderlyingCallsCount += 1 }
        setUserSessionReceivedUserSession = userSession
        setUserSessionReceivedInvocationsLock.withLock { setUserSessionUnderlyingReceivedInvocations.append(userSession) }
        setUserSessionClosure?(userSession)
    }
    //MARK: - requestAuthorization

    private let requestAuthorizationCallsCountLock = NSLock()
    private var requestAuthorizationUnderlyingCallsCount = 0
    var requestAuthorizationCallsCount: Int {
        get { requestAuthorizationCallsCountLock.withLock { requestAuthorizationUnderlyingCallsCount } }
        set { requestAuthorizationCallsCountLock.withLock { requestAuthorizationUnderlyingCallsCount = newValue } }
    }
    var requestAuthorizationCalled: Bool {
        return requestAuthorizationCallsCount > 0
    }
    var requestAuthorizationClosure: (() -> Void)?

    func requestAuthorization() {
        requestAuthorizationCallsCountLock.withLock { requestAuthorizationUnderlyingCallsCount += 1 }
        requestAuthorizationClosure?()
    }
    //MARK: - removeDeliveredMessageNotifications

    private let removeDeliveredMessageNotificationsForCallsCountLock = NSLock()
    private var removeDeliveredMessageNotificationsForUnderlyingCallsCount = 0
    var removeDeliveredMessageNotificationsForCallsCount: Int {
        get { removeDeliveredMessageNotificationsForCallsCountLock.withLock { removeDeliveredMessageNotificationsForUnderlyingCallsCount } }
        set { removeDeliveredMessageNotificationsForCallsCountLock.withLock { removeDeliveredMessageNotificationsForUnderlyingCallsCount = newValue } }
    }
    var removeDeliveredMessageNotificationsForCalled: Bool {
        return removeDeliveredMessageNotificationsForCallsCount > 0
    }
    private let removeDeliveredMessageNotificationsForReceivedRoomIDLock = NSLock()
    private var removeDeliveredMessageNotificationsForUnderlyingReceivedRoomID: String?
    var removeDeliveredMessageNotificationsForReceivedRoomID: String? {
        get { removeDeliveredMessageNotificationsForReceivedRoomIDLock.withLock { removeDeliveredMessageNotificationsForUnderlyingReceivedRoomID } }
        set { removeDeliveredMessageNotificationsForReceivedRoomIDLock.withLock { removeDeliveredMessageNotificationsForUnderlyingReceivedRoomID = newValue } }
    }
    private let removeDeliveredMessageNotificationsForReceivedInvocationsLock = NSLock()
    private var removeDeliveredMessageNotificationsForUnderlyingReceivedInvocations: [String] = []
    var removeDeliveredMessageNotificationsForReceivedInvocations: [String] {
        get { removeDeliveredMessageNotificationsForReceivedInvocationsLock.withLock { removeDeliveredMessageNotificationsForUnderlyingReceivedInvocations } }
        set { removeDeliveredMessageNotificationsForReceivedInvocationsLock.withLock { removeDeliveredMessageNotificationsForUnderlyingReceivedInvocations = newValue } }
    }
    var removeDeliveredMessageNotificationsForClosure: ((String) async -> Void)?

    func removeDeliveredMessageNotifications(for roomID: String) async {
        removeDeliveredMessageNotificationsForCallsCountLock.withLock { removeDeliveredMessageNotificationsForUnderlyingCallsCount += 1 }
        removeDeliveredMessageNotificationsForReceivedRoomID = roomID
        removeDeliveredMessageNotificationsForReceivedInvocationsLock.withLock { removeDeliveredMessageNotificationsForUnderlyingReceivedInvocations.append(roomID) }
        await removeDeliveredMessageNotificationsForClosure?(roomID)
    }
    //MARK: - removeDeliveredNotificationsForFullyReadRooms

    private let removeDeliveredNotificationsForFullyReadRoomsCallsCountLock = NSLock()
    private var removeDeliveredNotificationsForFullyReadRoomsUnderlyingCallsCount = 0
    var removeDeliveredNotificationsForFullyReadRoomsCallsCount: Int {
        get { removeDeliveredNotificationsForFullyReadRoomsCallsCountLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingCallsCount } }
        set { removeDeliveredNotificationsForFullyReadRoomsCallsCountLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingCallsCount = newValue } }
    }
    var removeDeliveredNotificationsForFullyReadRoomsCalled: Bool {
        return removeDeliveredNotificationsForFullyReadRoomsCallsCount > 0
    }
    private let removeDeliveredNotificationsForFullyReadRoomsReceivedRoomsLock = NSLock()
    private var removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedRooms: [RoomSummary]?
    var removeDeliveredNotificationsForFullyReadRoomsReceivedRooms: [RoomSummary]? {
        get { removeDeliveredNotificationsForFullyReadRoomsReceivedRoomsLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedRooms } }
        set { removeDeliveredNotificationsForFullyReadRoomsReceivedRoomsLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedRooms = newValue } }
    }
    private let removeDeliveredNotificationsForFullyReadRoomsReceivedInvocationsLock = NSLock()
    private var removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedInvocations: [[RoomSummary]] = []
    var removeDeliveredNotificationsForFullyReadRoomsReceivedInvocations: [[RoomSummary]] {
        get { removeDeliveredNotificationsForFullyReadRoomsReceivedInvocationsLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedInvocations } }
        set { removeDeliveredNotificationsForFullyReadRoomsReceivedInvocationsLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedInvocations = newValue } }
    }
    var removeDeliveredNotificationsForFullyReadRoomsClosure: (([RoomSummary]) async -> Void)?

    func removeDeliveredNotificationsForFullyReadRooms(_ rooms: [RoomSummary]) async {
        removeDeliveredNotificationsForFullyReadRoomsCallsCountLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingCallsCount += 1 }
        removeDeliveredNotificationsForFullyReadRoomsReceivedRooms = rooms
        removeDeliveredNotificationsForFullyReadRoomsReceivedInvocationsLock.withLock { removeDeliveredNotificationsForFullyReadRoomsUnderlyingReceivedInvocations.append(rooms) }
        await removeDeliveredNotificationsForFullyReadRoomsClosure?(rooms)
    }
}
class NotificationSettingsProxyMock: NotificationSettingsProxyProtocol, @unchecked Sendable {
    var callbacks: PassthroughSubject<NotificationSettingsProxyCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<NotificationSettingsProxyCallback, Never>!

    //MARK: - getNotificationSettings

    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    private let getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCountLock = NSLock()
    private var getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount: Int {
        get { getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCountLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount } }
        set { getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCountLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue } }
    }
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    private let getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArgumentsLock = NSLock()
    private var getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)? {
        get { getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArgumentsLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedArguments } }
        set { getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArgumentsLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedArguments = newValue } }
    }
    private let getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock = NSLock()
    private var getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] {
        get { getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations } }
        set { getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations = newValue } }
    }

    private let getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValueLock = NSLock()
    private var getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue: RoomNotificationSettingsProxyProtocol!
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue: RoomNotificationSettingsProxyProtocol! {
        get { getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValueLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue } }
        set { getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValueLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReturnValue = newValue } }
    }
    var getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> RoomNotificationSettingsProxyProtocol)?

    func getNotificationSettings(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws -> RoomNotificationSettingsProxyProtocol {
        if let error = getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError {
            throw error
        }
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneCallsCountLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount += 1 }
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { getNotificationSettingsRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)) }
        if let getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure = getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure {
            return try await getNotificationSettingsRoomIdIsEncryptedIsOneToOneClosure(roomId, isEncrypted, isOneToOne)
        } else {
            return getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue
        }
    }
    //MARK: - setNotificationMode

    var setNotificationModeRoomIdModeThrowableError: Error?
    private let setNotificationModeRoomIdModeCallsCountLock = NSLock()
    private var setNotificationModeRoomIdModeUnderlyingCallsCount = 0
    var setNotificationModeRoomIdModeCallsCount: Int {
        get { setNotificationModeRoomIdModeCallsCountLock.withLock { setNotificationModeRoomIdModeUnderlyingCallsCount } }
        set { setNotificationModeRoomIdModeCallsCountLock.withLock { setNotificationModeRoomIdModeUnderlyingCallsCount = newValue } }
    }
    var setNotificationModeRoomIdModeCalled: Bool {
        return setNotificationModeRoomIdModeCallsCount > 0
    }
    private let setNotificationModeRoomIdModeReceivedArgumentsLock = NSLock()
    private var setNotificationModeRoomIdModeUnderlyingReceivedArguments: (roomId: String, mode: RoomNotificationModeProxy)?
    var setNotificationModeRoomIdModeReceivedArguments: (roomId: String, mode: RoomNotificationModeProxy)? {
        get { setNotificationModeRoomIdModeReceivedArgumentsLock.withLock { setNotificationModeRoomIdModeUnderlyingReceivedArguments } }
        set { setNotificationModeRoomIdModeReceivedArgumentsLock.withLock { setNotificationModeRoomIdModeUnderlyingReceivedArguments = newValue } }
    }
    private let setNotificationModeRoomIdModeReceivedInvocationsLock = NSLock()
    private var setNotificationModeRoomIdModeUnderlyingReceivedInvocations: [(roomId: String, mode: RoomNotificationModeProxy)] = []
    var setNotificationModeRoomIdModeReceivedInvocations: [(roomId: String, mode: RoomNotificationModeProxy)] {
        get { setNotificationModeRoomIdModeReceivedInvocationsLock.withLock { setNotificationModeRoomIdModeUnderlyingReceivedInvocations } }
        set { setNotificationModeRoomIdModeReceivedInvocationsLock.withLock { setNotificationModeRoomIdModeUnderlyingReceivedInvocations = newValue } }
    }
    var setNotificationModeRoomIdModeClosure: ((String, RoomNotificationModeProxy) async throws -> Void)?

    func setNotificationMode(roomId: String, mode: RoomNotificationModeProxy) async throws {
        if let error = setNotificationModeRoomIdModeThrowableError {
            throw error
        }
        setNotificationModeRoomIdModeCallsCountLock.withLock { setNotificationModeRoomIdModeUnderlyingCallsCount += 1 }
        setNotificationModeRoomIdModeReceivedArguments = (roomId: roomId, mode: mode)
        setNotificationModeRoomIdModeReceivedInvocationsLock.withLock { setNotificationModeRoomIdModeUnderlyingReceivedInvocations.append((roomId: roomId, mode: mode)) }
        try await setNotificationModeRoomIdModeClosure?(roomId, mode)
    }
    //MARK: - getUserDefinedRoomNotificationMode

    var getUserDefinedRoomNotificationModeRoomIdThrowableError: Error?
    private let getUserDefinedRoomNotificationModeRoomIdCallsCountLock = NSLock()
    private var getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount = 0
    var getUserDefinedRoomNotificationModeRoomIdCallsCount: Int {
        get { getUserDefinedRoomNotificationModeRoomIdCallsCountLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount } }
        set { getUserDefinedRoomNotificationModeRoomIdCallsCountLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount = newValue } }
    }
    var getUserDefinedRoomNotificationModeRoomIdCalled: Bool {
        return getUserDefinedRoomNotificationModeRoomIdCallsCount > 0
    }
    private let getUserDefinedRoomNotificationModeRoomIdReceivedRoomIdLock = NSLock()
    private var getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedRoomId: String?
    var getUserDefinedRoomNotificationModeRoomIdReceivedRoomId: String? {
        get { getUserDefinedRoomNotificationModeRoomIdReceivedRoomIdLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedRoomId } }
        set { getUserDefinedRoomNotificationModeRoomIdReceivedRoomIdLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedRoomId = newValue } }
    }
    private let getUserDefinedRoomNotificationModeRoomIdReceivedInvocationsLock = NSLock()
    private var getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedInvocations: [String] = []
    var getUserDefinedRoomNotificationModeRoomIdReceivedInvocations: [String] {
        get { getUserDefinedRoomNotificationModeRoomIdReceivedInvocationsLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedInvocations } }
        set { getUserDefinedRoomNotificationModeRoomIdReceivedInvocationsLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedInvocations = newValue } }
    }

    private let getUserDefinedRoomNotificationModeRoomIdReturnValueLock = NSLock()
    private var getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue: RoomNotificationModeProxy?
    var getUserDefinedRoomNotificationModeRoomIdReturnValue: RoomNotificationModeProxy? {
        get { getUserDefinedRoomNotificationModeRoomIdReturnValueLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue } }
        set { getUserDefinedRoomNotificationModeRoomIdReturnValueLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReturnValue = newValue } }
    }
    var getUserDefinedRoomNotificationModeRoomIdClosure: ((String) async throws -> RoomNotificationModeProxy?)?

    func getUserDefinedRoomNotificationMode(roomId: String) async throws -> RoomNotificationModeProxy? {
        if let error = getUserDefinedRoomNotificationModeRoomIdThrowableError {
            throw error
        }
        getUserDefinedRoomNotificationModeRoomIdCallsCountLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingCallsCount += 1 }
        getUserDefinedRoomNotificationModeRoomIdReceivedRoomId = roomId
        getUserDefinedRoomNotificationModeRoomIdReceivedInvocationsLock.withLock { getUserDefinedRoomNotificationModeRoomIdUnderlyingReceivedInvocations.append(roomId) }
        if let getUserDefinedRoomNotificationModeRoomIdClosure = getUserDefinedRoomNotificationModeRoomIdClosure {
            return try await getUserDefinedRoomNotificationModeRoomIdClosure(roomId)
        } else {
            return getUserDefinedRoomNotificationModeRoomIdReturnValue
        }
    }
    //MARK: - getDefaultRoomNotificationMode

    private let getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCountLock = NSLock()
    private var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount: Int {
        get { getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCountLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount } }
        set { getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCountLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount = newValue } }
    }
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneCalled: Bool {
        return getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount > 0
    }
    private let getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArgumentsLock = NSLock()
    private var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool)?
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool)? {
        get { getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArgumentsLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedArguments } }
        set { getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArgumentsLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedArguments = newValue } }
    }
    private let getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocationsLock = NSLock()
    private var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool)] = []
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool)] {
        get { getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedInvocations } }
        set { getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedInvocations = newValue } }
    }

    private let getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValueLock = NSLock()
    private var getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue: RoomNotificationModeProxy!
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue: RoomNotificationModeProxy! {
        get { getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValueLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue } }
        set { getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValueLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReturnValue = newValue } }
    }
    var getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure: ((Bool, Bool) async -> RoomNotificationModeProxy)?

    func getDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool) async -> RoomNotificationModeProxy {
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCountLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingCallsCount += 1 }
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedArguments = (isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { getDefaultRoomNotificationModeIsEncryptedIsOneToOneUnderlyingReceivedInvocations.append((isEncrypted: isEncrypted, isOneToOne: isOneToOne)) }
        if let getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure {
            return await getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure(isEncrypted, isOneToOne)
        } else {
            return getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue
        }
    }
    //MARK: - setDefaultRoomNotificationMode

    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError: Error?
    private let setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCountLock = NSLock()
    private var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount = 0
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount: Int {
        get { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCountLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount } }
        set { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCountLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount = newValue } }
    }
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCalled: Bool {
        return setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount > 0
    }
    private let setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArgumentsLock = NSLock()
    private var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy)?
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments: (isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy)? {
        get { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArgumentsLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedArguments } }
        set { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArgumentsLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedArguments = newValue } }
    }
    private let setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocationsLock = NSLock()
    private var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy)] = []
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations: [(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy)] {
        get { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocationsLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedInvocations } }
        set { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocationsLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedInvocations = newValue } }
    }
    var setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure: ((Bool, Bool, RoomNotificationModeProxy) async throws -> Void)?

    func setDefaultRoomNotificationMode(isEncrypted: Bool, isOneToOne: Bool, mode: RoomNotificationModeProxy) async throws {
        if let error = setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError {
            throw error
        }
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCountLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingCallsCount += 1 }
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments = (isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode)
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocationsLock.withLock { setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeUnderlyingReceivedInvocations.append((isEncrypted: isEncrypted, isOneToOne: isOneToOne, mode: mode)) }
        try await setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure?(isEncrypted, isOneToOne, mode)
    }
    //MARK: - restoreDefaultNotificationMode

    var restoreDefaultNotificationModeRoomIdThrowableError: Error?
    private let restoreDefaultNotificationModeRoomIdCallsCountLock = NSLock()
    private var restoreDefaultNotificationModeRoomIdUnderlyingCallsCount = 0
    var restoreDefaultNotificationModeRoomIdCallsCount: Int {
        get { restoreDefaultNotificationModeRoomIdCallsCountLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingCallsCount } }
        set { restoreDefaultNotificationModeRoomIdCallsCountLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingCallsCount = newValue } }
    }
    var restoreDefaultNotificationModeRoomIdCalled: Bool {
        return restoreDefaultNotificationModeRoomIdCallsCount > 0
    }
    private let restoreDefaultNotificationModeRoomIdReceivedRoomIdLock = NSLock()
    private var restoreDefaultNotificationModeRoomIdUnderlyingReceivedRoomId: String?
    var restoreDefaultNotificationModeRoomIdReceivedRoomId: String? {
        get { restoreDefaultNotificationModeRoomIdReceivedRoomIdLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingReceivedRoomId } }
        set { restoreDefaultNotificationModeRoomIdReceivedRoomIdLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingReceivedRoomId = newValue } }
    }
    private let restoreDefaultNotificationModeRoomIdReceivedInvocationsLock = NSLock()
    private var restoreDefaultNotificationModeRoomIdUnderlyingReceivedInvocations: [String] = []
    var restoreDefaultNotificationModeRoomIdReceivedInvocations: [String] {
        get { restoreDefaultNotificationModeRoomIdReceivedInvocationsLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingReceivedInvocations } }
        set { restoreDefaultNotificationModeRoomIdReceivedInvocationsLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingReceivedInvocations = newValue } }
    }
    var restoreDefaultNotificationModeRoomIdClosure: ((String) async throws -> Void)?

    func restoreDefaultNotificationMode(roomId: String) async throws {
        if let error = restoreDefaultNotificationModeRoomIdThrowableError {
            throw error
        }
        restoreDefaultNotificationModeRoomIdCallsCountLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingCallsCount += 1 }
        restoreDefaultNotificationModeRoomIdReceivedRoomId = roomId
        restoreDefaultNotificationModeRoomIdReceivedInvocationsLock.withLock { restoreDefaultNotificationModeRoomIdUnderlyingReceivedInvocations.append(roomId) }
        try await restoreDefaultNotificationModeRoomIdClosure?(roomId)
    }
    //MARK: - unmuteRoom

    var unmuteRoomRoomIdIsEncryptedIsOneToOneThrowableError: Error?
    private let unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCountLock = NSLock()
    private var unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = 0
    var unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount: Int {
        get { unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCountLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount } }
        set { unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCountLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount = newValue } }
    }
    var unmuteRoomRoomIdIsEncryptedIsOneToOneCalled: Bool {
        return unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCount > 0
    }
    private let unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArgumentsLock = NSLock()
    private var unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)?
    var unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArguments: (roomId: String, isEncrypted: Bool, isOneToOne: Bool)? {
        get { unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArgumentsLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedArguments } }
        set { unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArgumentsLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedArguments = newValue } }
    }
    private let unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock = NSLock()
    private var unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] = []
    var unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocations: [(roomId: String, isEncrypted: Bool, isOneToOne: Bool)] {
        get { unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations } }
        set { unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations = newValue } }
    }
    var unmuteRoomRoomIdIsEncryptedIsOneToOneClosure: ((String, Bool, Bool) async throws -> Void)?

    func unmuteRoom(roomId: String, isEncrypted: Bool, isOneToOne: Bool) async throws {
        if let error = unmuteRoomRoomIdIsEncryptedIsOneToOneThrowableError {
            throw error
        }
        unmuteRoomRoomIdIsEncryptedIsOneToOneCallsCountLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingCallsCount += 1 }
        unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedArguments = (roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)
        unmuteRoomRoomIdIsEncryptedIsOneToOneReceivedInvocationsLock.withLock { unmuteRoomRoomIdIsEncryptedIsOneToOneUnderlyingReceivedInvocations.append((roomId: roomId, isEncrypted: isEncrypted, isOneToOne: isOneToOne)) }
        try await unmuteRoomRoomIdIsEncryptedIsOneToOneClosure?(roomId, isEncrypted, isOneToOne)
    }
    //MARK: - isRoomMentionEnabled

    var isRoomMentionEnabledThrowableError: Error?
    private let isRoomMentionEnabledCallsCountLock = NSLock()
    private var isRoomMentionEnabledUnderlyingCallsCount = 0
    var isRoomMentionEnabledCallsCount: Int {
        get { isRoomMentionEnabledCallsCountLock.withLock { isRoomMentionEnabledUnderlyingCallsCount } }
        set { isRoomMentionEnabledCallsCountLock.withLock { isRoomMentionEnabledUnderlyingCallsCount = newValue } }
    }
    var isRoomMentionEnabledCalled: Bool {
        return isRoomMentionEnabledCallsCount > 0
    }

    private let isRoomMentionEnabledReturnValueLock = NSLock()
    private var isRoomMentionEnabledUnderlyingReturnValue: Bool!
    var isRoomMentionEnabledReturnValue: Bool! {
        get { isRoomMentionEnabledReturnValueLock.withLock { isRoomMentionEnabledUnderlyingReturnValue } }
        set { isRoomMentionEnabledReturnValueLock.withLock { isRoomMentionEnabledUnderlyingReturnValue = newValue } }
    }
    var isRoomMentionEnabledClosure: (() async throws -> Bool)?

    func isRoomMentionEnabled() async throws -> Bool {
        if let error = isRoomMentionEnabledThrowableError {
            throw error
        }
        isRoomMentionEnabledCallsCountLock.withLock { isRoomMentionEnabledUnderlyingCallsCount += 1 }
        if let isRoomMentionEnabledClosure = isRoomMentionEnabledClosure {
            return try await isRoomMentionEnabledClosure()
        } else {
            return isRoomMentionEnabledReturnValue
        }
    }
    //MARK: - setRoomMentionEnabled

    var setRoomMentionEnabledEnabledThrowableError: Error?
    private let setRoomMentionEnabledEnabledCallsCountLock = NSLock()
    private var setRoomMentionEnabledEnabledUnderlyingCallsCount = 0
    var setRoomMentionEnabledEnabledCallsCount: Int {
        get { setRoomMentionEnabledEnabledCallsCountLock.withLock { setRoomMentionEnabledEnabledUnderlyingCallsCount } }
        set { setRoomMentionEnabledEnabledCallsCountLock.withLock { setRoomMentionEnabledEnabledUnderlyingCallsCount = newValue } }
    }
    var setRoomMentionEnabledEnabledCalled: Bool {
        return setRoomMentionEnabledEnabledCallsCount > 0
    }
    private let setRoomMentionEnabledEnabledReceivedEnabledLock = NSLock()
    private var setRoomMentionEnabledEnabledUnderlyingReceivedEnabled: Bool?
    var setRoomMentionEnabledEnabledReceivedEnabled: Bool? {
        get { setRoomMentionEnabledEnabledReceivedEnabledLock.withLock { setRoomMentionEnabledEnabledUnderlyingReceivedEnabled } }
        set { setRoomMentionEnabledEnabledReceivedEnabledLock.withLock { setRoomMentionEnabledEnabledUnderlyingReceivedEnabled = newValue } }
    }
    private let setRoomMentionEnabledEnabledReceivedInvocationsLock = NSLock()
    private var setRoomMentionEnabledEnabledUnderlyingReceivedInvocations: [Bool] = []
    var setRoomMentionEnabledEnabledReceivedInvocations: [Bool] {
        get { setRoomMentionEnabledEnabledReceivedInvocationsLock.withLock { setRoomMentionEnabledEnabledUnderlyingReceivedInvocations } }
        set { setRoomMentionEnabledEnabledReceivedInvocationsLock.withLock { setRoomMentionEnabledEnabledUnderlyingReceivedInvocations = newValue } }
    }
    var setRoomMentionEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setRoomMentionEnabled(enabled: Bool) async throws {
        if let error = setRoomMentionEnabledEnabledThrowableError {
            throw error
        }
        setRoomMentionEnabledEnabledCallsCountLock.withLock { setRoomMentionEnabledEnabledUnderlyingCallsCount += 1 }
        setRoomMentionEnabledEnabledReceivedEnabled = enabled
        setRoomMentionEnabledEnabledReceivedInvocationsLock.withLock { setRoomMentionEnabledEnabledUnderlyingReceivedInvocations.append(enabled) }
        try await setRoomMentionEnabledEnabledClosure?(enabled)
    }
    //MARK: - isCallEnabled

    var isCallEnabledThrowableError: Error?
    private let isCallEnabledCallsCountLock = NSLock()
    private var isCallEnabledUnderlyingCallsCount = 0
    var isCallEnabledCallsCount: Int {
        get { isCallEnabledCallsCountLock.withLock { isCallEnabledUnderlyingCallsCount } }
        set { isCallEnabledCallsCountLock.withLock { isCallEnabledUnderlyingCallsCount = newValue } }
    }
    var isCallEnabledCalled: Bool {
        return isCallEnabledCallsCount > 0
    }

    private let isCallEnabledReturnValueLock = NSLock()
    private var isCallEnabledUnderlyingReturnValue: Bool!
    var isCallEnabledReturnValue: Bool! {
        get { isCallEnabledReturnValueLock.withLock { isCallEnabledUnderlyingReturnValue } }
        set { isCallEnabledReturnValueLock.withLock { isCallEnabledUnderlyingReturnValue = newValue } }
    }
    var isCallEnabledClosure: (() async throws -> Bool)?

    func isCallEnabled() async throws -> Bool {
        if let error = isCallEnabledThrowableError {
            throw error
        }
        isCallEnabledCallsCountLock.withLock { isCallEnabledUnderlyingCallsCount += 1 }
        if let isCallEnabledClosure = isCallEnabledClosure {
            return try await isCallEnabledClosure()
        } else {
            return isCallEnabledReturnValue
        }
    }
    //MARK: - setCallEnabled

    var setCallEnabledEnabledThrowableError: Error?
    private let setCallEnabledEnabledCallsCountLock = NSLock()
    private var setCallEnabledEnabledUnderlyingCallsCount = 0
    var setCallEnabledEnabledCallsCount: Int {
        get { setCallEnabledEnabledCallsCountLock.withLock { setCallEnabledEnabledUnderlyingCallsCount } }
        set { setCallEnabledEnabledCallsCountLock.withLock { setCallEnabledEnabledUnderlyingCallsCount = newValue } }
    }
    var setCallEnabledEnabledCalled: Bool {
        return setCallEnabledEnabledCallsCount > 0
    }
    private let setCallEnabledEnabledReceivedEnabledLock = NSLock()
    private var setCallEnabledEnabledUnderlyingReceivedEnabled: Bool?
    var setCallEnabledEnabledReceivedEnabled: Bool? {
        get { setCallEnabledEnabledReceivedEnabledLock.withLock { setCallEnabledEnabledUnderlyingReceivedEnabled } }
        set { setCallEnabledEnabledReceivedEnabledLock.withLock { setCallEnabledEnabledUnderlyingReceivedEnabled = newValue } }
    }
    private let setCallEnabledEnabledReceivedInvocationsLock = NSLock()
    private var setCallEnabledEnabledUnderlyingReceivedInvocations: [Bool] = []
    var setCallEnabledEnabledReceivedInvocations: [Bool] {
        get { setCallEnabledEnabledReceivedInvocationsLock.withLock { setCallEnabledEnabledUnderlyingReceivedInvocations } }
        set { setCallEnabledEnabledReceivedInvocationsLock.withLock { setCallEnabledEnabledUnderlyingReceivedInvocations = newValue } }
    }
    var setCallEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setCallEnabled(enabled: Bool) async throws {
        if let error = setCallEnabledEnabledThrowableError {
            throw error
        }
        setCallEnabledEnabledCallsCountLock.withLock { setCallEnabledEnabledUnderlyingCallsCount += 1 }
        setCallEnabledEnabledReceivedEnabled = enabled
        setCallEnabledEnabledReceivedInvocationsLock.withLock { setCallEnabledEnabledUnderlyingReceivedInvocations.append(enabled) }
        try await setCallEnabledEnabledClosure?(enabled)
    }
    //MARK: - isInviteForMeEnabled

    var isInviteForMeEnabledThrowableError: Error?
    private let isInviteForMeEnabledCallsCountLock = NSLock()
    private var isInviteForMeEnabledUnderlyingCallsCount = 0
    var isInviteForMeEnabledCallsCount: Int {
        get { isInviteForMeEnabledCallsCountLock.withLock { isInviteForMeEnabledUnderlyingCallsCount } }
        set { isInviteForMeEnabledCallsCountLock.withLock { isInviteForMeEnabledUnderlyingCallsCount = newValue } }
    }
    var isInviteForMeEnabledCalled: Bool {
        return isInviteForMeEnabledCallsCount > 0
    }

    private let isInviteForMeEnabledReturnValueLock = NSLock()
    private var isInviteForMeEnabledUnderlyingReturnValue: Bool!
    var isInviteForMeEnabledReturnValue: Bool! {
        get { isInviteForMeEnabledReturnValueLock.withLock { isInviteForMeEnabledUnderlyingReturnValue } }
        set { isInviteForMeEnabledReturnValueLock.withLock { isInviteForMeEnabledUnderlyingReturnValue = newValue } }
    }
    var isInviteForMeEnabledClosure: (() async throws -> Bool)?

    func isInviteForMeEnabled() async throws -> Bool {
        if let error = isInviteForMeEnabledThrowableError {
            throw error
        }
        isInviteForMeEnabledCallsCountLock.withLock { isInviteForMeEnabledUnderlyingCallsCount += 1 }
        if let isInviteForMeEnabledClosure = isInviteForMeEnabledClosure {
            return try await isInviteForMeEnabledClosure()
        } else {
            return isInviteForMeEnabledReturnValue
        }
    }
    //MARK: - setInviteForMeEnabled

    var setInviteForMeEnabledEnabledThrowableError: Error?
    private let setInviteForMeEnabledEnabledCallsCountLock = NSLock()
    private var setInviteForMeEnabledEnabledUnderlyingCallsCount = 0
    var setInviteForMeEnabledEnabledCallsCount: Int {
        get { setInviteForMeEnabledEnabledCallsCountLock.withLock { setInviteForMeEnabledEnabledUnderlyingCallsCount } }
        set { setInviteForMeEnabledEnabledCallsCountLock.withLock { setInviteForMeEnabledEnabledUnderlyingCallsCount = newValue } }
    }
    var setInviteForMeEnabledEnabledCalled: Bool {
        return setInviteForMeEnabledEnabledCallsCount > 0
    }
    private let setInviteForMeEnabledEnabledReceivedEnabledLock = NSLock()
    private var setInviteForMeEnabledEnabledUnderlyingReceivedEnabled: Bool?
    var setInviteForMeEnabledEnabledReceivedEnabled: Bool? {
        get { setInviteForMeEnabledEnabledReceivedEnabledLock.withLock { setInviteForMeEnabledEnabledUnderlyingReceivedEnabled } }
        set { setInviteForMeEnabledEnabledReceivedEnabledLock.withLock { setInviteForMeEnabledEnabledUnderlyingReceivedEnabled = newValue } }
    }
    private let setInviteForMeEnabledEnabledReceivedInvocationsLock = NSLock()
    private var setInviteForMeEnabledEnabledUnderlyingReceivedInvocations: [Bool] = []
    var setInviteForMeEnabledEnabledReceivedInvocations: [Bool] {
        get { setInviteForMeEnabledEnabledReceivedInvocationsLock.withLock { setInviteForMeEnabledEnabledUnderlyingReceivedInvocations } }
        set { setInviteForMeEnabledEnabledReceivedInvocationsLock.withLock { setInviteForMeEnabledEnabledUnderlyingReceivedInvocations = newValue } }
    }
    var setInviteForMeEnabledEnabledClosure: ((Bool) async throws -> Void)?

    func setInviteForMeEnabled(enabled: Bool) async throws {
        if let error = setInviteForMeEnabledEnabledThrowableError {
            throw error
        }
        setInviteForMeEnabledEnabledCallsCountLock.withLock { setInviteForMeEnabledEnabledUnderlyingCallsCount += 1 }
        setInviteForMeEnabledEnabledReceivedEnabled = enabled
        setInviteForMeEnabledEnabledReceivedInvocationsLock.withLock { setInviteForMeEnabledEnabledUnderlyingReceivedInvocations.append(enabled) }
        try await setInviteForMeEnabledEnabledClosure?(enabled)
    }
    //MARK: - getRoomsWithUserDefinedRules

    var getRoomsWithUserDefinedRulesThrowableError: Error?
    private let getRoomsWithUserDefinedRulesCallsCountLock = NSLock()
    private var getRoomsWithUserDefinedRulesUnderlyingCallsCount = 0
    var getRoomsWithUserDefinedRulesCallsCount: Int {
        get { getRoomsWithUserDefinedRulesCallsCountLock.withLock { getRoomsWithUserDefinedRulesUnderlyingCallsCount } }
        set { getRoomsWithUserDefinedRulesCallsCountLock.withLock { getRoomsWithUserDefinedRulesUnderlyingCallsCount = newValue } }
    }
    var getRoomsWithUserDefinedRulesCalled: Bool {
        return getRoomsWithUserDefinedRulesCallsCount > 0
    }

    private let getRoomsWithUserDefinedRulesReturnValueLock = NSLock()
    private var getRoomsWithUserDefinedRulesUnderlyingReturnValue: [String]!
    var getRoomsWithUserDefinedRulesReturnValue: [String]! {
        get { getRoomsWithUserDefinedRulesReturnValueLock.withLock { getRoomsWithUserDefinedRulesUnderlyingReturnValue } }
        set { getRoomsWithUserDefinedRulesReturnValueLock.withLock { getRoomsWithUserDefinedRulesUnderlyingReturnValue = newValue } }
    }
    var getRoomsWithUserDefinedRulesClosure: (() async throws -> [String])?

    func getRoomsWithUserDefinedRules() async throws -> [String] {
        if let error = getRoomsWithUserDefinedRulesThrowableError {
            throw error
        }
        getRoomsWithUserDefinedRulesCallsCountLock.withLock { getRoomsWithUserDefinedRulesUnderlyingCallsCount += 1 }
        if let getRoomsWithUserDefinedRulesClosure = getRoomsWithUserDefinedRulesClosure {
            return try await getRoomsWithUserDefinedRulesClosure()
        } else {
            return getRoomsWithUserDefinedRulesReturnValue
        }
    }
    //MARK: - canPushEncryptedEventsToDevice

    private let canPushEncryptedEventsToDeviceCallsCountLock = NSLock()
    private var canPushEncryptedEventsToDeviceUnderlyingCallsCount = 0
    var canPushEncryptedEventsToDeviceCallsCount: Int {
        get { canPushEncryptedEventsToDeviceCallsCountLock.withLock { canPushEncryptedEventsToDeviceUnderlyingCallsCount } }
        set { canPushEncryptedEventsToDeviceCallsCountLock.withLock { canPushEncryptedEventsToDeviceUnderlyingCallsCount = newValue } }
    }
    var canPushEncryptedEventsToDeviceCalled: Bool {
        return canPushEncryptedEventsToDeviceCallsCount > 0
    }

    private let canPushEncryptedEventsToDeviceReturnValueLock = NSLock()
    private var canPushEncryptedEventsToDeviceUnderlyingReturnValue: Bool!
    var canPushEncryptedEventsToDeviceReturnValue: Bool! {
        get { canPushEncryptedEventsToDeviceReturnValueLock.withLock { canPushEncryptedEventsToDeviceUnderlyingReturnValue } }
        set { canPushEncryptedEventsToDeviceReturnValueLock.withLock { canPushEncryptedEventsToDeviceUnderlyingReturnValue = newValue } }
    }
    var canPushEncryptedEventsToDeviceClosure: (() async -> Bool)?

    func canPushEncryptedEventsToDevice() async -> Bool {
        canPushEncryptedEventsToDeviceCallsCountLock.withLock { canPushEncryptedEventsToDeviceUnderlyingCallsCount += 1 }
        if let canPushEncryptedEventsToDeviceClosure = canPushEncryptedEventsToDeviceClosure {
            return await canPushEncryptedEventsToDeviceClosure()
        } else {
            return canPushEncryptedEventsToDeviceReturnValue
        }
    }
}
class NotificationToneManagerMock: NotificationToneManagerProtocol, @unchecked Sendable {

    //MARK: - setSelectedTone

    var setSelectedToneThrowableError: Error?
    private let setSelectedToneCallsCountLock = NSLock()
    private var setSelectedToneUnderlyingCallsCount = 0
    var setSelectedToneCallsCount: Int {
        get { setSelectedToneCallsCountLock.withLock { setSelectedToneUnderlyingCallsCount } }
        set { setSelectedToneCallsCountLock.withLock { setSelectedToneUnderlyingCallsCount = newValue } }
    }
    var setSelectedToneCalled: Bool {
        return setSelectedToneCallsCount > 0
    }
    private let setSelectedToneReceivedAlertToneLock = NSLock()
    private var setSelectedToneUnderlyingReceivedAlertTone: NotificationTone?
    var setSelectedToneReceivedAlertTone: NotificationTone? {
        get { setSelectedToneReceivedAlertToneLock.withLock { setSelectedToneUnderlyingReceivedAlertTone } }
        set { setSelectedToneReceivedAlertToneLock.withLock { setSelectedToneUnderlyingReceivedAlertTone = newValue } }
    }
    private let setSelectedToneReceivedInvocationsLock = NSLock()
    private var setSelectedToneUnderlyingReceivedInvocations: [NotificationTone] = []
    var setSelectedToneReceivedInvocations: [NotificationTone] {
        get { setSelectedToneReceivedInvocationsLock.withLock { setSelectedToneUnderlyingReceivedInvocations } }
        set { setSelectedToneReceivedInvocationsLock.withLock { setSelectedToneUnderlyingReceivedInvocations = newValue } }
    }

    private let setSelectedToneReturnValueLock = NSLock()
    private var setSelectedToneUnderlyingReturnValue: URL!
    var setSelectedToneReturnValue: URL! {
        get { setSelectedToneReturnValueLock.withLock { setSelectedToneUnderlyingReturnValue } }
        set { setSelectedToneReturnValueLock.withLock { setSelectedToneUnderlyingReturnValue = newValue } }
    }
    var setSelectedToneClosure: ((NotificationTone) throws -> URL)?

    @discardableResult
    func setSelectedTone(_ alertTone: NotificationTone) throws -> URL {
        if let error = setSelectedToneThrowableError {
            throw error
        }
        setSelectedToneCallsCountLock.withLock { setSelectedToneUnderlyingCallsCount += 1 }
        setSelectedToneReceivedAlertTone = alertTone
        setSelectedToneReceivedInvocationsLock.withLock { setSelectedToneUnderlyingReceivedInvocations.append(alertTone) }
        if let setSelectedToneClosure = setSelectedToneClosure {
            return try setSelectedToneClosure(alertTone)
        } else {
            return setSelectedToneReturnValue
        }
    }
    //MARK: - customTones

    private let customTonesCallsCountLock = NSLock()
    private var customTonesUnderlyingCallsCount = 0
    var customTonesCallsCount: Int {
        get { customTonesCallsCountLock.withLock { customTonesUnderlyingCallsCount } }
        set { customTonesCallsCountLock.withLock { customTonesUnderlyingCallsCount = newValue } }
    }
    var customTonesCalled: Bool {
        return customTonesCallsCount > 0
    }

    private let customTonesReturnValueLock = NSLock()
    private var customTonesUnderlyingReturnValue: [NotificationTone]!
    var customTonesReturnValue: [NotificationTone]! {
        get { customTonesReturnValueLock.withLock { customTonesUnderlyingReturnValue } }
        set { customTonesReturnValueLock.withLock { customTonesUnderlyingReturnValue = newValue } }
    }
    var customTonesClosure: (() -> [NotificationTone])?

    func customTones() -> [NotificationTone] {
        customTonesCallsCountLock.withLock { customTonesUnderlyingCallsCount += 1 }
        if let customTonesClosure = customTonesClosure {
            return customTonesClosure()
        } else {
            return customTonesReturnValue
        }
    }
    //MARK: - deleteCustomTone

    var deleteCustomToneThrowableError: Error?
    private let deleteCustomToneCallsCountLock = NSLock()
    private var deleteCustomToneUnderlyingCallsCount = 0
    var deleteCustomToneCallsCount: Int {
        get { deleteCustomToneCallsCountLock.withLock { deleteCustomToneUnderlyingCallsCount } }
        set { deleteCustomToneCallsCountLock.withLock { deleteCustomToneUnderlyingCallsCount = newValue } }
    }
    var deleteCustomToneCalled: Bool {
        return deleteCustomToneCallsCount > 0
    }
    private let deleteCustomToneReceivedAlertToneLock = NSLock()
    private var deleteCustomToneUnderlyingReceivedAlertTone: NotificationTone?
    var deleteCustomToneReceivedAlertTone: NotificationTone? {
        get { deleteCustomToneReceivedAlertToneLock.withLock { deleteCustomToneUnderlyingReceivedAlertTone } }
        set { deleteCustomToneReceivedAlertToneLock.withLock { deleteCustomToneUnderlyingReceivedAlertTone = newValue } }
    }
    private let deleteCustomToneReceivedInvocationsLock = NSLock()
    private var deleteCustomToneUnderlyingReceivedInvocations: [NotificationTone] = []
    var deleteCustomToneReceivedInvocations: [NotificationTone] {
        get { deleteCustomToneReceivedInvocationsLock.withLock { deleteCustomToneUnderlyingReceivedInvocations } }
        set { deleteCustomToneReceivedInvocationsLock.withLock { deleteCustomToneUnderlyingReceivedInvocations = newValue } }
    }
    var deleteCustomToneClosure: ((NotificationTone) throws -> Void)?

    func deleteCustomTone(_ alertTone: NotificationTone) throws {
        if let error = deleteCustomToneThrowableError {
            throw error
        }
        deleteCustomToneCallsCountLock.withLock { deleteCustomToneUnderlyingCallsCount += 1 }
        deleteCustomToneReceivedAlertTone = alertTone
        deleteCustomToneReceivedInvocationsLock.withLock { deleteCustomToneUnderlyingReceivedInvocations.append(alertTone) }
        try deleteCustomToneClosure?(alertTone)
    }
    //MARK: - addNewToneToLibrary

    var addNewToneToLibraryFromThrowableError: Error?
    private let addNewToneToLibraryFromCallsCountLock = NSLock()
    private var addNewToneToLibraryFromUnderlyingCallsCount = 0
    var addNewToneToLibraryFromCallsCount: Int {
        get { addNewToneToLibraryFromCallsCountLock.withLock { addNewToneToLibraryFromUnderlyingCallsCount } }
        set { addNewToneToLibraryFromCallsCountLock.withLock { addNewToneToLibraryFromUnderlyingCallsCount = newValue } }
    }
    var addNewToneToLibraryFromCalled: Bool {
        return addNewToneToLibraryFromCallsCount > 0
    }
    private let addNewToneToLibraryFromReceivedSourceURLLock = NSLock()
    private var addNewToneToLibraryFromUnderlyingReceivedSourceURL: URL?
    var addNewToneToLibraryFromReceivedSourceURL: URL? {
        get { addNewToneToLibraryFromReceivedSourceURLLock.withLock { addNewToneToLibraryFromUnderlyingReceivedSourceURL } }
        set { addNewToneToLibraryFromReceivedSourceURLLock.withLock { addNewToneToLibraryFromUnderlyingReceivedSourceURL = newValue } }
    }
    private let addNewToneToLibraryFromReceivedInvocationsLock = NSLock()
    private var addNewToneToLibraryFromUnderlyingReceivedInvocations: [URL] = []
    var addNewToneToLibraryFromReceivedInvocations: [URL] {
        get { addNewToneToLibraryFromReceivedInvocationsLock.withLock { addNewToneToLibraryFromUnderlyingReceivedInvocations } }
        set { addNewToneToLibraryFromReceivedInvocationsLock.withLock { addNewToneToLibraryFromUnderlyingReceivedInvocations = newValue } }
    }

    private let addNewToneToLibraryFromReturnValueLock = NSLock()
    private var addNewToneToLibraryFromUnderlyingReturnValue: URL!
    var addNewToneToLibraryFromReturnValue: URL! {
        get { addNewToneToLibraryFromReturnValueLock.withLock { addNewToneToLibraryFromUnderlyingReturnValue } }
        set { addNewToneToLibraryFromReturnValueLock.withLock { addNewToneToLibraryFromUnderlyingReturnValue = newValue } }
    }
    var addNewToneToLibraryFromClosure: ((URL) throws -> URL)?

    @NotificationToneManager.ConversionActor
    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL {
        if let error = addNewToneToLibraryFromThrowableError {
            throw error
        }
        addNewToneToLibraryFromCallsCountLock.withLock { addNewToneToLibraryFromUnderlyingCallsCount += 1 }
        addNewToneToLibraryFromReceivedSourceURL = sourceURL
        addNewToneToLibraryFromReceivedInvocationsLock.withLock { addNewToneToLibraryFromUnderlyingReceivedInvocations.append(sourceURL) }
        if let addNewToneToLibraryFromClosure = addNewToneToLibraryFromClosure {
            return try addNewToneToLibraryFromClosure(sourceURL)
        } else {
            return addNewToneToLibraryFromReturnValue
        }
    }
}
class OrientationManagerMock: OrientationManagerProtocol, @unchecked Sendable {

    //MARK: - setOrientation

    private let setOrientationCallsCountLock = NSLock()
    private var setOrientationUnderlyingCallsCount = 0
    var setOrientationCallsCount: Int {
        get { setOrientationCallsCountLock.withLock { setOrientationUnderlyingCallsCount } }
        set { setOrientationCallsCountLock.withLock { setOrientationUnderlyingCallsCount = newValue } }
    }
    var setOrientationCalled: Bool {
        return setOrientationCallsCount > 0
    }
    private let setOrientationReceivedOrientationLock = NSLock()
    private var setOrientationUnderlyingReceivedOrientation: UIInterfaceOrientationMask?
    var setOrientationReceivedOrientation: UIInterfaceOrientationMask? {
        get { setOrientationReceivedOrientationLock.withLock { setOrientationUnderlyingReceivedOrientation } }
        set { setOrientationReceivedOrientationLock.withLock { setOrientationUnderlyingReceivedOrientation = newValue } }
    }
    private let setOrientationReceivedInvocationsLock = NSLock()
    private var setOrientationUnderlyingReceivedInvocations: [UIInterfaceOrientationMask] = []
    var setOrientationReceivedInvocations: [UIInterfaceOrientationMask] {
        get { setOrientationReceivedInvocationsLock.withLock { setOrientationUnderlyingReceivedInvocations } }
        set { setOrientationReceivedInvocationsLock.withLock { setOrientationUnderlyingReceivedInvocations = newValue } }
    }
    var setOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        setOrientationCallsCountLock.withLock { setOrientationUnderlyingCallsCount += 1 }
        setOrientationReceivedOrientation = orientation
        setOrientationReceivedInvocationsLock.withLock { setOrientationUnderlyingReceivedInvocations.append(orientation) }
        setOrientationClosure?(orientation)
    }
    //MARK: - lockOrientation

    private let lockOrientationCallsCountLock = NSLock()
    private var lockOrientationUnderlyingCallsCount = 0
    var lockOrientationCallsCount: Int {
        get { lockOrientationCallsCountLock.withLock { lockOrientationUnderlyingCallsCount } }
        set { lockOrientationCallsCountLock.withLock { lockOrientationUnderlyingCallsCount = newValue } }
    }
    var lockOrientationCalled: Bool {
        return lockOrientationCallsCount > 0
    }
    private let lockOrientationReceivedOrientationLock = NSLock()
    private var lockOrientationUnderlyingReceivedOrientation: UIInterfaceOrientationMask?
    var lockOrientationReceivedOrientation: UIInterfaceOrientationMask? {
        get { lockOrientationReceivedOrientationLock.withLock { lockOrientationUnderlyingReceivedOrientation } }
        set { lockOrientationReceivedOrientationLock.withLock { lockOrientationUnderlyingReceivedOrientation = newValue } }
    }
    private let lockOrientationReceivedInvocationsLock = NSLock()
    private var lockOrientationUnderlyingReceivedInvocations: [UIInterfaceOrientationMask] = []
    var lockOrientationReceivedInvocations: [UIInterfaceOrientationMask] {
        get { lockOrientationReceivedInvocationsLock.withLock { lockOrientationUnderlyingReceivedInvocations } }
        set { lockOrientationReceivedInvocationsLock.withLock { lockOrientationUnderlyingReceivedInvocations = newValue } }
    }
    var lockOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        lockOrientationCallsCountLock.withLock { lockOrientationUnderlyingCallsCount += 1 }
        lockOrientationReceivedOrientation = orientation
        lockOrientationReceivedInvocationsLock.withLock { lockOrientationUnderlyingReceivedInvocations.append(orientation) }
        lockOrientationClosure?(orientation)
    }
}
class PHGPostHogMock: PHGPostHogProtocol, @unchecked Sendable {

    //MARK: - optIn

    private let optInCallsCountLock = NSLock()
    private var optInUnderlyingCallsCount = 0
    var optInCallsCount: Int {
        get { optInCallsCountLock.withLock { optInUnderlyingCallsCount } }
        set { optInCallsCountLock.withLock { optInUnderlyingCallsCount = newValue } }
    }
    var optInCalled: Bool {
        return optInCallsCount > 0
    }
    var optInClosure: (() -> Void)?

    func optIn() {
        optInCallsCountLock.withLock { optInUnderlyingCallsCount += 1 }
        optInClosure?()
    }
    //MARK: - optOut

    private let optOutCallsCountLock = NSLock()
    private var optOutUnderlyingCallsCount = 0
    var optOutCallsCount: Int {
        get { optOutCallsCountLock.withLock { optOutUnderlyingCallsCount } }
        set { optOutCallsCountLock.withLock { optOutUnderlyingCallsCount = newValue } }
    }
    var optOutCalled: Bool {
        return optOutCallsCount > 0
    }
    var optOutClosure: (() -> Void)?

    func optOut() {
        optOutCallsCountLock.withLock { optOutUnderlyingCallsCount += 1 }
        optOutClosure?()
    }
    //MARK: - reset

    private let resetCallsCountLock = NSLock()
    private var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get { resetCallsCountLock.withLock { resetUnderlyingCallsCount } }
        set { resetCallsCountLock.withLock { resetUnderlyingCallsCount = newValue } }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCountLock.withLock { resetUnderlyingCallsCount += 1 }
        resetClosure?()
    }
    //MARK: - capture

    private let capturePropertiesUserPropertiesCallsCountLock = NSLock()
    private var capturePropertiesUserPropertiesUnderlyingCallsCount = 0
    var capturePropertiesUserPropertiesCallsCount: Int {
        get { capturePropertiesUserPropertiesCallsCountLock.withLock { capturePropertiesUserPropertiesUnderlyingCallsCount } }
        set { capturePropertiesUserPropertiesCallsCountLock.withLock { capturePropertiesUserPropertiesUnderlyingCallsCount = newValue } }
    }
    var capturePropertiesUserPropertiesCalled: Bool {
        return capturePropertiesUserPropertiesCallsCount > 0
    }
    private let capturePropertiesUserPropertiesReceivedArgumentsLock = NSLock()
    private var capturePropertiesUserPropertiesUnderlyingReceivedArguments: (event: String, properties: [String: Any]?, userProperties: [String: Any]?)?
    var capturePropertiesUserPropertiesReceivedArguments: (event: String, properties: [String: Any]?, userProperties: [String: Any]?)? {
        get { capturePropertiesUserPropertiesReceivedArgumentsLock.withLock { capturePropertiesUserPropertiesUnderlyingReceivedArguments } }
        set { capturePropertiesUserPropertiesReceivedArgumentsLock.withLock { capturePropertiesUserPropertiesUnderlyingReceivedArguments = newValue } }
    }
    private let capturePropertiesUserPropertiesReceivedInvocationsLock = NSLock()
    private var capturePropertiesUserPropertiesUnderlyingReceivedInvocations: [(event: String, properties: [String: Any]?, userProperties: [String: Any]?)] = []
    var capturePropertiesUserPropertiesReceivedInvocations: [(event: String, properties: [String: Any]?, userProperties: [String: Any]?)] {
        get { capturePropertiesUserPropertiesReceivedInvocationsLock.withLock { capturePropertiesUserPropertiesUnderlyingReceivedInvocations } }
        set { capturePropertiesUserPropertiesReceivedInvocationsLock.withLock { capturePropertiesUserPropertiesUnderlyingReceivedInvocations = newValue } }
    }
    var capturePropertiesUserPropertiesClosure: ((String, [String: Any]?, [String: Any]?) -> Void)?

    func capture(_ event: String, properties: [String: Any]?, userProperties: [String: Any]?) {
        capturePropertiesUserPropertiesCallsCountLock.withLock { capturePropertiesUserPropertiesUnderlyingCallsCount += 1 }
        capturePropertiesUserPropertiesReceivedArguments = (event: event, properties: properties, userProperties: userProperties)
        capturePropertiesUserPropertiesReceivedInvocationsLock.withLock { capturePropertiesUserPropertiesUnderlyingReceivedInvocations.append((event: event, properties: properties, userProperties: userProperties)) }
        capturePropertiesUserPropertiesClosure?(event, properties, userProperties)
    }
    //MARK: - screen

    private let screenPropertiesCallsCountLock = NSLock()
    private var screenPropertiesUnderlyingCallsCount = 0
    var screenPropertiesCallsCount: Int {
        get { screenPropertiesCallsCountLock.withLock { screenPropertiesUnderlyingCallsCount } }
        set { screenPropertiesCallsCountLock.withLock { screenPropertiesUnderlyingCallsCount = newValue } }
    }
    var screenPropertiesCalled: Bool {
        return screenPropertiesCallsCount > 0
    }
    private let screenPropertiesReceivedArgumentsLock = NSLock()
    private var screenPropertiesUnderlyingReceivedArguments: (screenTitle: String, properties: [String: Any]?)?
    var screenPropertiesReceivedArguments: (screenTitle: String, properties: [String: Any]?)? {
        get { screenPropertiesReceivedArgumentsLock.withLock { screenPropertiesUnderlyingReceivedArguments } }
        set { screenPropertiesReceivedArgumentsLock.withLock { screenPropertiesUnderlyingReceivedArguments = newValue } }
    }
    private let screenPropertiesReceivedInvocationsLock = NSLock()
    private var screenPropertiesUnderlyingReceivedInvocations: [(screenTitle: String, properties: [String: Any]?)] = []
    var screenPropertiesReceivedInvocations: [(screenTitle: String, properties: [String: Any]?)] {
        get { screenPropertiesReceivedInvocationsLock.withLock { screenPropertiesUnderlyingReceivedInvocations } }
        set { screenPropertiesReceivedInvocationsLock.withLock { screenPropertiesUnderlyingReceivedInvocations = newValue } }
    }
    var screenPropertiesClosure: ((String, [String: Any]?) -> Void)?

    func screen(_ screenTitle: String, properties: [String: Any]?) {
        screenPropertiesCallsCountLock.withLock { screenPropertiesUnderlyingCallsCount += 1 }
        screenPropertiesReceivedArguments = (screenTitle: screenTitle, properties: properties)
        screenPropertiesReceivedInvocationsLock.withLock { screenPropertiesUnderlyingReceivedInvocations.append((screenTitle: screenTitle, properties: properties)) }
        screenPropertiesClosure?(screenTitle, properties)
    }
}
class PhotoLibraryManagerMock: PhotoLibraryManagerProtocol, @unchecked Sendable {

    //MARK: - addResource

    private let addResourceAtCallsCountLock = NSLock()
    private var addResourceAtUnderlyingCallsCount = 0
    var addResourceAtCallsCount: Int {
        get { addResourceAtCallsCountLock.withLock { addResourceAtUnderlyingCallsCount } }
        set { addResourceAtCallsCountLock.withLock { addResourceAtUnderlyingCallsCount = newValue } }
    }
    var addResourceAtCalled: Bool {
        return addResourceAtCallsCount > 0
    }
    private let addResourceAtReceivedArgumentsLock = NSLock()
    private var addResourceAtUnderlyingReceivedArguments: (type: PHAssetResourceType, url: URL)?
    var addResourceAtReceivedArguments: (type: PHAssetResourceType, url: URL)? {
        get { addResourceAtReceivedArgumentsLock.withLock { addResourceAtUnderlyingReceivedArguments } }
        set { addResourceAtReceivedArgumentsLock.withLock { addResourceAtUnderlyingReceivedArguments = newValue } }
    }
    private let addResourceAtReceivedInvocationsLock = NSLock()
    private var addResourceAtUnderlyingReceivedInvocations: [(type: PHAssetResourceType, url: URL)] = []
    var addResourceAtReceivedInvocations: [(type: PHAssetResourceType, url: URL)] {
        get { addResourceAtReceivedInvocationsLock.withLock { addResourceAtUnderlyingReceivedInvocations } }
        set { addResourceAtReceivedInvocationsLock.withLock { addResourceAtUnderlyingReceivedInvocations = newValue } }
    }

    private let addResourceAtReturnValueLock = NSLock()
    private var addResourceAtUnderlyingReturnValue: Result<Void, PhotoLibraryManagerError>!
    var addResourceAtReturnValue: Result<Void, PhotoLibraryManagerError>! {
        get { addResourceAtReturnValueLock.withLock { addResourceAtUnderlyingReturnValue } }
        set { addResourceAtReturnValueLock.withLock { addResourceAtUnderlyingReturnValue = newValue } }
    }
    var addResourceAtClosure: ((PHAssetResourceType, URL) async -> Result<Void, PhotoLibraryManagerError>)?

    func addResource(_ type: PHAssetResourceType, at url: URL) async -> Result<Void, PhotoLibraryManagerError> {
        addResourceAtCallsCountLock.withLock { addResourceAtUnderlyingCallsCount += 1 }
        addResourceAtReceivedArguments = (type: type, url: url)
        addResourceAtReceivedInvocationsLock.withLock { addResourceAtUnderlyingReceivedInvocations.append((type: type, url: url)) }
        if let addResourceAtClosure = addResourceAtClosure {
            return await addResourceAtClosure(type, url)
        } else {
            return addResourceAtReturnValue
        }
    }
}
class PollInteractionHandlerMock: PollInteractionHandlerProtocol, @unchecked Sendable {

    //MARK: - sendPollResponse

    private let sendPollResponsePollStartIDOptionIDCallsCountLock = NSLock()
    private var sendPollResponsePollStartIDOptionIDUnderlyingCallsCount = 0
    var sendPollResponsePollStartIDOptionIDCallsCount: Int {
        get { sendPollResponsePollStartIDOptionIDCallsCountLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingCallsCount } }
        set { sendPollResponsePollStartIDOptionIDCallsCountLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingCallsCount = newValue } }
    }
    var sendPollResponsePollStartIDOptionIDCalled: Bool {
        return sendPollResponsePollStartIDOptionIDCallsCount > 0
    }
    private let sendPollResponsePollStartIDOptionIDReceivedArgumentsLock = NSLock()
    private var sendPollResponsePollStartIDOptionIDUnderlyingReceivedArguments: (pollStartID: String, optionID: String)?
    var sendPollResponsePollStartIDOptionIDReceivedArguments: (pollStartID: String, optionID: String)? {
        get { sendPollResponsePollStartIDOptionIDReceivedArgumentsLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReceivedArguments } }
        set { sendPollResponsePollStartIDOptionIDReceivedArgumentsLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReceivedArguments = newValue } }
    }
    private let sendPollResponsePollStartIDOptionIDReceivedInvocationsLock = NSLock()
    private var sendPollResponsePollStartIDOptionIDUnderlyingReceivedInvocations: [(pollStartID: String, optionID: String)] = []
    var sendPollResponsePollStartIDOptionIDReceivedInvocations: [(pollStartID: String, optionID: String)] {
        get { sendPollResponsePollStartIDOptionIDReceivedInvocationsLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReceivedInvocations } }
        set { sendPollResponsePollStartIDOptionIDReceivedInvocationsLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReceivedInvocations = newValue } }
    }

    private let sendPollResponsePollStartIDOptionIDReturnValueLock = NSLock()
    private var sendPollResponsePollStartIDOptionIDUnderlyingReturnValue: Result<Void, Error>!
    var sendPollResponsePollStartIDOptionIDReturnValue: Result<Void, Error>! {
        get { sendPollResponsePollStartIDOptionIDReturnValueLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReturnValue } }
        set { sendPollResponsePollStartIDOptionIDReturnValueLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReturnValue = newValue } }
    }
    var sendPollResponsePollStartIDOptionIDClosure: ((String, String) async -> Result<Void, Error>)?

    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error> {
        sendPollResponsePollStartIDOptionIDCallsCountLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingCallsCount += 1 }
        sendPollResponsePollStartIDOptionIDReceivedArguments = (pollStartID: pollStartID, optionID: optionID)
        sendPollResponsePollStartIDOptionIDReceivedInvocationsLock.withLock { sendPollResponsePollStartIDOptionIDUnderlyingReceivedInvocations.append((pollStartID: pollStartID, optionID: optionID)) }
        if let sendPollResponsePollStartIDOptionIDClosure = sendPollResponsePollStartIDOptionIDClosure {
            return await sendPollResponsePollStartIDOptionIDClosure(pollStartID, optionID)
        } else {
            return sendPollResponsePollStartIDOptionIDReturnValue
        }
    }
    //MARK: - endPoll

    private let endPollPollStartIDCallsCountLock = NSLock()
    private var endPollPollStartIDUnderlyingCallsCount = 0
    var endPollPollStartIDCallsCount: Int {
        get { endPollPollStartIDCallsCountLock.withLock { endPollPollStartIDUnderlyingCallsCount } }
        set { endPollPollStartIDCallsCountLock.withLock { endPollPollStartIDUnderlyingCallsCount = newValue } }
    }
    var endPollPollStartIDCalled: Bool {
        return endPollPollStartIDCallsCount > 0
    }
    private let endPollPollStartIDReceivedPollStartIDLock = NSLock()
    private var endPollPollStartIDUnderlyingReceivedPollStartID: String?
    var endPollPollStartIDReceivedPollStartID: String? {
        get { endPollPollStartIDReceivedPollStartIDLock.withLock { endPollPollStartIDUnderlyingReceivedPollStartID } }
        set { endPollPollStartIDReceivedPollStartIDLock.withLock { endPollPollStartIDUnderlyingReceivedPollStartID = newValue } }
    }
    private let endPollPollStartIDReceivedInvocationsLock = NSLock()
    private var endPollPollStartIDUnderlyingReceivedInvocations: [String] = []
    var endPollPollStartIDReceivedInvocations: [String] {
        get { endPollPollStartIDReceivedInvocationsLock.withLock { endPollPollStartIDUnderlyingReceivedInvocations } }
        set { endPollPollStartIDReceivedInvocationsLock.withLock { endPollPollStartIDUnderlyingReceivedInvocations = newValue } }
    }

    private let endPollPollStartIDReturnValueLock = NSLock()
    private var endPollPollStartIDUnderlyingReturnValue: Result<Void, Error>!
    var endPollPollStartIDReturnValue: Result<Void, Error>! {
        get { endPollPollStartIDReturnValueLock.withLock { endPollPollStartIDUnderlyingReturnValue } }
        set { endPollPollStartIDReturnValueLock.withLock { endPollPollStartIDUnderlyingReturnValue = newValue } }
    }
    var endPollPollStartIDClosure: ((String) async -> Result<Void, Error>)?

    func endPoll(pollStartID: String) async -> Result<Void, Error> {
        endPollPollStartIDCallsCountLock.withLock { endPollPollStartIDUnderlyingCallsCount += 1 }
        endPollPollStartIDReceivedPollStartID = pollStartID
        endPollPollStartIDReceivedInvocationsLock.withLock { endPollPollStartIDUnderlyingReceivedInvocations.append(pollStartID) }
        if let endPollPollStartIDClosure = endPollPollStartIDClosure {
            return await endPollPollStartIDClosure(pollStartID)
        } else {
            return endPollPollStartIDReturnValue
        }
    }
}
class QRCodeLoginServiceMock: QRCodeLoginServiceProtocol, @unchecked Sendable {

    //MARK: - loginWithQRCode

    private let loginWithQRCodeDataCallsCountLock = NSLock()
    private var loginWithQRCodeDataUnderlyingCallsCount = 0
    var loginWithQRCodeDataCallsCount: Int {
        get { loginWithQRCodeDataCallsCountLock.withLock { loginWithQRCodeDataUnderlyingCallsCount } }
        set { loginWithQRCodeDataCallsCountLock.withLock { loginWithQRCodeDataUnderlyingCallsCount = newValue } }
    }
    var loginWithQRCodeDataCalled: Bool {
        return loginWithQRCodeDataCallsCount > 0
    }
    private let loginWithQRCodeDataReceivedDataLock = NSLock()
    private var loginWithQRCodeDataUnderlyingReceivedData: Data?
    var loginWithQRCodeDataReceivedData: Data? {
        get { loginWithQRCodeDataReceivedDataLock.withLock { loginWithQRCodeDataUnderlyingReceivedData } }
        set { loginWithQRCodeDataReceivedDataLock.withLock { loginWithQRCodeDataUnderlyingReceivedData = newValue } }
    }
    private let loginWithQRCodeDataReceivedInvocationsLock = NSLock()
    private var loginWithQRCodeDataUnderlyingReceivedInvocations: [Data] = []
    var loginWithQRCodeDataReceivedInvocations: [Data] {
        get { loginWithQRCodeDataReceivedInvocationsLock.withLock { loginWithQRCodeDataUnderlyingReceivedInvocations } }
        set { loginWithQRCodeDataReceivedInvocationsLock.withLock { loginWithQRCodeDataUnderlyingReceivedInvocations = newValue } }
    }

    private let loginWithQRCodeDataReturnValueLock = NSLock()
    private var loginWithQRCodeDataUnderlyingReturnValue: QRLoginProgressPublisher!
    var loginWithQRCodeDataReturnValue: QRLoginProgressPublisher! {
        get { loginWithQRCodeDataReturnValueLock.withLock { loginWithQRCodeDataUnderlyingReturnValue } }
        set { loginWithQRCodeDataReturnValueLock.withLock { loginWithQRCodeDataUnderlyingReturnValue = newValue } }
    }
    var loginWithQRCodeDataClosure: ((Data) -> QRLoginProgressPublisher)?

    func loginWithQRCode(data: Data) -> QRLoginProgressPublisher {
        loginWithQRCodeDataCallsCountLock.withLock { loginWithQRCodeDataUnderlyingCallsCount += 1 }
        loginWithQRCodeDataReceivedData = data
        loginWithQRCodeDataReceivedInvocationsLock.withLock { loginWithQRCodeDataUnderlyingReceivedInvocations.append(data) }
        if let loginWithQRCodeDataClosure = loginWithQRCodeDataClosure {
            return loginWithQRCodeDataClosure(data)
        } else {
            return loginWithQRCodeDataReturnValue
        }
    }
}
class RoomDirectorySearchProxyMock: RoomDirectorySearchProxyProtocol, @unchecked Sendable {
    var resultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never> {
        get { return underlyingResultsPublisher }
        set(value) { underlyingResultsPublisher = value }
    }
    var underlyingResultsPublisher: CurrentValuePublisher<[RoomDirectorySearchResult], Never>!

    //MARK: - search

    private let searchQueryCallsCountLock = NSLock()
    private var searchQueryUnderlyingCallsCount = 0
    var searchQueryCallsCount: Int {
        get { searchQueryCallsCountLock.withLock { searchQueryUnderlyingCallsCount } }
        set { searchQueryCallsCountLock.withLock { searchQueryUnderlyingCallsCount = newValue } }
    }
    var searchQueryCalled: Bool {
        return searchQueryCallsCount > 0
    }
    private let searchQueryReceivedQueryLock = NSLock()
    private var searchQueryUnderlyingReceivedQuery: String?
    var searchQueryReceivedQuery: String? {
        get { searchQueryReceivedQueryLock.withLock { searchQueryUnderlyingReceivedQuery } }
        set { searchQueryReceivedQueryLock.withLock { searchQueryUnderlyingReceivedQuery = newValue } }
    }
    private let searchQueryReceivedInvocationsLock = NSLock()
    private var searchQueryUnderlyingReceivedInvocations: [String?] = []
    var searchQueryReceivedInvocations: [String?] {
        get { searchQueryReceivedInvocationsLock.withLock { searchQueryUnderlyingReceivedInvocations } }
        set { searchQueryReceivedInvocationsLock.withLock { searchQueryUnderlyingReceivedInvocations = newValue } }
    }

    private let searchQueryReturnValueLock = NSLock()
    private var searchQueryUnderlyingReturnValue: Result<Void, RoomDirectorySearchError>!
    var searchQueryReturnValue: Result<Void, RoomDirectorySearchError>! {
        get { searchQueryReturnValueLock.withLock { searchQueryUnderlyingReturnValue } }
        set { searchQueryReturnValueLock.withLock { searchQueryUnderlyingReturnValue = newValue } }
    }
    var searchQueryClosure: ((String?) async -> Result<Void, RoomDirectorySearchError>)?

    func search(query: String?) async -> Result<Void, RoomDirectorySearchError> {
        searchQueryCallsCountLock.withLock { searchQueryUnderlyingCallsCount += 1 }
        searchQueryReceivedQuery = query
        searchQueryReceivedInvocationsLock.withLock { searchQueryUnderlyingReceivedInvocations.append(query) }
        if let searchQueryClosure = searchQueryClosure {
            return await searchQueryClosure(query)
        } else {
            return searchQueryReturnValue
        }
    }
    //MARK: - nextPage

    private let nextPageCallsCountLock = NSLock()
    private var nextPageUnderlyingCallsCount = 0
    var nextPageCallsCount: Int {
        get { nextPageCallsCountLock.withLock { nextPageUnderlyingCallsCount } }
        set { nextPageCallsCountLock.withLock { nextPageUnderlyingCallsCount = newValue } }
    }
    var nextPageCalled: Bool {
        return nextPageCallsCount > 0
    }

    private let nextPageReturnValueLock = NSLock()
    private var nextPageUnderlyingReturnValue: Result<Void, RoomDirectorySearchError>!
    var nextPageReturnValue: Result<Void, RoomDirectorySearchError>! {
        get { nextPageReturnValueLock.withLock { nextPageUnderlyingReturnValue } }
        set { nextPageReturnValueLock.withLock { nextPageUnderlyingReturnValue = newValue } }
    }
    var nextPageClosure: (() async -> Result<Void, RoomDirectorySearchError>)?

    func nextPage() async -> Result<Void, RoomDirectorySearchError> {
        nextPageCallsCountLock.withLock { nextPageUnderlyingCallsCount += 1 }
        if let nextPageClosure = nextPageClosure {
            return await nextPageClosure()
        } else {
            return nextPageReturnValue
        }
    }
}
class RoomInfoProxyMock: RoomInfoProxyProtocol, @unchecked Sendable {
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var creators: [String] = []
    var displayName: String?
    var rawName: String?
    var topic: String?
    var avatarURL: URL?
    var isEncrypted: Bool {
        get { return underlyingIsEncrypted }
        set(value) { underlyingIsEncrypted = value }
    }
    var underlyingIsEncrypted: Bool!
    var isDirect: Bool {
        get { return underlyingIsDirect }
        set(value) { underlyingIsDirect = value }
    }
    var underlyingIsDirect: Bool!
    var isDM: Bool {
        get { return underlyingIsDM }
        set(value) { underlyingIsDM = value }
    }
    var underlyingIsDM: Bool!
    var isSpace: Bool {
        get { return underlyingIsSpace }
        set(value) { underlyingIsSpace = value }
    }
    var underlyingIsSpace: Bool!
    var isFavourite: Bool {
        get { return underlyingIsFavourite }
        set(value) { underlyingIsFavourite = value }
    }
    var underlyingIsFavourite: Bool!
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var membership: Membership {
        get { return underlyingMembership }
        set(value) { underlyingMembership = value }
    }
    var underlyingMembership: Membership!
    var inviter: RoomMemberProxyProtocol?
    var activeMembersCount: Int {
        get { return underlyingActiveMembersCount }
        set(value) { underlyingActiveMembersCount = value }
    }
    var underlyingActiveMembersCount: Int!
    var invitedMembersCount: Int {
        get { return underlyingInvitedMembersCount }
        set(value) { underlyingInvitedMembersCount = value }
    }
    var underlyingInvitedMembersCount: Int!
    var joinedMembersCount: Int {
        get { return underlyingJoinedMembersCount }
        set(value) { underlyingJoinedMembersCount = value }
    }
    var underlyingJoinedMembersCount: Int!
    var highlightCount: Int {
        get { return underlyingHighlightCount }
        set(value) { underlyingHighlightCount = value }
    }
    var underlyingHighlightCount: Int!
    var notificationCount: Int {
        get { return underlyingNotificationCount }
        set(value) { underlyingNotificationCount = value }
    }
    var underlyingNotificationCount: Int!
    var cachedUserDefinedNotificationMode: RoomNotificationMode?
    var hasRoomCall: Bool {
        get { return underlyingHasRoomCall }
        set(value) { underlyingHasRoomCall = value }
    }
    var underlyingHasRoomCall: Bool!
    var activeRoomCallIntent: CallIntent?
    var activeRoomCallParticipants: [String] = []
    var isMarkedUnread: Bool {
        get { return underlyingIsMarkedUnread }
        set(value) { underlyingIsMarkedUnread = value }
    }
    var underlyingIsMarkedUnread: Bool!
    var unreadMessagesCount: UInt {
        get { return underlyingUnreadMessagesCount }
        set(value) { underlyingUnreadMessagesCount = value }
    }
    var underlyingUnreadMessagesCount: UInt!
    var unreadNotificationsCount: UInt {
        get { return underlyingUnreadNotificationsCount }
        set(value) { underlyingUnreadNotificationsCount = value }
    }
    var underlyingUnreadNotificationsCount: UInt!
    var unreadMentionsCount: UInt {
        get { return underlyingUnreadMentionsCount }
        set(value) { underlyingUnreadMentionsCount = value }
    }
    var underlyingUnreadMentionsCount: UInt!
    var fullyReadEventID: String?
    var pinnedEventIDs: Set<String> {
        get { return underlyingPinnedEventIDs }
        set(value) { underlyingPinnedEventIDs = value }
    }
    var underlyingPinnedEventIDs: Set<String>!
    var joinRule: JoinRule?
    var historyVisibility: RoomHistoryVisibility {
        get { return underlyingHistoryVisibility }
        set(value) { underlyingHistoryVisibility = value }
    }
    var underlyingHistoryVisibility: RoomHistoryVisibility!
    var powerLevels: RoomPowerLevelsProxyProtocol?
    var successor: SuccessorRoom?
    var heroes: [RoomHero] = []

}
class RoomLiveLocationServiceMock: RoomLiveLocationServiceProtocol, @unchecked Sendable {
    var liveLocationsPublisher: CurrentValuePublisher<[LiveLocationShare], Never> {
        get { return underlyingLiveLocationsPublisher }
        set(value) { underlyingLiveLocationsPublisher = value }
    }
    var underlyingLiveLocationsPublisher: CurrentValuePublisher<[LiveLocationShare], Never>!

}
class RoomMemberProxyMock: RoomMemberProxyProtocol, @unchecked Sendable {
    var userID: String {
        get { return underlyingUserID }
        set(value) { underlyingUserID = value }
    }
    var underlyingUserID: String!
    var displayName: String?
    var disambiguatedDisplayName: String?
    var avatarURL: URL?
    var membership: MembershipState {
        get { return underlyingMembership }
        set(value) { underlyingMembership = value }
    }
    var underlyingMembership: MembershipState!
    var membershipChangeReason: String?
    var isIgnored: Bool {
        get { return underlyingIsIgnored }
        set(value) { underlyingIsIgnored = value }
    }
    var underlyingIsIgnored: Bool!
    var powerLevel: RoomPowerLevel {
        get { return underlyingPowerLevel }
        set(value) { underlyingPowerLevel = value }
    }
    var underlyingPowerLevel: RoomPowerLevel!
    var isServiceMember: Bool {
        get { return underlyingIsServiceMember }
        set(value) { underlyingIsServiceMember = value }
    }
    var underlyingIsServiceMember: Bool!

}
class RoomMembershipDetailsProxyMock: RoomMembershipDetailsProxyProtocol, @unchecked Sendable {
    var ownRoomMember: RoomMemberProxyProtocol {
        get { return underlyingOwnRoomMember }
        set(value) { underlyingOwnRoomMember = value }
    }
    var underlyingOwnRoomMember: RoomMemberProxyProtocol!
    var senderRoomMember: RoomMemberProxyProtocol?

}
class RoomNotificationSettingsProxyMock: RoomNotificationSettingsProxyProtocol, @unchecked Sendable {
    var mode: RoomNotificationModeProxy {
        get { return underlyingMode }
        set(value) { underlyingMode = value }
    }
    var underlyingMode: RoomNotificationModeProxy!
    var isDefault: Bool {
        get { return underlyingIsDefault }
        set(value) { underlyingIsDefault = value }
    }
    var underlyingIsDefault: Bool!

}
class RoomPowerLevelsProxyMock: RoomPowerLevelsProxyProtocol, @unchecked Sendable {
    var values: RoomPowerLevelsValues {
        get { return underlyingValues }
        set(value) { underlyingValues = value }
    }
    var underlyingValues: RoomPowerLevelsValues!
    var userPowerLevels: [String: Int64] = [:]

    //MARK: - canOwnUser

    private let canOwnUserSendMessageCallsCountLock = NSLock()
    private var canOwnUserSendMessageUnderlyingCallsCount = 0
    var canOwnUserSendMessageCallsCount: Int {
        get { canOwnUserSendMessageCallsCountLock.withLock { canOwnUserSendMessageUnderlyingCallsCount } }
        set { canOwnUserSendMessageCallsCountLock.withLock { canOwnUserSendMessageUnderlyingCallsCount = newValue } }
    }
    var canOwnUserSendMessageCalled: Bool {
        return canOwnUserSendMessageCallsCount > 0
    }
    private let canOwnUserSendMessageReceivedMessageTypeLock = NSLock()
    private var canOwnUserSendMessageUnderlyingReceivedMessageType: MessageLikeEventType?
    var canOwnUserSendMessageReceivedMessageType: MessageLikeEventType? {
        get { canOwnUserSendMessageReceivedMessageTypeLock.withLock { canOwnUserSendMessageUnderlyingReceivedMessageType } }
        set { canOwnUserSendMessageReceivedMessageTypeLock.withLock { canOwnUserSendMessageUnderlyingReceivedMessageType = newValue } }
    }
    private let canOwnUserSendMessageReceivedInvocationsLock = NSLock()
    private var canOwnUserSendMessageUnderlyingReceivedInvocations: [MessageLikeEventType] = []
    var canOwnUserSendMessageReceivedInvocations: [MessageLikeEventType] {
        get { canOwnUserSendMessageReceivedInvocationsLock.withLock { canOwnUserSendMessageUnderlyingReceivedInvocations } }
        set { canOwnUserSendMessageReceivedInvocationsLock.withLock { canOwnUserSendMessageUnderlyingReceivedInvocations = newValue } }
    }

    private let canOwnUserSendMessageReturnValueLock = NSLock()
    private var canOwnUserSendMessageUnderlyingReturnValue: Bool!
    var canOwnUserSendMessageReturnValue: Bool! {
        get { canOwnUserSendMessageReturnValueLock.withLock { canOwnUserSendMessageUnderlyingReturnValue } }
        set { canOwnUserSendMessageReturnValueLock.withLock { canOwnUserSendMessageUnderlyingReturnValue = newValue } }
    }
    var canOwnUserSendMessageClosure: ((MessageLikeEventType) -> Bool)?

    func canOwnUser(sendMessage messageType: MessageLikeEventType) -> Bool {
        canOwnUserSendMessageCallsCountLock.withLock { canOwnUserSendMessageUnderlyingCallsCount += 1 }
        canOwnUserSendMessageReceivedMessageType = messageType
        canOwnUserSendMessageReceivedInvocationsLock.withLock { canOwnUserSendMessageUnderlyingReceivedInvocations.append(messageType) }
        if let canOwnUserSendMessageClosure = canOwnUserSendMessageClosure {
            return canOwnUserSendMessageClosure(messageType)
        } else {
            return canOwnUserSendMessageReturnValue
        }
    }
    //MARK: - canOwnUser

    private let canOwnUserSendStateEventCallsCountLock = NSLock()
    private var canOwnUserSendStateEventUnderlyingCallsCount = 0
    var canOwnUserSendStateEventCallsCount: Int {
        get { canOwnUserSendStateEventCallsCountLock.withLock { canOwnUserSendStateEventUnderlyingCallsCount } }
        set { canOwnUserSendStateEventCallsCountLock.withLock { canOwnUserSendStateEventUnderlyingCallsCount = newValue } }
    }
    var canOwnUserSendStateEventCalled: Bool {
        return canOwnUserSendStateEventCallsCount > 0
    }
    private let canOwnUserSendStateEventReceivedEventLock = NSLock()
    private var canOwnUserSendStateEventUnderlyingReceivedEvent: StateEventType?
    var canOwnUserSendStateEventReceivedEvent: StateEventType? {
        get { canOwnUserSendStateEventReceivedEventLock.withLock { canOwnUserSendStateEventUnderlyingReceivedEvent } }
        set { canOwnUserSendStateEventReceivedEventLock.withLock { canOwnUserSendStateEventUnderlyingReceivedEvent = newValue } }
    }
    private let canOwnUserSendStateEventReceivedInvocationsLock = NSLock()
    private var canOwnUserSendStateEventUnderlyingReceivedInvocations: [StateEventType] = []
    var canOwnUserSendStateEventReceivedInvocations: [StateEventType] {
        get { canOwnUserSendStateEventReceivedInvocationsLock.withLock { canOwnUserSendStateEventUnderlyingReceivedInvocations } }
        set { canOwnUserSendStateEventReceivedInvocationsLock.withLock { canOwnUserSendStateEventUnderlyingReceivedInvocations = newValue } }
    }

    private let canOwnUserSendStateEventReturnValueLock = NSLock()
    private var canOwnUserSendStateEventUnderlyingReturnValue: Bool!
    var canOwnUserSendStateEventReturnValue: Bool! {
        get { canOwnUserSendStateEventReturnValueLock.withLock { canOwnUserSendStateEventUnderlyingReturnValue } }
        set { canOwnUserSendStateEventReturnValueLock.withLock { canOwnUserSendStateEventUnderlyingReturnValue = newValue } }
    }
    var canOwnUserSendStateEventClosure: ((StateEventType) -> Bool)?

    func canOwnUser(sendStateEvent event: StateEventType) -> Bool {
        canOwnUserSendStateEventCallsCountLock.withLock { canOwnUserSendStateEventUnderlyingCallsCount += 1 }
        canOwnUserSendStateEventReceivedEvent = event
        canOwnUserSendStateEventReceivedInvocationsLock.withLock { canOwnUserSendStateEventUnderlyingReceivedInvocations.append(event) }
        if let canOwnUserSendStateEventClosure = canOwnUserSendStateEventClosure {
            return canOwnUserSendStateEventClosure(event)
        } else {
            return canOwnUserSendStateEventReturnValue
        }
    }
    //MARK: - canOwnUserInvite

    private let canOwnUserInviteCallsCountLock = NSLock()
    private var canOwnUserInviteUnderlyingCallsCount = 0
    var canOwnUserInviteCallsCount: Int {
        get { canOwnUserInviteCallsCountLock.withLock { canOwnUserInviteUnderlyingCallsCount } }
        set { canOwnUserInviteCallsCountLock.withLock { canOwnUserInviteUnderlyingCallsCount = newValue } }
    }
    var canOwnUserInviteCalled: Bool {
        return canOwnUserInviteCallsCount > 0
    }

    private let canOwnUserInviteReturnValueLock = NSLock()
    private var canOwnUserInviteUnderlyingReturnValue: Bool!
    var canOwnUserInviteReturnValue: Bool! {
        get { canOwnUserInviteReturnValueLock.withLock { canOwnUserInviteUnderlyingReturnValue } }
        set { canOwnUserInviteReturnValueLock.withLock { canOwnUserInviteUnderlyingReturnValue = newValue } }
    }
    var canOwnUserInviteClosure: (() -> Bool)?

    func canOwnUserInvite() -> Bool {
        canOwnUserInviteCallsCountLock.withLock { canOwnUserInviteUnderlyingCallsCount += 1 }
        if let canOwnUserInviteClosure = canOwnUserInviteClosure {
            return canOwnUserInviteClosure()
        } else {
            return canOwnUserInviteReturnValue
        }
    }
    //MARK: - canOwnUserRedactOther

    private let canOwnUserRedactOtherCallsCountLock = NSLock()
    private var canOwnUserRedactOtherUnderlyingCallsCount = 0
    var canOwnUserRedactOtherCallsCount: Int {
        get { canOwnUserRedactOtherCallsCountLock.withLock { canOwnUserRedactOtherUnderlyingCallsCount } }
        set { canOwnUserRedactOtherCallsCountLock.withLock { canOwnUserRedactOtherUnderlyingCallsCount = newValue } }
    }
    var canOwnUserRedactOtherCalled: Bool {
        return canOwnUserRedactOtherCallsCount > 0
    }

    private let canOwnUserRedactOtherReturnValueLock = NSLock()
    private var canOwnUserRedactOtherUnderlyingReturnValue: Bool!
    var canOwnUserRedactOtherReturnValue: Bool! {
        get { canOwnUserRedactOtherReturnValueLock.withLock { canOwnUserRedactOtherUnderlyingReturnValue } }
        set { canOwnUserRedactOtherReturnValueLock.withLock { canOwnUserRedactOtherUnderlyingReturnValue = newValue } }
    }
    var canOwnUserRedactOtherClosure: (() -> Bool)?

    func canOwnUserRedactOther() -> Bool {
        canOwnUserRedactOtherCallsCountLock.withLock { canOwnUserRedactOtherUnderlyingCallsCount += 1 }
        if let canOwnUserRedactOtherClosure = canOwnUserRedactOtherClosure {
            return canOwnUserRedactOtherClosure()
        } else {
            return canOwnUserRedactOtherReturnValue
        }
    }
    //MARK: - canOwnUserRedactOwn

    private let canOwnUserRedactOwnCallsCountLock = NSLock()
    private var canOwnUserRedactOwnUnderlyingCallsCount = 0
    var canOwnUserRedactOwnCallsCount: Int {
        get { canOwnUserRedactOwnCallsCountLock.withLock { canOwnUserRedactOwnUnderlyingCallsCount } }
        set { canOwnUserRedactOwnCallsCountLock.withLock { canOwnUserRedactOwnUnderlyingCallsCount = newValue } }
    }
    var canOwnUserRedactOwnCalled: Bool {
        return canOwnUserRedactOwnCallsCount > 0
    }

    private let canOwnUserRedactOwnReturnValueLock = NSLock()
    private var canOwnUserRedactOwnUnderlyingReturnValue: Bool!
    var canOwnUserRedactOwnReturnValue: Bool! {
        get { canOwnUserRedactOwnReturnValueLock.withLock { canOwnUserRedactOwnUnderlyingReturnValue } }
        set { canOwnUserRedactOwnReturnValueLock.withLock { canOwnUserRedactOwnUnderlyingReturnValue = newValue } }
    }
    var canOwnUserRedactOwnClosure: (() -> Bool)?

    func canOwnUserRedactOwn() -> Bool {
        canOwnUserRedactOwnCallsCountLock.withLock { canOwnUserRedactOwnUnderlyingCallsCount += 1 }
        if let canOwnUserRedactOwnClosure = canOwnUserRedactOwnClosure {
            return canOwnUserRedactOwnClosure()
        } else {
            return canOwnUserRedactOwnReturnValue
        }
    }
    //MARK: - canOwnUserKick

    private let canOwnUserKickCallsCountLock = NSLock()
    private var canOwnUserKickUnderlyingCallsCount = 0
    var canOwnUserKickCallsCount: Int {
        get { canOwnUserKickCallsCountLock.withLock { canOwnUserKickUnderlyingCallsCount } }
        set { canOwnUserKickCallsCountLock.withLock { canOwnUserKickUnderlyingCallsCount = newValue } }
    }
    var canOwnUserKickCalled: Bool {
        return canOwnUserKickCallsCount > 0
    }

    private let canOwnUserKickReturnValueLock = NSLock()
    private var canOwnUserKickUnderlyingReturnValue: Bool!
    var canOwnUserKickReturnValue: Bool! {
        get { canOwnUserKickReturnValueLock.withLock { canOwnUserKickUnderlyingReturnValue } }
        set { canOwnUserKickReturnValueLock.withLock { canOwnUserKickUnderlyingReturnValue = newValue } }
    }
    var canOwnUserKickClosure: (() -> Bool)?

    func canOwnUserKick() -> Bool {
        canOwnUserKickCallsCountLock.withLock { canOwnUserKickUnderlyingCallsCount += 1 }
        if let canOwnUserKickClosure = canOwnUserKickClosure {
            return canOwnUserKickClosure()
        } else {
            return canOwnUserKickReturnValue
        }
    }
    //MARK: - canOwnUserBan

    private let canOwnUserBanCallsCountLock = NSLock()
    private var canOwnUserBanUnderlyingCallsCount = 0
    var canOwnUserBanCallsCount: Int {
        get { canOwnUserBanCallsCountLock.withLock { canOwnUserBanUnderlyingCallsCount } }
        set { canOwnUserBanCallsCountLock.withLock { canOwnUserBanUnderlyingCallsCount = newValue } }
    }
    var canOwnUserBanCalled: Bool {
        return canOwnUserBanCallsCount > 0
    }

    private let canOwnUserBanReturnValueLock = NSLock()
    private var canOwnUserBanUnderlyingReturnValue: Bool!
    var canOwnUserBanReturnValue: Bool! {
        get { canOwnUserBanReturnValueLock.withLock { canOwnUserBanUnderlyingReturnValue } }
        set { canOwnUserBanReturnValueLock.withLock { canOwnUserBanUnderlyingReturnValue = newValue } }
    }
    var canOwnUserBanClosure: (() -> Bool)?

    func canOwnUserBan() -> Bool {
        canOwnUserBanCallsCountLock.withLock { canOwnUserBanUnderlyingCallsCount += 1 }
        if let canOwnUserBanClosure = canOwnUserBanClosure {
            return canOwnUserBanClosure()
        } else {
            return canOwnUserBanReturnValue
        }
    }
    //MARK: - canOwnUserTriggerRoomNotification

    private let canOwnUserTriggerRoomNotificationCallsCountLock = NSLock()
    private var canOwnUserTriggerRoomNotificationUnderlyingCallsCount = 0
    var canOwnUserTriggerRoomNotificationCallsCount: Int {
        get { canOwnUserTriggerRoomNotificationCallsCountLock.withLock { canOwnUserTriggerRoomNotificationUnderlyingCallsCount } }
        set { canOwnUserTriggerRoomNotificationCallsCountLock.withLock { canOwnUserTriggerRoomNotificationUnderlyingCallsCount = newValue } }
    }
    var canOwnUserTriggerRoomNotificationCalled: Bool {
        return canOwnUserTriggerRoomNotificationCallsCount > 0
    }

    private let canOwnUserTriggerRoomNotificationReturnValueLock = NSLock()
    private var canOwnUserTriggerRoomNotificationUnderlyingReturnValue: Bool!
    var canOwnUserTriggerRoomNotificationReturnValue: Bool! {
        get { canOwnUserTriggerRoomNotificationReturnValueLock.withLock { canOwnUserTriggerRoomNotificationUnderlyingReturnValue } }
        set { canOwnUserTriggerRoomNotificationReturnValueLock.withLock { canOwnUserTriggerRoomNotificationUnderlyingReturnValue = newValue } }
    }
    var canOwnUserTriggerRoomNotificationClosure: (() -> Bool)?

    func canOwnUserTriggerRoomNotification() -> Bool {
        canOwnUserTriggerRoomNotificationCallsCountLock.withLock { canOwnUserTriggerRoomNotificationUnderlyingCallsCount += 1 }
        if let canOwnUserTriggerRoomNotificationClosure = canOwnUserTriggerRoomNotificationClosure {
            return canOwnUserTriggerRoomNotificationClosure()
        } else {
            return canOwnUserTriggerRoomNotificationReturnValue
        }
    }
    //MARK: - canOwnUserPinOrUnpin

    private let canOwnUserPinOrUnpinCallsCountLock = NSLock()
    private var canOwnUserPinOrUnpinUnderlyingCallsCount = 0
    var canOwnUserPinOrUnpinCallsCount: Int {
        get { canOwnUserPinOrUnpinCallsCountLock.withLock { canOwnUserPinOrUnpinUnderlyingCallsCount } }
        set { canOwnUserPinOrUnpinCallsCountLock.withLock { canOwnUserPinOrUnpinUnderlyingCallsCount = newValue } }
    }
    var canOwnUserPinOrUnpinCalled: Bool {
        return canOwnUserPinOrUnpinCallsCount > 0
    }

    private let canOwnUserPinOrUnpinReturnValueLock = NSLock()
    private var canOwnUserPinOrUnpinUnderlyingReturnValue: Bool!
    var canOwnUserPinOrUnpinReturnValue: Bool! {
        get { canOwnUserPinOrUnpinReturnValueLock.withLock { canOwnUserPinOrUnpinUnderlyingReturnValue } }
        set { canOwnUserPinOrUnpinReturnValueLock.withLock { canOwnUserPinOrUnpinUnderlyingReturnValue = newValue } }
    }
    var canOwnUserPinOrUnpinClosure: (() -> Bool)?

    func canOwnUserPinOrUnpin() -> Bool {
        canOwnUserPinOrUnpinCallsCountLock.withLock { canOwnUserPinOrUnpinUnderlyingCallsCount += 1 }
        if let canOwnUserPinOrUnpinClosure = canOwnUserPinOrUnpinClosure {
            return canOwnUserPinOrUnpinClosure()
        } else {
            return canOwnUserPinOrUnpinReturnValue
        }
    }
    //MARK: - canOwnUserJoinCall

    private let canOwnUserJoinCallCallsCountLock = NSLock()
    private var canOwnUserJoinCallUnderlyingCallsCount = 0
    var canOwnUserJoinCallCallsCount: Int {
        get { canOwnUserJoinCallCallsCountLock.withLock { canOwnUserJoinCallUnderlyingCallsCount } }
        set { canOwnUserJoinCallCallsCountLock.withLock { canOwnUserJoinCallUnderlyingCallsCount = newValue } }
    }
    var canOwnUserJoinCallCalled: Bool {
        return canOwnUserJoinCallCallsCount > 0
    }

    private let canOwnUserJoinCallReturnValueLock = NSLock()
    private var canOwnUserJoinCallUnderlyingReturnValue: Bool!
    var canOwnUserJoinCallReturnValue: Bool! {
        get { canOwnUserJoinCallReturnValueLock.withLock { canOwnUserJoinCallUnderlyingReturnValue } }
        set { canOwnUserJoinCallReturnValueLock.withLock { canOwnUserJoinCallUnderlyingReturnValue = newValue } }
    }
    var canOwnUserJoinCallClosure: (() -> Bool)?

    func canOwnUserJoinCall() -> Bool {
        canOwnUserJoinCallCallsCountLock.withLock { canOwnUserJoinCallUnderlyingCallsCount += 1 }
        if let canOwnUserJoinCallClosure = canOwnUserJoinCallClosure {
            return canOwnUserJoinCallClosure()
        } else {
            return canOwnUserJoinCallReturnValue
        }
    }
    //MARK: - canOwnUserEditRolesAndPermissions

    private let canOwnUserEditRolesAndPermissionsCallsCountLock = NSLock()
    private var canOwnUserEditRolesAndPermissionsUnderlyingCallsCount = 0
    var canOwnUserEditRolesAndPermissionsCallsCount: Int {
        get { canOwnUserEditRolesAndPermissionsCallsCountLock.withLock { canOwnUserEditRolesAndPermissionsUnderlyingCallsCount } }
        set { canOwnUserEditRolesAndPermissionsCallsCountLock.withLock { canOwnUserEditRolesAndPermissionsUnderlyingCallsCount = newValue } }
    }
    var canOwnUserEditRolesAndPermissionsCalled: Bool {
        return canOwnUserEditRolesAndPermissionsCallsCount > 0
    }

    private let canOwnUserEditRolesAndPermissionsReturnValueLock = NSLock()
    private var canOwnUserEditRolesAndPermissionsUnderlyingReturnValue: Bool!
    var canOwnUserEditRolesAndPermissionsReturnValue: Bool! {
        get { canOwnUserEditRolesAndPermissionsReturnValueLock.withLock { canOwnUserEditRolesAndPermissionsUnderlyingReturnValue } }
        set { canOwnUserEditRolesAndPermissionsReturnValueLock.withLock { canOwnUserEditRolesAndPermissionsUnderlyingReturnValue = newValue } }
    }
    var canOwnUserEditRolesAndPermissionsClosure: (() -> Bool)?

    func canOwnUserEditRolesAndPermissions() -> Bool {
        canOwnUserEditRolesAndPermissionsCallsCountLock.withLock { canOwnUserEditRolesAndPermissionsUnderlyingCallsCount += 1 }
        if let canOwnUserEditRolesAndPermissionsClosure = canOwnUserEditRolesAndPermissionsClosure {
            return canOwnUserEditRolesAndPermissionsClosure()
        } else {
            return canOwnUserEditRolesAndPermissionsReturnValue
        }
    }
    //MARK: - canUser

    private let canUserUserIDSendMessageCallsCountLock = NSLock()
    private var canUserUserIDSendMessageUnderlyingCallsCount = 0
    var canUserUserIDSendMessageCallsCount: Int {
        get { canUserUserIDSendMessageCallsCountLock.withLock { canUserUserIDSendMessageUnderlyingCallsCount } }
        set { canUserUserIDSendMessageCallsCountLock.withLock { canUserUserIDSendMessageUnderlyingCallsCount = newValue } }
    }
    var canUserUserIDSendMessageCalled: Bool {
        return canUserUserIDSendMessageCallsCount > 0
    }
    private let canUserUserIDSendMessageReceivedArgumentsLock = NSLock()
    private var canUserUserIDSendMessageUnderlyingReceivedArguments: (userID: String, messageType: MessageLikeEventType)?
    var canUserUserIDSendMessageReceivedArguments: (userID: String, messageType: MessageLikeEventType)? {
        get { canUserUserIDSendMessageReceivedArgumentsLock.withLock { canUserUserIDSendMessageUnderlyingReceivedArguments } }
        set { canUserUserIDSendMessageReceivedArgumentsLock.withLock { canUserUserIDSendMessageUnderlyingReceivedArguments = newValue } }
    }
    private let canUserUserIDSendMessageReceivedInvocationsLock = NSLock()
    private var canUserUserIDSendMessageUnderlyingReceivedInvocations: [(userID: String, messageType: MessageLikeEventType)] = []
    var canUserUserIDSendMessageReceivedInvocations: [(userID: String, messageType: MessageLikeEventType)] {
        get { canUserUserIDSendMessageReceivedInvocationsLock.withLock { canUserUserIDSendMessageUnderlyingReceivedInvocations } }
        set { canUserUserIDSendMessageReceivedInvocationsLock.withLock { canUserUserIDSendMessageUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserUserIDSendMessageReturnValueLock = NSLock()
    private var canUserUserIDSendMessageUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserUserIDSendMessageReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserUserIDSendMessageReturnValueLock.withLock { canUserUserIDSendMessageUnderlyingReturnValue } }
        set { canUserUserIDSendMessageReturnValueLock.withLock { canUserUserIDSendMessageUnderlyingReturnValue = newValue } }
    }
    var canUserUserIDSendMessageClosure: ((String, MessageLikeEventType) -> Result<Bool, RoomProxyError>)?

    func canUser(userID: String, sendMessage messageType: MessageLikeEventType) -> Result<Bool, RoomProxyError> {
        canUserUserIDSendMessageCallsCountLock.withLock { canUserUserIDSendMessageUnderlyingCallsCount += 1 }
        canUserUserIDSendMessageReceivedArguments = (userID: userID, messageType: messageType)
        canUserUserIDSendMessageReceivedInvocationsLock.withLock { canUserUserIDSendMessageUnderlyingReceivedInvocations.append((userID: userID, messageType: messageType)) }
        if let canUserUserIDSendMessageClosure = canUserUserIDSendMessageClosure {
            return canUserUserIDSendMessageClosure(userID, messageType)
        } else {
            return canUserUserIDSendMessageReturnValue
        }
    }
    //MARK: - canUser

    private let canUserUserIDSendStateEventCallsCountLock = NSLock()
    private var canUserUserIDSendStateEventUnderlyingCallsCount = 0
    var canUserUserIDSendStateEventCallsCount: Int {
        get { canUserUserIDSendStateEventCallsCountLock.withLock { canUserUserIDSendStateEventUnderlyingCallsCount } }
        set { canUserUserIDSendStateEventCallsCountLock.withLock { canUserUserIDSendStateEventUnderlyingCallsCount = newValue } }
    }
    var canUserUserIDSendStateEventCalled: Bool {
        return canUserUserIDSendStateEventCallsCount > 0
    }
    private let canUserUserIDSendStateEventReceivedArgumentsLock = NSLock()
    private var canUserUserIDSendStateEventUnderlyingReceivedArguments: (userID: String, event: StateEventType)?
    var canUserUserIDSendStateEventReceivedArguments: (userID: String, event: StateEventType)? {
        get { canUserUserIDSendStateEventReceivedArgumentsLock.withLock { canUserUserIDSendStateEventUnderlyingReceivedArguments } }
        set { canUserUserIDSendStateEventReceivedArgumentsLock.withLock { canUserUserIDSendStateEventUnderlyingReceivedArguments = newValue } }
    }
    private let canUserUserIDSendStateEventReceivedInvocationsLock = NSLock()
    private var canUserUserIDSendStateEventUnderlyingReceivedInvocations: [(userID: String, event: StateEventType)] = []
    var canUserUserIDSendStateEventReceivedInvocations: [(userID: String, event: StateEventType)] {
        get { canUserUserIDSendStateEventReceivedInvocationsLock.withLock { canUserUserIDSendStateEventUnderlyingReceivedInvocations } }
        set { canUserUserIDSendStateEventReceivedInvocationsLock.withLock { canUserUserIDSendStateEventUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserUserIDSendStateEventReturnValueLock = NSLock()
    private var canUserUserIDSendStateEventUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserUserIDSendStateEventReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserUserIDSendStateEventReturnValueLock.withLock { canUserUserIDSendStateEventUnderlyingReturnValue } }
        set { canUserUserIDSendStateEventReturnValueLock.withLock { canUserUserIDSendStateEventUnderlyingReturnValue = newValue } }
    }
    var canUserUserIDSendStateEventClosure: ((String, StateEventType) -> Result<Bool, RoomProxyError>)?

    func canUser(userID: String, sendStateEvent event: StateEventType) -> Result<Bool, RoomProxyError> {
        canUserUserIDSendStateEventCallsCountLock.withLock { canUserUserIDSendStateEventUnderlyingCallsCount += 1 }
        canUserUserIDSendStateEventReceivedArguments = (userID: userID, event: event)
        canUserUserIDSendStateEventReceivedInvocationsLock.withLock { canUserUserIDSendStateEventUnderlyingReceivedInvocations.append((userID: userID, event: event)) }
        if let canUserUserIDSendStateEventClosure = canUserUserIDSendStateEventClosure {
            return canUserUserIDSendStateEventClosure(userID, event)
        } else {
            return canUserUserIDSendStateEventReturnValue
        }
    }
    //MARK: - canUserInvite

    private let canUserInviteUserIDCallsCountLock = NSLock()
    private var canUserInviteUserIDUnderlyingCallsCount = 0
    var canUserInviteUserIDCallsCount: Int {
        get { canUserInviteUserIDCallsCountLock.withLock { canUserInviteUserIDUnderlyingCallsCount } }
        set { canUserInviteUserIDCallsCountLock.withLock { canUserInviteUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserInviteUserIDCalled: Bool {
        return canUserInviteUserIDCallsCount > 0
    }
    private let canUserInviteUserIDReceivedUserIDLock = NSLock()
    private var canUserInviteUserIDUnderlyingReceivedUserID: String?
    var canUserInviteUserIDReceivedUserID: String? {
        get { canUserInviteUserIDReceivedUserIDLock.withLock { canUserInviteUserIDUnderlyingReceivedUserID } }
        set { canUserInviteUserIDReceivedUserIDLock.withLock { canUserInviteUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserInviteUserIDReceivedInvocationsLock = NSLock()
    private var canUserInviteUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserInviteUserIDReceivedInvocations: [String] {
        get { canUserInviteUserIDReceivedInvocationsLock.withLock { canUserInviteUserIDUnderlyingReceivedInvocations } }
        set { canUserInviteUserIDReceivedInvocationsLock.withLock { canUserInviteUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserInviteUserIDReturnValueLock = NSLock()
    private var canUserInviteUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserInviteUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserInviteUserIDReturnValueLock.withLock { canUserInviteUserIDUnderlyingReturnValue } }
        set { canUserInviteUserIDReturnValueLock.withLock { canUserInviteUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserInviteUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserInvite(userID: String) -> Result<Bool, RoomProxyError> {
        canUserInviteUserIDCallsCountLock.withLock { canUserInviteUserIDUnderlyingCallsCount += 1 }
        canUserInviteUserIDReceivedUserID = userID
        canUserInviteUserIDReceivedInvocationsLock.withLock { canUserInviteUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserInviteUserIDClosure = canUserInviteUserIDClosure {
            return canUserInviteUserIDClosure(userID)
        } else {
            return canUserInviteUserIDReturnValue
        }
    }
    //MARK: - canUserRedactOther

    private let canUserRedactOtherUserIDCallsCountLock = NSLock()
    private var canUserRedactOtherUserIDUnderlyingCallsCount = 0
    var canUserRedactOtherUserIDCallsCount: Int {
        get { canUserRedactOtherUserIDCallsCountLock.withLock { canUserRedactOtherUserIDUnderlyingCallsCount } }
        set { canUserRedactOtherUserIDCallsCountLock.withLock { canUserRedactOtherUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserRedactOtherUserIDCalled: Bool {
        return canUserRedactOtherUserIDCallsCount > 0
    }
    private let canUserRedactOtherUserIDReceivedUserIDLock = NSLock()
    private var canUserRedactOtherUserIDUnderlyingReceivedUserID: String?
    var canUserRedactOtherUserIDReceivedUserID: String? {
        get { canUserRedactOtherUserIDReceivedUserIDLock.withLock { canUserRedactOtherUserIDUnderlyingReceivedUserID } }
        set { canUserRedactOtherUserIDReceivedUserIDLock.withLock { canUserRedactOtherUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserRedactOtherUserIDReceivedInvocationsLock = NSLock()
    private var canUserRedactOtherUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserRedactOtherUserIDReceivedInvocations: [String] {
        get { canUserRedactOtherUserIDReceivedInvocationsLock.withLock { canUserRedactOtherUserIDUnderlyingReceivedInvocations } }
        set { canUserRedactOtherUserIDReceivedInvocationsLock.withLock { canUserRedactOtherUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserRedactOtherUserIDReturnValueLock = NSLock()
    private var canUserRedactOtherUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactOtherUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserRedactOtherUserIDReturnValueLock.withLock { canUserRedactOtherUserIDUnderlyingReturnValue } }
        set { canUserRedactOtherUserIDReturnValueLock.withLock { canUserRedactOtherUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserRedactOtherUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserRedactOther(userID: String) -> Result<Bool, RoomProxyError> {
        canUserRedactOtherUserIDCallsCountLock.withLock { canUserRedactOtherUserIDUnderlyingCallsCount += 1 }
        canUserRedactOtherUserIDReceivedUserID = userID
        canUserRedactOtherUserIDReceivedInvocationsLock.withLock { canUserRedactOtherUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserRedactOtherUserIDClosure = canUserRedactOtherUserIDClosure {
            return canUserRedactOtherUserIDClosure(userID)
        } else {
            return canUserRedactOtherUserIDReturnValue
        }
    }
    //MARK: - canUserRedactOwn

    private let canUserRedactOwnUserIDCallsCountLock = NSLock()
    private var canUserRedactOwnUserIDUnderlyingCallsCount = 0
    var canUserRedactOwnUserIDCallsCount: Int {
        get { canUserRedactOwnUserIDCallsCountLock.withLock { canUserRedactOwnUserIDUnderlyingCallsCount } }
        set { canUserRedactOwnUserIDCallsCountLock.withLock { canUserRedactOwnUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserRedactOwnUserIDCalled: Bool {
        return canUserRedactOwnUserIDCallsCount > 0
    }
    private let canUserRedactOwnUserIDReceivedUserIDLock = NSLock()
    private var canUserRedactOwnUserIDUnderlyingReceivedUserID: String?
    var canUserRedactOwnUserIDReceivedUserID: String? {
        get { canUserRedactOwnUserIDReceivedUserIDLock.withLock { canUserRedactOwnUserIDUnderlyingReceivedUserID } }
        set { canUserRedactOwnUserIDReceivedUserIDLock.withLock { canUserRedactOwnUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserRedactOwnUserIDReceivedInvocationsLock = NSLock()
    private var canUserRedactOwnUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserRedactOwnUserIDReceivedInvocations: [String] {
        get { canUserRedactOwnUserIDReceivedInvocationsLock.withLock { canUserRedactOwnUserIDUnderlyingReceivedInvocations } }
        set { canUserRedactOwnUserIDReceivedInvocationsLock.withLock { canUserRedactOwnUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserRedactOwnUserIDReturnValueLock = NSLock()
    private var canUserRedactOwnUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserRedactOwnUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserRedactOwnUserIDReturnValueLock.withLock { canUserRedactOwnUserIDUnderlyingReturnValue } }
        set { canUserRedactOwnUserIDReturnValueLock.withLock { canUserRedactOwnUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserRedactOwnUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserRedactOwn(userID: String) -> Result<Bool, RoomProxyError> {
        canUserRedactOwnUserIDCallsCountLock.withLock { canUserRedactOwnUserIDUnderlyingCallsCount += 1 }
        canUserRedactOwnUserIDReceivedUserID = userID
        canUserRedactOwnUserIDReceivedInvocationsLock.withLock { canUserRedactOwnUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserRedactOwnUserIDClosure = canUserRedactOwnUserIDClosure {
            return canUserRedactOwnUserIDClosure(userID)
        } else {
            return canUserRedactOwnUserIDReturnValue
        }
    }
    //MARK: - canUserKick

    private let canUserKickUserIDCallsCountLock = NSLock()
    private var canUserKickUserIDUnderlyingCallsCount = 0
    var canUserKickUserIDCallsCount: Int {
        get { canUserKickUserIDCallsCountLock.withLock { canUserKickUserIDUnderlyingCallsCount } }
        set { canUserKickUserIDCallsCountLock.withLock { canUserKickUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserKickUserIDCalled: Bool {
        return canUserKickUserIDCallsCount > 0
    }
    private let canUserKickUserIDReceivedUserIDLock = NSLock()
    private var canUserKickUserIDUnderlyingReceivedUserID: String?
    var canUserKickUserIDReceivedUserID: String? {
        get { canUserKickUserIDReceivedUserIDLock.withLock { canUserKickUserIDUnderlyingReceivedUserID } }
        set { canUserKickUserIDReceivedUserIDLock.withLock { canUserKickUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserKickUserIDReceivedInvocationsLock = NSLock()
    private var canUserKickUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserKickUserIDReceivedInvocations: [String] {
        get { canUserKickUserIDReceivedInvocationsLock.withLock { canUserKickUserIDUnderlyingReceivedInvocations } }
        set { canUserKickUserIDReceivedInvocationsLock.withLock { canUserKickUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserKickUserIDReturnValueLock = NSLock()
    private var canUserKickUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserKickUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserKickUserIDReturnValueLock.withLock { canUserKickUserIDUnderlyingReturnValue } }
        set { canUserKickUserIDReturnValueLock.withLock { canUserKickUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserKickUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserKick(userID: String) -> Result<Bool, RoomProxyError> {
        canUserKickUserIDCallsCountLock.withLock { canUserKickUserIDUnderlyingCallsCount += 1 }
        canUserKickUserIDReceivedUserID = userID
        canUserKickUserIDReceivedInvocationsLock.withLock { canUserKickUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserKickUserIDClosure = canUserKickUserIDClosure {
            return canUserKickUserIDClosure(userID)
        } else {
            return canUserKickUserIDReturnValue
        }
    }
    //MARK: - canUserBan

    private let canUserBanUserIDCallsCountLock = NSLock()
    private var canUserBanUserIDUnderlyingCallsCount = 0
    var canUserBanUserIDCallsCount: Int {
        get { canUserBanUserIDCallsCountLock.withLock { canUserBanUserIDUnderlyingCallsCount } }
        set { canUserBanUserIDCallsCountLock.withLock { canUserBanUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserBanUserIDCalled: Bool {
        return canUserBanUserIDCallsCount > 0
    }
    private let canUserBanUserIDReceivedUserIDLock = NSLock()
    private var canUserBanUserIDUnderlyingReceivedUserID: String?
    var canUserBanUserIDReceivedUserID: String? {
        get { canUserBanUserIDReceivedUserIDLock.withLock { canUserBanUserIDUnderlyingReceivedUserID } }
        set { canUserBanUserIDReceivedUserIDLock.withLock { canUserBanUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserBanUserIDReceivedInvocationsLock = NSLock()
    private var canUserBanUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserBanUserIDReceivedInvocations: [String] {
        get { canUserBanUserIDReceivedInvocationsLock.withLock { canUserBanUserIDUnderlyingReceivedInvocations } }
        set { canUserBanUserIDReceivedInvocationsLock.withLock { canUserBanUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserBanUserIDReturnValueLock = NSLock()
    private var canUserBanUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserBanUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserBanUserIDReturnValueLock.withLock { canUserBanUserIDUnderlyingReturnValue } }
        set { canUserBanUserIDReturnValueLock.withLock { canUserBanUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserBanUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserBan(userID: String) -> Result<Bool, RoomProxyError> {
        canUserBanUserIDCallsCountLock.withLock { canUserBanUserIDUnderlyingCallsCount += 1 }
        canUserBanUserIDReceivedUserID = userID
        canUserBanUserIDReceivedInvocationsLock.withLock { canUserBanUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserBanUserIDClosure = canUserBanUserIDClosure {
            return canUserBanUserIDClosure(userID)
        } else {
            return canUserBanUserIDReturnValue
        }
    }
    //MARK: - canUserTriggerRoomNotification

    private let canUserTriggerRoomNotificationUserIDCallsCountLock = NSLock()
    private var canUserTriggerRoomNotificationUserIDUnderlyingCallsCount = 0
    var canUserTriggerRoomNotificationUserIDCallsCount: Int {
        get { canUserTriggerRoomNotificationUserIDCallsCountLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingCallsCount } }
        set { canUserTriggerRoomNotificationUserIDCallsCountLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserTriggerRoomNotificationUserIDCalled: Bool {
        return canUserTriggerRoomNotificationUserIDCallsCount > 0
    }
    private let canUserTriggerRoomNotificationUserIDReceivedUserIDLock = NSLock()
    private var canUserTriggerRoomNotificationUserIDUnderlyingReceivedUserID: String?
    var canUserTriggerRoomNotificationUserIDReceivedUserID: String? {
        get { canUserTriggerRoomNotificationUserIDReceivedUserIDLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReceivedUserID } }
        set { canUserTriggerRoomNotificationUserIDReceivedUserIDLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserTriggerRoomNotificationUserIDReceivedInvocationsLock = NSLock()
    private var canUserTriggerRoomNotificationUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserTriggerRoomNotificationUserIDReceivedInvocations: [String] {
        get { canUserTriggerRoomNotificationUserIDReceivedInvocationsLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReceivedInvocations } }
        set { canUserTriggerRoomNotificationUserIDReceivedInvocationsLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserTriggerRoomNotificationUserIDReturnValueLock = NSLock()
    private var canUserTriggerRoomNotificationUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserTriggerRoomNotificationUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserTriggerRoomNotificationUserIDReturnValueLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReturnValue } }
        set { canUserTriggerRoomNotificationUserIDReturnValueLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserTriggerRoomNotificationUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserTriggerRoomNotification(userID: String) -> Result<Bool, RoomProxyError> {
        canUserTriggerRoomNotificationUserIDCallsCountLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingCallsCount += 1 }
        canUserTriggerRoomNotificationUserIDReceivedUserID = userID
        canUserTriggerRoomNotificationUserIDReceivedInvocationsLock.withLock { canUserTriggerRoomNotificationUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserTriggerRoomNotificationUserIDClosure = canUserTriggerRoomNotificationUserIDClosure {
            return canUserTriggerRoomNotificationUserIDClosure(userID)
        } else {
            return canUserTriggerRoomNotificationUserIDReturnValue
        }
    }
    //MARK: - canUserPinOrUnpin

    private let canUserPinOrUnpinUserIDCallsCountLock = NSLock()
    private var canUserPinOrUnpinUserIDUnderlyingCallsCount = 0
    var canUserPinOrUnpinUserIDCallsCount: Int {
        get { canUserPinOrUnpinUserIDCallsCountLock.withLock { canUserPinOrUnpinUserIDUnderlyingCallsCount } }
        set { canUserPinOrUnpinUserIDCallsCountLock.withLock { canUserPinOrUnpinUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserPinOrUnpinUserIDCalled: Bool {
        return canUserPinOrUnpinUserIDCallsCount > 0
    }
    private let canUserPinOrUnpinUserIDReceivedUserIDLock = NSLock()
    private var canUserPinOrUnpinUserIDUnderlyingReceivedUserID: String?
    var canUserPinOrUnpinUserIDReceivedUserID: String? {
        get { canUserPinOrUnpinUserIDReceivedUserIDLock.withLock { canUserPinOrUnpinUserIDUnderlyingReceivedUserID } }
        set { canUserPinOrUnpinUserIDReceivedUserIDLock.withLock { canUserPinOrUnpinUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserPinOrUnpinUserIDReceivedInvocationsLock = NSLock()
    private var canUserPinOrUnpinUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserPinOrUnpinUserIDReceivedInvocations: [String] {
        get { canUserPinOrUnpinUserIDReceivedInvocationsLock.withLock { canUserPinOrUnpinUserIDUnderlyingReceivedInvocations } }
        set { canUserPinOrUnpinUserIDReceivedInvocationsLock.withLock { canUserPinOrUnpinUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserPinOrUnpinUserIDReturnValueLock = NSLock()
    private var canUserPinOrUnpinUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserPinOrUnpinUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserPinOrUnpinUserIDReturnValueLock.withLock { canUserPinOrUnpinUserIDUnderlyingReturnValue } }
        set { canUserPinOrUnpinUserIDReturnValueLock.withLock { canUserPinOrUnpinUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserPinOrUnpinUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserPinOrUnpin(userID: String) -> Result<Bool, RoomProxyError> {
        canUserPinOrUnpinUserIDCallsCountLock.withLock { canUserPinOrUnpinUserIDUnderlyingCallsCount += 1 }
        canUserPinOrUnpinUserIDReceivedUserID = userID
        canUserPinOrUnpinUserIDReceivedInvocationsLock.withLock { canUserPinOrUnpinUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserPinOrUnpinUserIDClosure = canUserPinOrUnpinUserIDClosure {
            return canUserPinOrUnpinUserIDClosure(userID)
        } else {
            return canUserPinOrUnpinUserIDReturnValue
        }
    }
    //MARK: - canUserJoinCall

    private let canUserJoinCallUserIDCallsCountLock = NSLock()
    private var canUserJoinCallUserIDUnderlyingCallsCount = 0
    var canUserJoinCallUserIDCallsCount: Int {
        get { canUserJoinCallUserIDCallsCountLock.withLock { canUserJoinCallUserIDUnderlyingCallsCount } }
        set { canUserJoinCallUserIDCallsCountLock.withLock { canUserJoinCallUserIDUnderlyingCallsCount = newValue } }
    }
    var canUserJoinCallUserIDCalled: Bool {
        return canUserJoinCallUserIDCallsCount > 0
    }
    private let canUserJoinCallUserIDReceivedUserIDLock = NSLock()
    private var canUserJoinCallUserIDUnderlyingReceivedUserID: String?
    var canUserJoinCallUserIDReceivedUserID: String? {
        get { canUserJoinCallUserIDReceivedUserIDLock.withLock { canUserJoinCallUserIDUnderlyingReceivedUserID } }
        set { canUserJoinCallUserIDReceivedUserIDLock.withLock { canUserJoinCallUserIDUnderlyingReceivedUserID = newValue } }
    }
    private let canUserJoinCallUserIDReceivedInvocationsLock = NSLock()
    private var canUserJoinCallUserIDUnderlyingReceivedInvocations: [String] = []
    var canUserJoinCallUserIDReceivedInvocations: [String] {
        get { canUserJoinCallUserIDReceivedInvocationsLock.withLock { canUserJoinCallUserIDUnderlyingReceivedInvocations } }
        set { canUserJoinCallUserIDReceivedInvocationsLock.withLock { canUserJoinCallUserIDUnderlyingReceivedInvocations = newValue } }
    }

    private let canUserJoinCallUserIDReturnValueLock = NSLock()
    private var canUserJoinCallUserIDUnderlyingReturnValue: Result<Bool, RoomProxyError>!
    var canUserJoinCallUserIDReturnValue: Result<Bool, RoomProxyError>! {
        get { canUserJoinCallUserIDReturnValueLock.withLock { canUserJoinCallUserIDUnderlyingReturnValue } }
        set { canUserJoinCallUserIDReturnValueLock.withLock { canUserJoinCallUserIDUnderlyingReturnValue = newValue } }
    }
    var canUserJoinCallUserIDClosure: ((String) -> Result<Bool, RoomProxyError>)?

    func canUserJoinCall(userID: String) -> Result<Bool, RoomProxyError> {
        canUserJoinCallUserIDCallsCountLock.withLock { canUserJoinCallUserIDUnderlyingCallsCount += 1 }
        canUserJoinCallUserIDReceivedUserID = userID
        canUserJoinCallUserIDReceivedInvocationsLock.withLock { canUserJoinCallUserIDUnderlyingReceivedInvocations.append(userID) }
        if let canUserJoinCallUserIDClosure = canUserJoinCallUserIDClosure {
            return canUserJoinCallUserIDClosure(userID)
        } else {
            return canUserJoinCallUserIDReturnValue
        }
    }
}
class RoomPreviewProxyMock: RoomPreviewProxyProtocol, @unchecked Sendable {
    var info: RoomPreviewInfoProxy {
        get { return underlyingInfo }
        set(value) { underlyingInfo = value }
    }
    var underlyingInfo: RoomPreviewInfoProxy!
    var ownMembershipDetailsCallsCount = 0
    var ownMembershipDetailsCalled: Bool {
        return ownMembershipDetailsCallsCount > 0
    }

    var ownMembershipDetails: RoomMembershipDetailsProxyProtocol? {
        get async {
            ownMembershipDetailsCallsCount += 1
            if let ownMembershipDetailsClosure = ownMembershipDetailsClosure {
                return await ownMembershipDetailsClosure()
            } else {
                return underlyingOwnMembershipDetails
            }
        }
    }
    var underlyingOwnMembershipDetails: RoomMembershipDetailsProxyProtocol?
    var ownMembershipDetailsClosure: (() async -> RoomMembershipDetailsProxyProtocol?)?

}
class RoomProxyMock: RoomProxyProtocol, @unchecked Sendable {
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var ownUserID: String {
        get { return underlyingOwnUserID }
        set(value) { underlyingOwnUserID = value }
    }
    var underlyingOwnUserID: String!

}
class RoomSummaryProviderMock: RoomSummaryProviderProtocol, @unchecked Sendable {
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> {
        get { return underlyingStatePublisher }
        set(value) { underlyingStatePublisher = value }
    }
    var underlyingStatePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never>!
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> {
        get { return underlyingRoomListPublisher }
        set(value) { underlyingRoomListPublisher = value }
    }
    var underlyingRoomListPublisher: CurrentValuePublisher<[RoomSummary], Never>!

    //MARK: - updateVisibleRange

    private let updateVisibleRangeCallsCountLock = NSLock()
    private var updateVisibleRangeUnderlyingCallsCount = 0
    var updateVisibleRangeCallsCount: Int {
        get { updateVisibleRangeCallsCountLock.withLock { updateVisibleRangeUnderlyingCallsCount } }
        set { updateVisibleRangeCallsCountLock.withLock { updateVisibleRangeUnderlyingCallsCount = newValue } }
    }
    var updateVisibleRangeCalled: Bool {
        return updateVisibleRangeCallsCount > 0
    }
    private let updateVisibleRangeReceivedRangeLock = NSLock()
    private var updateVisibleRangeUnderlyingReceivedRange: Range<Int>?
    var updateVisibleRangeReceivedRange: Range<Int>? {
        get { updateVisibleRangeReceivedRangeLock.withLock { updateVisibleRangeUnderlyingReceivedRange } }
        set { updateVisibleRangeReceivedRangeLock.withLock { updateVisibleRangeUnderlyingReceivedRange = newValue } }
    }
    private let updateVisibleRangeReceivedInvocationsLock = NSLock()
    private var updateVisibleRangeUnderlyingReceivedInvocations: [Range<Int>] = []
    var updateVisibleRangeReceivedInvocations: [Range<Int>] {
        get { updateVisibleRangeReceivedInvocationsLock.withLock { updateVisibleRangeUnderlyingReceivedInvocations } }
        set { updateVisibleRangeReceivedInvocationsLock.withLock { updateVisibleRangeUnderlyingReceivedInvocations = newValue } }
    }
    var updateVisibleRangeClosure: ((Range<Int>) -> Void)?

    func updateVisibleRange(_ range: Range<Int>) {
        updateVisibleRangeCallsCountLock.withLock { updateVisibleRangeUnderlyingCallsCount += 1 }
        updateVisibleRangeReceivedRange = range
        updateVisibleRangeReceivedInvocationsLock.withLock { updateVisibleRangeUnderlyingReceivedInvocations.append(range) }
        updateVisibleRangeClosure?(range)
    }
    //MARK: - setFilter

    private let setFilterCallsCountLock = NSLock()
    private var setFilterUnderlyingCallsCount = 0
    var setFilterCallsCount: Int {
        get { setFilterCallsCountLock.withLock { setFilterUnderlyingCallsCount } }
        set { setFilterCallsCountLock.withLock { setFilterUnderlyingCallsCount = newValue } }
    }
    var setFilterCalled: Bool {
        return setFilterCallsCount > 0
    }
    private let setFilterReceivedFilterLock = NSLock()
    private var setFilterUnderlyingReceivedFilter: RoomSummaryProviderFilter?
    var setFilterReceivedFilter: RoomSummaryProviderFilter? {
        get { setFilterReceivedFilterLock.withLock { setFilterUnderlyingReceivedFilter } }
        set { setFilterReceivedFilterLock.withLock { setFilterUnderlyingReceivedFilter = newValue } }
    }
    private let setFilterReceivedInvocationsLock = NSLock()
    private var setFilterUnderlyingReceivedInvocations: [RoomSummaryProviderFilter] = []
    var setFilterReceivedInvocations: [RoomSummaryProviderFilter] {
        get { setFilterReceivedInvocationsLock.withLock { setFilterUnderlyingReceivedInvocations } }
        set { setFilterReceivedInvocationsLock.withLock { setFilterUnderlyingReceivedInvocations = newValue } }
    }
    var setFilterClosure: ((RoomSummaryProviderFilter) -> Void)?

    func setFilter(_ filter: RoomSummaryProviderFilter) {
        setFilterCallsCountLock.withLock { setFilterUnderlyingCallsCount += 1 }
        setFilterReceivedFilter = filter
        setFilterReceivedInvocationsLock.withLock { setFilterUnderlyingReceivedInvocations.append(filter) }
        setFilterClosure?(filter)
    }
    //MARK: - setRoomList

    private let setRoomListCallsCountLock = NSLock()
    private var setRoomListUnderlyingCallsCount = 0
    var setRoomListCallsCount: Int {
        get { setRoomListCallsCountLock.withLock { setRoomListUnderlyingCallsCount } }
        set { setRoomListCallsCountLock.withLock { setRoomListUnderlyingCallsCount = newValue } }
    }
    var setRoomListCalled: Bool {
        return setRoomListCallsCount > 0
    }
    private let setRoomListReceivedRoomListLock = NSLock()
    private var setRoomListUnderlyingReceivedRoomList: RoomList?
    var setRoomListReceivedRoomList: RoomList? {
        get { setRoomListReceivedRoomListLock.withLock { setRoomListUnderlyingReceivedRoomList } }
        set { setRoomListReceivedRoomListLock.withLock { setRoomListUnderlyingReceivedRoomList = newValue } }
    }
    private let setRoomListReceivedInvocationsLock = NSLock()
    private var setRoomListUnderlyingReceivedInvocations: [RoomList] = []
    var setRoomListReceivedInvocations: [RoomList] {
        get { setRoomListReceivedInvocationsLock.withLock { setRoomListUnderlyingReceivedInvocations } }
        set { setRoomListReceivedInvocationsLock.withLock { setRoomListUnderlyingReceivedInvocations = newValue } }
    }
    var setRoomListClosure: ((RoomList) -> Void)?

    func setRoomList(_ roomList: RoomList) {
        setRoomListCallsCountLock.withLock { setRoomListUnderlyingCallsCount += 1 }
        setRoomListReceivedRoomList = roomList
        setRoomListReceivedInvocationsLock.withLock { setRoomListUnderlyingReceivedInvocations.append(roomList) }
        setRoomListClosure?(roomList)
    }
}
class RoomThreadListServiceProxyMock: RoomThreadListServiceProxyProtocol, @unchecked Sendable {
    var itemsPublisher: CurrentValuePublisher<[RoomThreadListItem], Never> {
        get { return underlyingItemsPublisher }
        set(value) { underlyingItemsPublisher = value }
    }
    var underlyingItemsPublisher: CurrentValuePublisher<[RoomThreadListItem], Never>!
    var paginationStatePublisher: CurrentValuePublisher<RoomThreadListPaginationState, Never> {
        get { return underlyingPaginationStatePublisher }
        set(value) { underlyingPaginationStatePublisher = value }
    }
    var underlyingPaginationStatePublisher: CurrentValuePublisher<RoomThreadListPaginationState, Never>!

    //MARK: - paginate

    private let paginateCallsCountLock = NSLock()
    private var paginateUnderlyingCallsCount = 0
    var paginateCallsCount: Int {
        get { paginateCallsCountLock.withLock { paginateUnderlyingCallsCount } }
        set { paginateCallsCountLock.withLock { paginateUnderlyingCallsCount = newValue } }
    }
    var paginateCalled: Bool {
        return paginateCallsCount > 0
    }

    private let paginateReturnValueLock = NSLock()
    private var paginateUnderlyingReturnValue: Result<Void, RoomProxyError>!
    var paginateReturnValue: Result<Void, RoomProxyError>! {
        get { paginateReturnValueLock.withLock { paginateUnderlyingReturnValue } }
        set { paginateReturnValueLock.withLock { paginateUnderlyingReturnValue = newValue } }
    }
    var paginateClosure: (() async -> Result<Void, RoomProxyError>)?

    func paginate() async -> Result<Void, RoomProxyError> {
        paginateCallsCountLock.withLock { paginateUnderlyingCallsCount += 1 }
        if let paginateClosure = paginateClosure {
            return await paginateClosure()
        } else {
            return paginateReturnValue
        }
    }
}
class SecureBackupControllerMock: SecureBackupControllerProtocol, @unchecked Sendable {
    var recoveryState: CurrentValuePublisher<SecureBackupRecoveryState, Never> {
        get { return underlyingRecoveryState }
        set(value) { underlyingRecoveryState = value }
    }
    var underlyingRecoveryState: CurrentValuePublisher<SecureBackupRecoveryState, Never>!
    var keyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never> {
        get { return underlyingKeyBackupState }
        set(value) { underlyingKeyBackupState = value }
    }
    var underlyingKeyBackupState: CurrentValuePublisher<SecureBackupKeyBackupState, Never>!

    //MARK: - enable

    private let enableCallsCountLock = NSLock()
    private var enableUnderlyingCallsCount = 0
    var enableCallsCount: Int {
        get { enableCallsCountLock.withLock { enableUnderlyingCallsCount } }
        set { enableCallsCountLock.withLock { enableUnderlyingCallsCount = newValue } }
    }
    var enableCalled: Bool {
        return enableCallsCount > 0
    }

    private let enableReturnValueLock = NSLock()
    private var enableUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var enableReturnValue: Result<Void, SecureBackupControllerError>! {
        get { enableReturnValueLock.withLock { enableUnderlyingReturnValue } }
        set { enableReturnValueLock.withLock { enableUnderlyingReturnValue = newValue } }
    }
    var enableClosure: (() async -> Result<Void, SecureBackupControllerError>)?

    func enable() async -> Result<Void, SecureBackupControllerError> {
        enableCallsCountLock.withLock { enableUnderlyingCallsCount += 1 }
        if let enableClosure = enableClosure {
            return await enableClosure()
        } else {
            return enableReturnValue
        }
    }
    //MARK: - disable

    private let disableCallsCountLock = NSLock()
    private var disableUnderlyingCallsCount = 0
    var disableCallsCount: Int {
        get { disableCallsCountLock.withLock { disableUnderlyingCallsCount } }
        set { disableCallsCountLock.withLock { disableUnderlyingCallsCount = newValue } }
    }
    var disableCalled: Bool {
        return disableCallsCount > 0
    }

    private let disableReturnValueLock = NSLock()
    private var disableUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var disableReturnValue: Result<Void, SecureBackupControllerError>! {
        get { disableReturnValueLock.withLock { disableUnderlyingReturnValue } }
        set { disableReturnValueLock.withLock { disableUnderlyingReturnValue = newValue } }
    }
    var disableClosure: (() async -> Result<Void, SecureBackupControllerError>)?

    func disable() async -> Result<Void, SecureBackupControllerError> {
        disableCallsCountLock.withLock { disableUnderlyingCallsCount += 1 }
        if let disableClosure = disableClosure {
            return await disableClosure()
        } else {
            return disableReturnValue
        }
    }
    //MARK: - generateRecoveryKey

    private let generateRecoveryKeyWithPassphraseCallsCountLock = NSLock()
    private var generateRecoveryKeyWithPassphraseUnderlyingCallsCount = 0
    var generateRecoveryKeyWithPassphraseCallsCount: Int {
        get { generateRecoveryKeyWithPassphraseCallsCountLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingCallsCount } }
        set { generateRecoveryKeyWithPassphraseCallsCountLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingCallsCount = newValue } }
    }
    var generateRecoveryKeyWithPassphraseCalled: Bool {
        return generateRecoveryKeyWithPassphraseCallsCount > 0
    }
    private let generateRecoveryKeyWithPassphraseReceivedPassphraseLock = NSLock()
    private var generateRecoveryKeyWithPassphraseUnderlyingReceivedPassphrase: String?
    var generateRecoveryKeyWithPassphraseReceivedPassphrase: String? {
        get { generateRecoveryKeyWithPassphraseReceivedPassphraseLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReceivedPassphrase } }
        set { generateRecoveryKeyWithPassphraseReceivedPassphraseLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReceivedPassphrase = newValue } }
    }
    private let generateRecoveryKeyWithPassphraseReceivedInvocationsLock = NSLock()
    private var generateRecoveryKeyWithPassphraseUnderlyingReceivedInvocations: [String?] = []
    var generateRecoveryKeyWithPassphraseReceivedInvocations: [String?] {
        get { generateRecoveryKeyWithPassphraseReceivedInvocationsLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReceivedInvocations } }
        set { generateRecoveryKeyWithPassphraseReceivedInvocationsLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReceivedInvocations = newValue } }
    }

    private let generateRecoveryKeyWithPassphraseReturnValueLock = NSLock()
    private var generateRecoveryKeyWithPassphraseUnderlyingReturnValue: Result<String, SecureBackupControllerError>!
    var generateRecoveryKeyWithPassphraseReturnValue: Result<String, SecureBackupControllerError>! {
        get { generateRecoveryKeyWithPassphraseReturnValueLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReturnValue } }
        set { generateRecoveryKeyWithPassphraseReturnValueLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReturnValue = newValue } }
    }
    var generateRecoveryKeyWithPassphraseClosure: ((String?) async -> Result<String, SecureBackupControllerError>)?

    func generateRecoveryKey(withPassphrase passphrase: String?) async -> Result<String, SecureBackupControllerError> {
        generateRecoveryKeyWithPassphraseCallsCountLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingCallsCount += 1 }
        generateRecoveryKeyWithPassphraseReceivedPassphrase = passphrase
        generateRecoveryKeyWithPassphraseReceivedInvocationsLock.withLock { generateRecoveryKeyWithPassphraseUnderlyingReceivedInvocations.append(passphrase) }
        if let generateRecoveryKeyWithPassphraseClosure = generateRecoveryKeyWithPassphraseClosure {
            return await generateRecoveryKeyWithPassphraseClosure(passphrase)
        } else {
            return generateRecoveryKeyWithPassphraseReturnValue
        }
    }
    //MARK: - confirmRecoveryKey

    private let confirmRecoveryKeyCallsCountLock = NSLock()
    private var confirmRecoveryKeyUnderlyingCallsCount = 0
    var confirmRecoveryKeyCallsCount: Int {
        get { confirmRecoveryKeyCallsCountLock.withLock { confirmRecoveryKeyUnderlyingCallsCount } }
        set { confirmRecoveryKeyCallsCountLock.withLock { confirmRecoveryKeyUnderlyingCallsCount = newValue } }
    }
    var confirmRecoveryKeyCalled: Bool {
        return confirmRecoveryKeyCallsCount > 0
    }
    private let confirmRecoveryKeyReceivedKeyLock = NSLock()
    private var confirmRecoveryKeyUnderlyingReceivedKey: String?
    var confirmRecoveryKeyReceivedKey: String? {
        get { confirmRecoveryKeyReceivedKeyLock.withLock { confirmRecoveryKeyUnderlyingReceivedKey } }
        set { confirmRecoveryKeyReceivedKeyLock.withLock { confirmRecoveryKeyUnderlyingReceivedKey = newValue } }
    }
    private let confirmRecoveryKeyReceivedInvocationsLock = NSLock()
    private var confirmRecoveryKeyUnderlyingReceivedInvocations: [String] = []
    var confirmRecoveryKeyReceivedInvocations: [String] {
        get { confirmRecoveryKeyReceivedInvocationsLock.withLock { confirmRecoveryKeyUnderlyingReceivedInvocations } }
        set { confirmRecoveryKeyReceivedInvocationsLock.withLock { confirmRecoveryKeyUnderlyingReceivedInvocations = newValue } }
    }

    private let confirmRecoveryKeyReturnValueLock = NSLock()
    private var confirmRecoveryKeyUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var confirmRecoveryKeyReturnValue: Result<Void, SecureBackupControllerError>! {
        get { confirmRecoveryKeyReturnValueLock.withLock { confirmRecoveryKeyUnderlyingReturnValue } }
        set { confirmRecoveryKeyReturnValueLock.withLock { confirmRecoveryKeyUnderlyingReturnValue = newValue } }
    }
    var confirmRecoveryKeyClosure: ((String) async -> Result<Void, SecureBackupControllerError>)?

    func confirmRecoveryKey(_ key: String) async -> Result<Void, SecureBackupControllerError> {
        confirmRecoveryKeyCallsCountLock.withLock { confirmRecoveryKeyUnderlyingCallsCount += 1 }
        confirmRecoveryKeyReceivedKey = key
        confirmRecoveryKeyReceivedInvocationsLock.withLock { confirmRecoveryKeyUnderlyingReceivedInvocations.append(key) }
        if let confirmRecoveryKeyClosure = confirmRecoveryKeyClosure {
            return await confirmRecoveryKeyClosure(key)
        } else {
            return confirmRecoveryKeyReturnValue
        }
    }
    //MARK: - waitForKeyBackupUpload

    private let waitForKeyBackupUploadUploadStateSubjectCallsCountLock = NSLock()
    private var waitForKeyBackupUploadUploadStateSubjectUnderlyingCallsCount = 0
    var waitForKeyBackupUploadUploadStateSubjectCallsCount: Int {
        get { waitForKeyBackupUploadUploadStateSubjectCallsCountLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingCallsCount } }
        set { waitForKeyBackupUploadUploadStateSubjectCallsCountLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingCallsCount = newValue } }
    }
    var waitForKeyBackupUploadUploadStateSubjectCalled: Bool {
        return waitForKeyBackupUploadUploadStateSubjectCallsCount > 0
    }
    private let waitForKeyBackupUploadUploadStateSubjectReceivedUploadStateSubjectLock = NSLock()
    private var waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedUploadStateSubject: CurrentValueSubject<SecureBackupSteadyState, Never>?
    var waitForKeyBackupUploadUploadStateSubjectReceivedUploadStateSubject: CurrentValueSubject<SecureBackupSteadyState, Never>? {
        get { waitForKeyBackupUploadUploadStateSubjectReceivedUploadStateSubjectLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedUploadStateSubject } }
        set { waitForKeyBackupUploadUploadStateSubjectReceivedUploadStateSubjectLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedUploadStateSubject = newValue } }
    }
    private let waitForKeyBackupUploadUploadStateSubjectReceivedInvocationsLock = NSLock()
    private var waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedInvocations: [CurrentValueSubject<SecureBackupSteadyState, Never>] = []
    var waitForKeyBackupUploadUploadStateSubjectReceivedInvocations: [CurrentValueSubject<SecureBackupSteadyState, Never>] {
        get { waitForKeyBackupUploadUploadStateSubjectReceivedInvocationsLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedInvocations } }
        set { waitForKeyBackupUploadUploadStateSubjectReceivedInvocationsLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedInvocations = newValue } }
    }

    private let waitForKeyBackupUploadUploadStateSubjectReturnValueLock = NSLock()
    private var waitForKeyBackupUploadUploadStateSubjectUnderlyingReturnValue: Result<Void, SecureBackupControllerError>!
    var waitForKeyBackupUploadUploadStateSubjectReturnValue: Result<Void, SecureBackupControllerError>! {
        get { waitForKeyBackupUploadUploadStateSubjectReturnValueLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReturnValue } }
        set { waitForKeyBackupUploadUploadStateSubjectReturnValueLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReturnValue = newValue } }
    }
    var waitForKeyBackupUploadUploadStateSubjectClosure: ((CurrentValueSubject<SecureBackupSteadyState, Never>) async -> Result<Void, SecureBackupControllerError>)?

    func waitForKeyBackupUpload(uploadStateSubject: CurrentValueSubject<SecureBackupSteadyState, Never>) async -> Result<Void, SecureBackupControllerError> {
        waitForKeyBackupUploadUploadStateSubjectCallsCountLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingCallsCount += 1 }
        waitForKeyBackupUploadUploadStateSubjectReceivedUploadStateSubject = uploadStateSubject
        waitForKeyBackupUploadUploadStateSubjectReceivedInvocationsLock.withLock { waitForKeyBackupUploadUploadStateSubjectUnderlyingReceivedInvocations.append(uploadStateSubject) }
        if let waitForKeyBackupUploadUploadStateSubjectClosure = waitForKeyBackupUploadUploadStateSubjectClosure {
            return await waitForKeyBackupUploadUploadStateSubjectClosure(uploadStateSubject)
        } else {
            return waitForKeyBackupUploadUploadStateSubjectReturnValue
        }
    }
}
class SessionVerificationControllerProxyMock: SessionVerificationControllerProxyProtocol, @unchecked Sendable {
    var actions: PassthroughSubject<SessionVerificationControllerProxyAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: PassthroughSubject<SessionVerificationControllerProxyAction, Never>!

    //MARK: - acknowledgeVerificationRequest

    private let acknowledgeVerificationRequestDetailsCallsCountLock = NSLock()
    private var acknowledgeVerificationRequestDetailsUnderlyingCallsCount = 0
    var acknowledgeVerificationRequestDetailsCallsCount: Int {
        get { acknowledgeVerificationRequestDetailsCallsCountLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingCallsCount } }
        set { acknowledgeVerificationRequestDetailsCallsCountLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingCallsCount = newValue } }
    }
    var acknowledgeVerificationRequestDetailsCalled: Bool {
        return acknowledgeVerificationRequestDetailsCallsCount > 0
    }
    private let acknowledgeVerificationRequestDetailsReceivedDetailsLock = NSLock()
    private var acknowledgeVerificationRequestDetailsUnderlyingReceivedDetails: SessionVerificationRequestDetails?
    var acknowledgeVerificationRequestDetailsReceivedDetails: SessionVerificationRequestDetails? {
        get { acknowledgeVerificationRequestDetailsReceivedDetailsLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReceivedDetails } }
        set { acknowledgeVerificationRequestDetailsReceivedDetailsLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReceivedDetails = newValue } }
    }
    private let acknowledgeVerificationRequestDetailsReceivedInvocationsLock = NSLock()
    private var acknowledgeVerificationRequestDetailsUnderlyingReceivedInvocations: [SessionVerificationRequestDetails] = []
    var acknowledgeVerificationRequestDetailsReceivedInvocations: [SessionVerificationRequestDetails] {
        get { acknowledgeVerificationRequestDetailsReceivedInvocationsLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReceivedInvocations } }
        set { acknowledgeVerificationRequestDetailsReceivedInvocationsLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReceivedInvocations = newValue } }
    }

    private let acknowledgeVerificationRequestDetailsReturnValueLock = NSLock()
    private var acknowledgeVerificationRequestDetailsUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var acknowledgeVerificationRequestDetailsReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { acknowledgeVerificationRequestDetailsReturnValueLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReturnValue } }
        set { acknowledgeVerificationRequestDetailsReturnValueLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReturnValue = newValue } }
    }
    var acknowledgeVerificationRequestDetailsClosure: ((SessionVerificationRequestDetails) async -> Result<Void, SessionVerificationControllerProxyError>)?

    func acknowledgeVerificationRequest(details: SessionVerificationRequestDetails) async -> Result<Void, SessionVerificationControllerProxyError> {
        acknowledgeVerificationRequestDetailsCallsCountLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingCallsCount += 1 }
        acknowledgeVerificationRequestDetailsReceivedDetails = details
        acknowledgeVerificationRequestDetailsReceivedInvocationsLock.withLock { acknowledgeVerificationRequestDetailsUnderlyingReceivedInvocations.append(details) }
        if let acknowledgeVerificationRequestDetailsClosure = acknowledgeVerificationRequestDetailsClosure {
            return await acknowledgeVerificationRequestDetailsClosure(details)
        } else {
            return acknowledgeVerificationRequestDetailsReturnValue
        }
    }
    //MARK: - acceptVerificationRequest

    private let acceptVerificationRequestCallsCountLock = NSLock()
    private var acceptVerificationRequestUnderlyingCallsCount = 0
    var acceptVerificationRequestCallsCount: Int {
        get { acceptVerificationRequestCallsCountLock.withLock { acceptVerificationRequestUnderlyingCallsCount } }
        set { acceptVerificationRequestCallsCountLock.withLock { acceptVerificationRequestUnderlyingCallsCount = newValue } }
    }
    var acceptVerificationRequestCalled: Bool {
        return acceptVerificationRequestCallsCount > 0
    }

    private let acceptVerificationRequestReturnValueLock = NSLock()
    private var acceptVerificationRequestUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var acceptVerificationRequestReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { acceptVerificationRequestReturnValueLock.withLock { acceptVerificationRequestUnderlyingReturnValue } }
        set { acceptVerificationRequestReturnValueLock.withLock { acceptVerificationRequestUnderlyingReturnValue = newValue } }
    }
    var acceptVerificationRequestClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func acceptVerificationRequest() async -> Result<Void, SessionVerificationControllerProxyError> {
        acceptVerificationRequestCallsCountLock.withLock { acceptVerificationRequestUnderlyingCallsCount += 1 }
        if let acceptVerificationRequestClosure = acceptVerificationRequestClosure {
            return await acceptVerificationRequestClosure()
        } else {
            return acceptVerificationRequestReturnValue
        }
    }
    //MARK: - requestDeviceVerification

    private let requestDeviceVerificationCallsCountLock = NSLock()
    private var requestDeviceVerificationUnderlyingCallsCount = 0
    var requestDeviceVerificationCallsCount: Int {
        get { requestDeviceVerificationCallsCountLock.withLock { requestDeviceVerificationUnderlyingCallsCount } }
        set { requestDeviceVerificationCallsCountLock.withLock { requestDeviceVerificationUnderlyingCallsCount = newValue } }
    }
    var requestDeviceVerificationCalled: Bool {
        return requestDeviceVerificationCallsCount > 0
    }

    private let requestDeviceVerificationReturnValueLock = NSLock()
    private var requestDeviceVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var requestDeviceVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { requestDeviceVerificationReturnValueLock.withLock { requestDeviceVerificationUnderlyingReturnValue } }
        set { requestDeviceVerificationReturnValueLock.withLock { requestDeviceVerificationUnderlyingReturnValue = newValue } }
    }
    var requestDeviceVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func requestDeviceVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        requestDeviceVerificationCallsCountLock.withLock { requestDeviceVerificationUnderlyingCallsCount += 1 }
        if let requestDeviceVerificationClosure = requestDeviceVerificationClosure {
            return await requestDeviceVerificationClosure()
        } else {
            return requestDeviceVerificationReturnValue
        }
    }
    //MARK: - requestUserVerification

    private let requestUserVerificationCallsCountLock = NSLock()
    private var requestUserVerificationUnderlyingCallsCount = 0
    var requestUserVerificationCallsCount: Int {
        get { requestUserVerificationCallsCountLock.withLock { requestUserVerificationUnderlyingCallsCount } }
        set { requestUserVerificationCallsCountLock.withLock { requestUserVerificationUnderlyingCallsCount = newValue } }
    }
    var requestUserVerificationCalled: Bool {
        return requestUserVerificationCallsCount > 0
    }
    private let requestUserVerificationReceivedUserIDLock = NSLock()
    private var requestUserVerificationUnderlyingReceivedUserID: String?
    var requestUserVerificationReceivedUserID: String? {
        get { requestUserVerificationReceivedUserIDLock.withLock { requestUserVerificationUnderlyingReceivedUserID } }
        set { requestUserVerificationReceivedUserIDLock.withLock { requestUserVerificationUnderlyingReceivedUserID = newValue } }
    }
    private let requestUserVerificationReceivedInvocationsLock = NSLock()
    private var requestUserVerificationUnderlyingReceivedInvocations: [String] = []
    var requestUserVerificationReceivedInvocations: [String] {
        get { requestUserVerificationReceivedInvocationsLock.withLock { requestUserVerificationUnderlyingReceivedInvocations } }
        set { requestUserVerificationReceivedInvocationsLock.withLock { requestUserVerificationUnderlyingReceivedInvocations = newValue } }
    }

    private let requestUserVerificationReturnValueLock = NSLock()
    private var requestUserVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var requestUserVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { requestUserVerificationReturnValueLock.withLock { requestUserVerificationUnderlyingReturnValue } }
        set { requestUserVerificationReturnValueLock.withLock { requestUserVerificationUnderlyingReturnValue = newValue } }
    }
    var requestUserVerificationClosure: ((String) async -> Result<Void, SessionVerificationControllerProxyError>)?

    func requestUserVerification(_ userID: String) async -> Result<Void, SessionVerificationControllerProxyError> {
        requestUserVerificationCallsCountLock.withLock { requestUserVerificationUnderlyingCallsCount += 1 }
        requestUserVerificationReceivedUserID = userID
        requestUserVerificationReceivedInvocationsLock.withLock { requestUserVerificationUnderlyingReceivedInvocations.append(userID) }
        if let requestUserVerificationClosure = requestUserVerificationClosure {
            return await requestUserVerificationClosure(userID)
        } else {
            return requestUserVerificationReturnValue
        }
    }
    //MARK: - startSasVerification

    private let startSasVerificationCallsCountLock = NSLock()
    private var startSasVerificationUnderlyingCallsCount = 0
    var startSasVerificationCallsCount: Int {
        get { startSasVerificationCallsCountLock.withLock { startSasVerificationUnderlyingCallsCount } }
        set { startSasVerificationCallsCountLock.withLock { startSasVerificationUnderlyingCallsCount = newValue } }
    }
    var startSasVerificationCalled: Bool {
        return startSasVerificationCallsCount > 0
    }

    private let startSasVerificationReturnValueLock = NSLock()
    private var startSasVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var startSasVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { startSasVerificationReturnValueLock.withLock { startSasVerificationUnderlyingReturnValue } }
        set { startSasVerificationReturnValueLock.withLock { startSasVerificationUnderlyingReturnValue = newValue } }
    }
    var startSasVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        startSasVerificationCallsCountLock.withLock { startSasVerificationUnderlyingCallsCount += 1 }
        if let startSasVerificationClosure = startSasVerificationClosure {
            return await startSasVerificationClosure()
        } else {
            return startSasVerificationReturnValue
        }
    }
    //MARK: - approveVerification

    private let approveVerificationCallsCountLock = NSLock()
    private var approveVerificationUnderlyingCallsCount = 0
    var approveVerificationCallsCount: Int {
        get { approveVerificationCallsCountLock.withLock { approveVerificationUnderlyingCallsCount } }
        set { approveVerificationCallsCountLock.withLock { approveVerificationUnderlyingCallsCount = newValue } }
    }
    var approveVerificationCalled: Bool {
        return approveVerificationCallsCount > 0
    }

    private let approveVerificationReturnValueLock = NSLock()
    private var approveVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var approveVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { approveVerificationReturnValueLock.withLock { approveVerificationUnderlyingReturnValue } }
        set { approveVerificationReturnValueLock.withLock { approveVerificationUnderlyingReturnValue = newValue } }
    }
    var approveVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        approveVerificationCallsCountLock.withLock { approveVerificationUnderlyingCallsCount += 1 }
        if let approveVerificationClosure = approveVerificationClosure {
            return await approveVerificationClosure()
        } else {
            return approveVerificationReturnValue
        }
    }
    //MARK: - declineVerification

    private let declineVerificationCallsCountLock = NSLock()
    private var declineVerificationUnderlyingCallsCount = 0
    var declineVerificationCallsCount: Int {
        get { declineVerificationCallsCountLock.withLock { declineVerificationUnderlyingCallsCount } }
        set { declineVerificationCallsCountLock.withLock { declineVerificationUnderlyingCallsCount = newValue } }
    }
    var declineVerificationCalled: Bool {
        return declineVerificationCallsCount > 0
    }

    private let declineVerificationReturnValueLock = NSLock()
    private var declineVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var declineVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { declineVerificationReturnValueLock.withLock { declineVerificationUnderlyingReturnValue } }
        set { declineVerificationReturnValueLock.withLock { declineVerificationUnderlyingReturnValue = newValue } }
    }
    var declineVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        declineVerificationCallsCountLock.withLock { declineVerificationUnderlyingCallsCount += 1 }
        if let declineVerificationClosure = declineVerificationClosure {
            return await declineVerificationClosure()
        } else {
            return declineVerificationReturnValue
        }
    }
    //MARK: - cancelVerification

    private let cancelVerificationCallsCountLock = NSLock()
    private var cancelVerificationUnderlyingCallsCount = 0
    var cancelVerificationCallsCount: Int {
        get { cancelVerificationCallsCountLock.withLock { cancelVerificationUnderlyingCallsCount } }
        set { cancelVerificationCallsCountLock.withLock { cancelVerificationUnderlyingCallsCount = newValue } }
    }
    var cancelVerificationCalled: Bool {
        return cancelVerificationCallsCount > 0
    }

    private let cancelVerificationReturnValueLock = NSLock()
    private var cancelVerificationUnderlyingReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var cancelVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>! {
        get { cancelVerificationReturnValueLock.withLock { cancelVerificationUnderlyingReturnValue } }
        set { cancelVerificationReturnValueLock.withLock { cancelVerificationUnderlyingReturnValue = newValue } }
    }
    var cancelVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        cancelVerificationCallsCountLock.withLock { cancelVerificationUnderlyingCallsCount += 1 }
        if let cancelVerificationClosure = cancelVerificationClosure {
            return await cancelVerificationClosure()
        } else {
            return cancelVerificationReturnValue
        }
    }
}
class SpaceRoomListProxyMock: SpaceRoomListProxyProtocol, @unchecked Sendable {
    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var spaceServiceRoomPublisher: CurrentValuePublisher<SpaceServiceRoom, Never> {
        get { return underlyingSpaceServiceRoomPublisher }
        set(value) { underlyingSpaceServiceRoomPublisher = value }
    }
    var underlyingSpaceServiceRoomPublisher: CurrentValuePublisher<SpaceServiceRoom, Never>!
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never> {
        get { return underlyingSpaceRoomsPublisher }
        set(value) { underlyingSpaceRoomsPublisher = value }
    }
    var underlyingSpaceRoomsPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never>!
    var paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never> {
        get { return underlyingPaginationStatePublisher }
        set(value) { underlyingPaginationStatePublisher = value }
    }
    var underlyingPaginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never>!

    //MARK: - paginate

    private let paginateCallsCountLock = NSLock()
    private var paginateUnderlyingCallsCount = 0
    var paginateCallsCount: Int {
        get { paginateCallsCountLock.withLock { paginateUnderlyingCallsCount } }
        set { paginateCallsCountLock.withLock { paginateUnderlyingCallsCount = newValue } }
    }
    var paginateCalled: Bool {
        return paginateCallsCount > 0
    }
    var paginateClosure: (() async -> Void)?

    func paginate() async {
        paginateCallsCountLock.withLock { paginateUnderlyingCallsCount += 1 }
        await paginateClosure?()
    }
    //MARK: - reset

    private let resetCallsCountLock = NSLock()
    private var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get { resetCallsCountLock.withLock { resetUnderlyingCallsCount } }
        set { resetCallsCountLock.withLock { resetUnderlyingCallsCount = newValue } }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() async -> Void)?

    func reset() async {
        resetCallsCountLock.withLock { resetUnderlyingCallsCount += 1 }
        await resetClosure?()
    }
}
class SpaceServiceProxyMock: SpaceServiceProxyProtocol, @unchecked Sendable {
    var topLevelSpacesPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never> {
        get { return underlyingTopLevelSpacesPublisher }
        set(value) { underlyingTopLevelSpacesPublisher = value }
    }
    var underlyingTopLevelSpacesPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never>!
    var spaceFilterPublisher: CurrentValuePublisher<[SpaceServiceFilter], Never> {
        get { return underlyingSpaceFilterPublisher }
        set(value) { underlyingSpaceFilterPublisher = value }
    }
    var underlyingSpaceFilterPublisher: CurrentValuePublisher<[SpaceServiceFilter], Never>!

    //MARK: - spaceRoomList

    private let spaceRoomListSpaceIDCallsCountLock = NSLock()
    private var spaceRoomListSpaceIDUnderlyingCallsCount = 0
    var spaceRoomListSpaceIDCallsCount: Int {
        get { spaceRoomListSpaceIDCallsCountLock.withLock { spaceRoomListSpaceIDUnderlyingCallsCount } }
        set { spaceRoomListSpaceIDCallsCountLock.withLock { spaceRoomListSpaceIDUnderlyingCallsCount = newValue } }
    }
    var spaceRoomListSpaceIDCalled: Bool {
        return spaceRoomListSpaceIDCallsCount > 0
    }
    private let spaceRoomListSpaceIDReceivedSpaceIDLock = NSLock()
    private var spaceRoomListSpaceIDUnderlyingReceivedSpaceID: String?
    var spaceRoomListSpaceIDReceivedSpaceID: String? {
        get { spaceRoomListSpaceIDReceivedSpaceIDLock.withLock { spaceRoomListSpaceIDUnderlyingReceivedSpaceID } }
        set { spaceRoomListSpaceIDReceivedSpaceIDLock.withLock { spaceRoomListSpaceIDUnderlyingReceivedSpaceID = newValue } }
    }
    private let spaceRoomListSpaceIDReceivedInvocationsLock = NSLock()
    private var spaceRoomListSpaceIDUnderlyingReceivedInvocations: [String] = []
    var spaceRoomListSpaceIDReceivedInvocations: [String] {
        get { spaceRoomListSpaceIDReceivedInvocationsLock.withLock { spaceRoomListSpaceIDUnderlyingReceivedInvocations } }
        set { spaceRoomListSpaceIDReceivedInvocationsLock.withLock { spaceRoomListSpaceIDUnderlyingReceivedInvocations = newValue } }
    }

    private let spaceRoomListSpaceIDReturnValueLock = NSLock()
    private var spaceRoomListSpaceIDUnderlyingReturnValue: Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>!
    var spaceRoomListSpaceIDReturnValue: Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>! {
        get { spaceRoomListSpaceIDReturnValueLock.withLock { spaceRoomListSpaceIDUnderlyingReturnValue } }
        set { spaceRoomListSpaceIDReturnValueLock.withLock { spaceRoomListSpaceIDUnderlyingReturnValue = newValue } }
    }
    var spaceRoomListSpaceIDClosure: ((String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>)?

    func spaceRoomList(spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError> {
        spaceRoomListSpaceIDCallsCountLock.withLock { spaceRoomListSpaceIDUnderlyingCallsCount += 1 }
        spaceRoomListSpaceIDReceivedSpaceID = spaceID
        spaceRoomListSpaceIDReceivedInvocationsLock.withLock { spaceRoomListSpaceIDUnderlyingReceivedInvocations.append(spaceID) }
        if let spaceRoomListSpaceIDClosure = spaceRoomListSpaceIDClosure {
            return await spaceRoomListSpaceIDClosure(spaceID)
        } else {
            return spaceRoomListSpaceIDReturnValue
        }
    }
    //MARK: - spaceForIdentifier

    private let spaceForIdentifierSpaceIDCallsCountLock = NSLock()
    private var spaceForIdentifierSpaceIDUnderlyingCallsCount = 0
    var spaceForIdentifierSpaceIDCallsCount: Int {
        get { spaceForIdentifierSpaceIDCallsCountLock.withLock { spaceForIdentifierSpaceIDUnderlyingCallsCount } }
        set { spaceForIdentifierSpaceIDCallsCountLock.withLock { spaceForIdentifierSpaceIDUnderlyingCallsCount = newValue } }
    }
    var spaceForIdentifierSpaceIDCalled: Bool {
        return spaceForIdentifierSpaceIDCallsCount > 0
    }
    private let spaceForIdentifierSpaceIDReceivedSpaceIDLock = NSLock()
    private var spaceForIdentifierSpaceIDUnderlyingReceivedSpaceID: String?
    var spaceForIdentifierSpaceIDReceivedSpaceID: String? {
        get { spaceForIdentifierSpaceIDReceivedSpaceIDLock.withLock { spaceForIdentifierSpaceIDUnderlyingReceivedSpaceID } }
        set { spaceForIdentifierSpaceIDReceivedSpaceIDLock.withLock { spaceForIdentifierSpaceIDUnderlyingReceivedSpaceID = newValue } }
    }
    private let spaceForIdentifierSpaceIDReceivedInvocationsLock = NSLock()
    private var spaceForIdentifierSpaceIDUnderlyingReceivedInvocations: [String] = []
    var spaceForIdentifierSpaceIDReceivedInvocations: [String] {
        get { spaceForIdentifierSpaceIDReceivedInvocationsLock.withLock { spaceForIdentifierSpaceIDUnderlyingReceivedInvocations } }
        set { spaceForIdentifierSpaceIDReceivedInvocationsLock.withLock { spaceForIdentifierSpaceIDUnderlyingReceivedInvocations = newValue } }
    }

    private let spaceForIdentifierSpaceIDReturnValueLock = NSLock()
    private var spaceForIdentifierSpaceIDUnderlyingReturnValue: Result<SpaceServiceRoom?, SpaceServiceProxyError>!
    var spaceForIdentifierSpaceIDReturnValue: Result<SpaceServiceRoom?, SpaceServiceProxyError>! {
        get { spaceForIdentifierSpaceIDReturnValueLock.withLock { spaceForIdentifierSpaceIDUnderlyingReturnValue } }
        set { spaceForIdentifierSpaceIDReturnValueLock.withLock { spaceForIdentifierSpaceIDUnderlyingReturnValue = newValue } }
    }
    var spaceForIdentifierSpaceIDClosure: ((String) async -> Result<SpaceServiceRoom?, SpaceServiceProxyError>)?

    func spaceForIdentifier(spaceID: String) async -> Result<SpaceServiceRoom?, SpaceServiceProxyError> {
        spaceForIdentifierSpaceIDCallsCountLock.withLock { spaceForIdentifierSpaceIDUnderlyingCallsCount += 1 }
        spaceForIdentifierSpaceIDReceivedSpaceID = spaceID
        spaceForIdentifierSpaceIDReceivedInvocationsLock.withLock { spaceForIdentifierSpaceIDUnderlyingReceivedInvocations.append(spaceID) }
        if let spaceForIdentifierSpaceIDClosure = spaceForIdentifierSpaceIDClosure {
            return await spaceForIdentifierSpaceIDClosure(spaceID)
        } else {
            return spaceForIdentifierSpaceIDReturnValue
        }
    }
    //MARK: - leaveSpace

    private let leaveSpaceSpaceIDCallsCountLock = NSLock()
    private var leaveSpaceSpaceIDUnderlyingCallsCount = 0
    var leaveSpaceSpaceIDCallsCount: Int {
        get { leaveSpaceSpaceIDCallsCountLock.withLock { leaveSpaceSpaceIDUnderlyingCallsCount } }
        set { leaveSpaceSpaceIDCallsCountLock.withLock { leaveSpaceSpaceIDUnderlyingCallsCount = newValue } }
    }
    var leaveSpaceSpaceIDCalled: Bool {
        return leaveSpaceSpaceIDCallsCount > 0
    }
    private let leaveSpaceSpaceIDReceivedSpaceIDLock = NSLock()
    private var leaveSpaceSpaceIDUnderlyingReceivedSpaceID: String?
    var leaveSpaceSpaceIDReceivedSpaceID: String? {
        get { leaveSpaceSpaceIDReceivedSpaceIDLock.withLock { leaveSpaceSpaceIDUnderlyingReceivedSpaceID } }
        set { leaveSpaceSpaceIDReceivedSpaceIDLock.withLock { leaveSpaceSpaceIDUnderlyingReceivedSpaceID = newValue } }
    }
    private let leaveSpaceSpaceIDReceivedInvocationsLock = NSLock()
    private var leaveSpaceSpaceIDUnderlyingReceivedInvocations: [String] = []
    var leaveSpaceSpaceIDReceivedInvocations: [String] {
        get { leaveSpaceSpaceIDReceivedInvocationsLock.withLock { leaveSpaceSpaceIDUnderlyingReceivedInvocations } }
        set { leaveSpaceSpaceIDReceivedInvocationsLock.withLock { leaveSpaceSpaceIDUnderlyingReceivedInvocations = newValue } }
    }

    private let leaveSpaceSpaceIDReturnValueLock = NSLock()
    private var leaveSpaceSpaceIDUnderlyingReturnValue: Result<LeaveSpaceHandleProxy, SpaceServiceProxyError>!
    var leaveSpaceSpaceIDReturnValue: Result<LeaveSpaceHandleProxy, SpaceServiceProxyError>! {
        get { leaveSpaceSpaceIDReturnValueLock.withLock { leaveSpaceSpaceIDUnderlyingReturnValue } }
        set { leaveSpaceSpaceIDReturnValueLock.withLock { leaveSpaceSpaceIDUnderlyingReturnValue = newValue } }
    }
    var leaveSpaceSpaceIDClosure: ((String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError>)?

    func leaveSpace(spaceID: String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError> {
        leaveSpaceSpaceIDCallsCountLock.withLock { leaveSpaceSpaceIDUnderlyingCallsCount += 1 }
        leaveSpaceSpaceIDReceivedSpaceID = spaceID
        leaveSpaceSpaceIDReceivedInvocationsLock.withLock { leaveSpaceSpaceIDUnderlyingReceivedInvocations.append(spaceID) }
        if let leaveSpaceSpaceIDClosure = leaveSpaceSpaceIDClosure {
            return await leaveSpaceSpaceIDClosure(spaceID)
        } else {
            return leaveSpaceSpaceIDReturnValue
        }
    }
    //MARK: - joinedParents

    private let joinedParentsChildIDCallsCountLock = NSLock()
    private var joinedParentsChildIDUnderlyingCallsCount = 0
    var joinedParentsChildIDCallsCount: Int {
        get { joinedParentsChildIDCallsCountLock.withLock { joinedParentsChildIDUnderlyingCallsCount } }
        set { joinedParentsChildIDCallsCountLock.withLock { joinedParentsChildIDUnderlyingCallsCount = newValue } }
    }
    var joinedParentsChildIDCalled: Bool {
        return joinedParentsChildIDCallsCount > 0
    }
    private let joinedParentsChildIDReceivedChildIDLock = NSLock()
    private var joinedParentsChildIDUnderlyingReceivedChildID: String?
    var joinedParentsChildIDReceivedChildID: String? {
        get { joinedParentsChildIDReceivedChildIDLock.withLock { joinedParentsChildIDUnderlyingReceivedChildID } }
        set { joinedParentsChildIDReceivedChildIDLock.withLock { joinedParentsChildIDUnderlyingReceivedChildID = newValue } }
    }
    private let joinedParentsChildIDReceivedInvocationsLock = NSLock()
    private var joinedParentsChildIDUnderlyingReceivedInvocations: [String] = []
    var joinedParentsChildIDReceivedInvocations: [String] {
        get { joinedParentsChildIDReceivedInvocationsLock.withLock { joinedParentsChildIDUnderlyingReceivedInvocations } }
        set { joinedParentsChildIDReceivedInvocationsLock.withLock { joinedParentsChildIDUnderlyingReceivedInvocations = newValue } }
    }

    private let joinedParentsChildIDReturnValueLock = NSLock()
    private var joinedParentsChildIDUnderlyingReturnValue: Result<[SpaceServiceRoom], SpaceServiceProxyError>!
    var joinedParentsChildIDReturnValue: Result<[SpaceServiceRoom], SpaceServiceProxyError>! {
        get { joinedParentsChildIDReturnValueLock.withLock { joinedParentsChildIDUnderlyingReturnValue } }
        set { joinedParentsChildIDReturnValueLock.withLock { joinedParentsChildIDUnderlyingReturnValue = newValue } }
    }
    var joinedParentsChildIDClosure: ((String) async -> Result<[SpaceServiceRoom], SpaceServiceProxyError>)?

    func joinedParents(childID: String) async -> Result<[SpaceServiceRoom], SpaceServiceProxyError> {
        joinedParentsChildIDCallsCountLock.withLock { joinedParentsChildIDUnderlyingCallsCount += 1 }
        joinedParentsChildIDReceivedChildID = childID
        joinedParentsChildIDReceivedInvocationsLock.withLock { joinedParentsChildIDUnderlyingReceivedInvocations.append(childID) }
        if let joinedParentsChildIDClosure = joinedParentsChildIDClosure {
            return await joinedParentsChildIDClosure(childID)
        } else {
            return joinedParentsChildIDReturnValue
        }
    }
    //MARK: - editableSpaces

    private let editableSpacesCallsCountLock = NSLock()
    private var editableSpacesUnderlyingCallsCount = 0
    var editableSpacesCallsCount: Int {
        get { editableSpacesCallsCountLock.withLock { editableSpacesUnderlyingCallsCount } }
        set { editableSpacesCallsCountLock.withLock { editableSpacesUnderlyingCallsCount = newValue } }
    }
    var editableSpacesCalled: Bool {
        return editableSpacesCallsCount > 0
    }

    private let editableSpacesReturnValueLock = NSLock()
    private var editableSpacesUnderlyingReturnValue: [SpaceServiceRoom]!
    var editableSpacesReturnValue: [SpaceServiceRoom]! {
        get { editableSpacesReturnValueLock.withLock { editableSpacesUnderlyingReturnValue } }
        set { editableSpacesReturnValueLock.withLock { editableSpacesUnderlyingReturnValue = newValue } }
    }
    var editableSpacesClosure: (() async -> [SpaceServiceRoom])?

    func editableSpaces() async -> [SpaceServiceRoom] {
        editableSpacesCallsCountLock.withLock { editableSpacesUnderlyingCallsCount += 1 }
        if let editableSpacesClosure = editableSpacesClosure {
            return await editableSpacesClosure()
        } else {
            return editableSpacesReturnValue
        }
    }
    //MARK: - addChild

    private let addChildToCallsCountLock = NSLock()
    private var addChildToUnderlyingCallsCount = 0
    var addChildToCallsCount: Int {
        get { addChildToCallsCountLock.withLock { addChildToUnderlyingCallsCount } }
        set { addChildToCallsCountLock.withLock { addChildToUnderlyingCallsCount = newValue } }
    }
    var addChildToCalled: Bool {
        return addChildToCallsCount > 0
    }
    private let addChildToReceivedArgumentsLock = NSLock()
    private var addChildToUnderlyingReceivedArguments: (childID: String, spaceID: String)?
    var addChildToReceivedArguments: (childID: String, spaceID: String)? {
        get { addChildToReceivedArgumentsLock.withLock { addChildToUnderlyingReceivedArguments } }
        set { addChildToReceivedArgumentsLock.withLock { addChildToUnderlyingReceivedArguments = newValue } }
    }
    private let addChildToReceivedInvocationsLock = NSLock()
    private var addChildToUnderlyingReceivedInvocations: [(childID: String, spaceID: String)] = []
    var addChildToReceivedInvocations: [(childID: String, spaceID: String)] {
        get { addChildToReceivedInvocationsLock.withLock { addChildToUnderlyingReceivedInvocations } }
        set { addChildToReceivedInvocationsLock.withLock { addChildToUnderlyingReceivedInvocations = newValue } }
    }

    private let addChildToReturnValueLock = NSLock()
    private var addChildToUnderlyingReturnValue: Result<Void, SpaceServiceProxyError>!
    var addChildToReturnValue: Result<Void, SpaceServiceProxyError>! {
        get { addChildToReturnValueLock.withLock { addChildToUnderlyingReturnValue } }
        set { addChildToReturnValueLock.withLock { addChildToUnderlyingReturnValue = newValue } }
    }
    var addChildToClosure: ((String, String) async -> Result<Void, SpaceServiceProxyError>)?

    func addChild(_ childID: String, to spaceID: String) async -> Result<Void, SpaceServiceProxyError> {
        addChildToCallsCountLock.withLock { addChildToUnderlyingCallsCount += 1 }
        addChildToReceivedArguments = (childID: childID, spaceID: spaceID)
        addChildToReceivedInvocationsLock.withLock { addChildToUnderlyingReceivedInvocations.append((childID: childID, spaceID: spaceID)) }
        if let addChildToClosure = addChildToClosure {
            return await addChildToClosure(childID, spaceID)
        } else {
            return addChildToReturnValue
        }
    }
    //MARK: - removeChild

    private let removeChildFromCallsCountLock = NSLock()
    private var removeChildFromUnderlyingCallsCount = 0
    var removeChildFromCallsCount: Int {
        get { removeChildFromCallsCountLock.withLock { removeChildFromUnderlyingCallsCount } }
        set { removeChildFromCallsCountLock.withLock { removeChildFromUnderlyingCallsCount = newValue } }
    }
    var removeChildFromCalled: Bool {
        return removeChildFromCallsCount > 0
    }
    private let removeChildFromReceivedArgumentsLock = NSLock()
    private var removeChildFromUnderlyingReceivedArguments: (childID: String, spaceID: String)?
    var removeChildFromReceivedArguments: (childID: String, spaceID: String)? {
        get { removeChildFromReceivedArgumentsLock.withLock { removeChildFromUnderlyingReceivedArguments } }
        set { removeChildFromReceivedArgumentsLock.withLock { removeChildFromUnderlyingReceivedArguments = newValue } }
    }
    private let removeChildFromReceivedInvocationsLock = NSLock()
    private var removeChildFromUnderlyingReceivedInvocations: [(childID: String, spaceID: String)] = []
    var removeChildFromReceivedInvocations: [(childID: String, spaceID: String)] {
        get { removeChildFromReceivedInvocationsLock.withLock { removeChildFromUnderlyingReceivedInvocations } }
        set { removeChildFromReceivedInvocationsLock.withLock { removeChildFromUnderlyingReceivedInvocations = newValue } }
    }

    private let removeChildFromReturnValueLock = NSLock()
    private var removeChildFromUnderlyingReturnValue: Result<Void, SpaceServiceProxyError>!
    var removeChildFromReturnValue: Result<Void, SpaceServiceProxyError>! {
        get { removeChildFromReturnValueLock.withLock { removeChildFromUnderlyingReturnValue } }
        set { removeChildFromReturnValueLock.withLock { removeChildFromUnderlyingReturnValue = newValue } }
    }
    var removeChildFromClosure: ((String, String) async -> Result<Void, SpaceServiceProxyError>)?

    func removeChild(_ childID: String, from spaceID: String) async -> Result<Void, SpaceServiceProxyError> {
        removeChildFromCallsCountLock.withLock { removeChildFromUnderlyingCallsCount += 1 }
        removeChildFromReceivedArguments = (childID: childID, spaceID: spaceID)
        removeChildFromReceivedInvocationsLock.withLock { removeChildFromUnderlyingReceivedInvocations.append((childID: childID, spaceID: spaceID)) }
        if let removeChildFromClosure = removeChildFromClosure {
            return await removeChildFromClosure(childID, spaceID)
        } else {
            return removeChildFromReturnValue
        }
    }
}
class StaticRoomSummaryProviderMock: StaticRoomSummaryProviderProtocol, @unchecked Sendable {
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> {
        get { return underlyingStatePublisher }
        set(value) { underlyingStatePublisher = value }
    }
    var underlyingStatePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never>!
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> {
        get { return underlyingRoomListPublisher }
        set(value) { underlyingRoomListPublisher = value }
    }
    var underlyingRoomListPublisher: CurrentValuePublisher<[RoomSummary], Never>!

    //MARK: - setRoomList

    private let setRoomListCallsCountLock = NSLock()
    private var setRoomListUnderlyingCallsCount = 0
    var setRoomListCallsCount: Int {
        get { setRoomListCallsCountLock.withLock { setRoomListUnderlyingCallsCount } }
        set { setRoomListCallsCountLock.withLock { setRoomListUnderlyingCallsCount = newValue } }
    }
    var setRoomListCalled: Bool {
        return setRoomListCallsCount > 0
    }
    private let setRoomListReceivedRoomListLock = NSLock()
    private var setRoomListUnderlyingReceivedRoomList: RoomList?
    var setRoomListReceivedRoomList: RoomList? {
        get { setRoomListReceivedRoomListLock.withLock { setRoomListUnderlyingReceivedRoomList } }
        set { setRoomListReceivedRoomListLock.withLock { setRoomListUnderlyingReceivedRoomList = newValue } }
    }
    private let setRoomListReceivedInvocationsLock = NSLock()
    private var setRoomListUnderlyingReceivedInvocations: [RoomList] = []
    var setRoomListReceivedInvocations: [RoomList] {
        get { setRoomListReceivedInvocationsLock.withLock { setRoomListUnderlyingReceivedInvocations } }
        set { setRoomListReceivedInvocationsLock.withLock { setRoomListUnderlyingReceivedInvocations = newValue } }
    }
    var setRoomListClosure: ((RoomList) -> Void)?

    func setRoomList(_ roomList: RoomList) {
        setRoomListCallsCountLock.withLock { setRoomListUnderlyingCallsCount += 1 }
        setRoomListReceivedRoomList = roomList
        setRoomListReceivedInvocationsLock.withLock { setRoomListUnderlyingReceivedInvocations.append(roomList) }
        setRoomListClosure?(roomList)
    }
}
class TimelineControllerFactoryMock: TimelineControllerFactoryProtocol, @unchecked Sendable {

    //MARK: - buildTimelineController

    private let buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCountLock = NSLock()
    private var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingCallsCount = 0
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount: Int {
        get { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingCallsCount } }
        set { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingCallsCount = newValue } }
    }
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCalled: Bool {
        return buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount > 0
    }
    private let buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArgumentsLock = NSLock()
    private var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)?
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)? {
        get { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedArguments } }
        set { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedArguments = newValue } }
    }
    private let buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedInvocationsLock = NSLock()
    private var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] = []
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] {
        get { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations } }
        set { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations = newValue } }
    }

    private let buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValueLock = NSLock()
    private var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReturnValue: TimelineControllerProtocol!
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue: TimelineControllerProtocol! {
        get { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReturnValue } }
        set { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReturnValue = newValue } }
    }
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderClosure: ((JoinedRoomProxyProtocol, String?, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) -> TimelineControllerProtocol)?

    func buildTimelineController(roomProxy: JoinedRoomProxyProtocol, initialFocussedEventID: String?, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol) -> TimelineControllerProtocol {
        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingCallsCount += 1 }
        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments = (roomProxy: roomProxy, initialFocussedEventID: initialFocussedEventID, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)
        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations.append((roomProxy: roomProxy, initialFocussedEventID: initialFocussedEventID, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)) }
        if let buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderClosure = buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderClosure {
            return buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderClosure(roomProxy, initialFocussedEventID, timelineItemFactory, mediaProvider)
        } else {
            return buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue
        }
    }
    //MARK: - buildThreadTimelineController

    private let buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCallsCountLock = NSLock()
    private var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount = 0
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCallsCount: Int {
        get { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount } }
        set { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount = newValue } }
    }
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCalled: Bool {
        return buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCallsCount > 0
    }
    private let buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock = NSLock()
    private var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments: (threadRootEventID: String, initialFocussedEventID: String?, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)?
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedArguments: (threadRootEventID: String, initialFocussedEventID: String?, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)? {
        get { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments } }
        set { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments = newValue } }
    }
    private let buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock = NSLock()
    private var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations: [(threadRootEventID: String, initialFocussedEventID: String?, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] = []
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedInvocations: [(threadRootEventID: String, initialFocussedEventID: String?, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] {
        get { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations } }
        set { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations = newValue } }
    }

    private let buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReturnValueLock = NSLock()
    private var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue: Result<TimelineControllerProtocol, TimelineFactoryControllerError>!
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReturnValue: Result<TimelineControllerProtocol, TimelineFactoryControllerError>! {
        get { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue } }
        set { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue = newValue } }
    }
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure: ((String, String?, JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>)?

    func buildThreadTimelineController(threadRootEventID: String, initialFocussedEventID: String?, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount += 1 }
        buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedArguments = (threadRootEventID: threadRootEventID, initialFocussedEventID: initialFocussedEventID, roomProxy: roomProxy, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)
        buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations.append((threadRootEventID: threadRootEventID, initialFocussedEventID: initialFocussedEventID, roomProxy: roomProxy, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)) }
        if let buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure = buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure {
            return await buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure(threadRootEventID, initialFocussedEventID, roomProxy, timelineItemFactory, mediaProvider)
        } else {
            return buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderReturnValue
        }
    }
    //MARK: - buildPinnedEventsTimelineController

    private let buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCallsCountLock = NSLock()
    private var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount = 0
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCallsCount: Int {
        get { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount } }
        set { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount = newValue } }
    }
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCalled: Bool {
        return buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCallsCount > 0
    }
    private let buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock = NSLock()
    private var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)?
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedArguments: (roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)? {
        get { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments } }
        set { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments = newValue } }
    }
    private let buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock = NSLock()
    private var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] = []
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedInvocations: [(roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] {
        get { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations } }
        set { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations = newValue } }
    }

    private let buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReturnValueLock = NSLock()
    private var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue: Result<TimelineControllerProtocol, TimelineFactoryControllerError>!
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReturnValue: Result<TimelineControllerProtocol, TimelineFactoryControllerError>! {
        get { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue } }
        set { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue = newValue } }
    }
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderClosure: ((JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>)?

    func buildPinnedEventsTimelineController(roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount += 1 }
        buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedArguments = (roomProxy: roomProxy, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)
        buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations.append((roomProxy: roomProxy, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)) }
        if let buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderClosure = buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderClosure {
            return await buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderClosure(roomProxy, timelineItemFactory, mediaProvider)
        } else {
            return buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderReturnValue
        }
    }
    //MARK: - buildMessageFilteredTimelineController

    private let buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCallsCountLock = NSLock()
    private var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount = 0
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCallsCount: Int {
        get { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount } }
        set { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount = newValue } }
    }
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCalled: Bool {
        return buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCallsCount > 0
    }
    private let buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock = NSLock()
    private var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments: (focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)?
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedArguments: (focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)? {
        get { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments } }
        set { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedArgumentsLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedArguments = newValue } }
    }
    private let buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock = NSLock()
    private var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations: [(focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] = []
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedInvocations: [(focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol)] {
        get { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations } }
        set { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations = newValue } }
    }

    private let buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReturnValueLock = NSLock()
    private var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue: Result<TimelineControllerProtocol, TimelineFactoryControllerError>!
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReturnValue: Result<TimelineControllerProtocol, TimelineFactoryControllerError>! {
        get { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue } }
        set { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReturnValueLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReturnValue = newValue } }
    }
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderClosure: ((TimelineFocus, [TimelineAllowedMessageType], TimelineKind.MediaPresentation, JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>)?

    func buildMessageFilteredTimelineController(focus: TimelineFocus, allowedMessageTypes: [TimelineAllowedMessageType], presentation: TimelineKind.MediaPresentation, roomProxy: JoinedRoomProxyProtocol, timelineItemFactory: RoomTimelineItemFactoryProtocol, mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderCallsCountLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingCallsCount += 1 }
        buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedArguments = (focus: focus, allowedMessageTypes: allowedMessageTypes, presentation: presentation, roomProxy: roomProxy, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)
        buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReceivedInvocationsLock.withLock { buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderUnderlyingReceivedInvocations.append((focus: focus, allowedMessageTypes: allowedMessageTypes, presentation: presentation, roomProxy: roomProxy, timelineItemFactory: timelineItemFactory, mediaProvider: mediaProvider)) }
        if let buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderClosure = buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderClosure {
            return await buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderClosure(focus, allowedMessageTypes, presentation, roomProxy, timelineItemFactory, mediaProvider)
        } else {
            return buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderReturnValue
        }
    }
}
class TimelineControllerMock: TimelineControllerProtocol, @unchecked Sendable {
    var roomID: String {
        get { return underlyingRoomID }
        set(value) { underlyingRoomID = value }
    }
    var underlyingRoomID: String!
    var timelineKind: TimelineKind {
        get { return underlyingTimelineKind }
        set(value) { underlyingTimelineKind = value }
    }
    var underlyingTimelineKind: TimelineKind!
    var timelineItems: [RoomTimelineItemProtocol] = []
    var paginationState: TimelinePaginationState {
        get { return underlyingPaginationState }
        set(value) { underlyingPaginationState = value }
    }
    var underlyingPaginationState: TimelinePaginationState!
    var callbacks: PassthroughSubject<TimelineControllerCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<TimelineControllerCallback, Never>!

    //MARK: - processItemAppearance

    private let processItemAppearanceCallsCountLock = NSLock()
    private var processItemAppearanceUnderlyingCallsCount = 0
    var processItemAppearanceCallsCount: Int {
        get { processItemAppearanceCallsCountLock.withLock { processItemAppearanceUnderlyingCallsCount } }
        set { processItemAppearanceCallsCountLock.withLock { processItemAppearanceUnderlyingCallsCount = newValue } }
    }
    var processItemAppearanceCalled: Bool {
        return processItemAppearanceCallsCount > 0
    }
    private let processItemAppearanceReceivedItemIDLock = NSLock()
    private var processItemAppearanceUnderlyingReceivedItemID: TimelineItemIdentifier?
    var processItemAppearanceReceivedItemID: TimelineItemIdentifier? {
        get { processItemAppearanceReceivedItemIDLock.withLock { processItemAppearanceUnderlyingReceivedItemID } }
        set { processItemAppearanceReceivedItemIDLock.withLock { processItemAppearanceUnderlyingReceivedItemID = newValue } }
    }
    private let processItemAppearanceReceivedInvocationsLock = NSLock()
    private var processItemAppearanceUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var processItemAppearanceReceivedInvocations: [TimelineItemIdentifier] {
        get { processItemAppearanceReceivedInvocationsLock.withLock { processItemAppearanceUnderlyingReceivedInvocations } }
        set { processItemAppearanceReceivedInvocationsLock.withLock { processItemAppearanceUnderlyingReceivedInvocations = newValue } }
    }
    var processItemAppearanceClosure: ((TimelineItemIdentifier) async -> Void)?

    func processItemAppearance(_ itemID: TimelineItemIdentifier) async {
        processItemAppearanceCallsCountLock.withLock { processItemAppearanceUnderlyingCallsCount += 1 }
        processItemAppearanceReceivedItemID = itemID
        processItemAppearanceReceivedInvocationsLock.withLock { processItemAppearanceUnderlyingReceivedInvocations.append(itemID) }
        await processItemAppearanceClosure?(itemID)
    }
    //MARK: - processItemDisappearance

    private let processItemDisappearanceCallsCountLock = NSLock()
    private var processItemDisappearanceUnderlyingCallsCount = 0
    var processItemDisappearanceCallsCount: Int {
        get { processItemDisappearanceCallsCountLock.withLock { processItemDisappearanceUnderlyingCallsCount } }
        set { processItemDisappearanceCallsCountLock.withLock { processItemDisappearanceUnderlyingCallsCount = newValue } }
    }
    var processItemDisappearanceCalled: Bool {
        return processItemDisappearanceCallsCount > 0
    }
    private let processItemDisappearanceReceivedItemIDLock = NSLock()
    private var processItemDisappearanceUnderlyingReceivedItemID: TimelineItemIdentifier?
    var processItemDisappearanceReceivedItemID: TimelineItemIdentifier? {
        get { processItemDisappearanceReceivedItemIDLock.withLock { processItemDisappearanceUnderlyingReceivedItemID } }
        set { processItemDisappearanceReceivedItemIDLock.withLock { processItemDisappearanceUnderlyingReceivedItemID = newValue } }
    }
    private let processItemDisappearanceReceivedInvocationsLock = NSLock()
    private var processItemDisappearanceUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var processItemDisappearanceReceivedInvocations: [TimelineItemIdentifier] {
        get { processItemDisappearanceReceivedInvocationsLock.withLock { processItemDisappearanceUnderlyingReceivedInvocations } }
        set { processItemDisappearanceReceivedInvocationsLock.withLock { processItemDisappearanceUnderlyingReceivedInvocations = newValue } }
    }
    var processItemDisappearanceClosure: ((TimelineItemIdentifier) async -> Void)?

    func processItemDisappearance(_ itemID: TimelineItemIdentifier) async {
        processItemDisappearanceCallsCountLock.withLock { processItemDisappearanceUnderlyingCallsCount += 1 }
        processItemDisappearanceReceivedItemID = itemID
        processItemDisappearanceReceivedInvocationsLock.withLock { processItemDisappearanceUnderlyingReceivedInvocations.append(itemID) }
        await processItemDisappearanceClosure?(itemID)
    }
    //MARK: - focusOnEvent

    private let focusOnEventTimelineSizeCallsCountLock = NSLock()
    private var focusOnEventTimelineSizeUnderlyingCallsCount = 0
    var focusOnEventTimelineSizeCallsCount: Int {
        get { focusOnEventTimelineSizeCallsCountLock.withLock { focusOnEventTimelineSizeUnderlyingCallsCount } }
        set { focusOnEventTimelineSizeCallsCountLock.withLock { focusOnEventTimelineSizeUnderlyingCallsCount = newValue } }
    }
    var focusOnEventTimelineSizeCalled: Bool {
        return focusOnEventTimelineSizeCallsCount > 0
    }
    private let focusOnEventTimelineSizeReceivedArgumentsLock = NSLock()
    private var focusOnEventTimelineSizeUnderlyingReceivedArguments: (eventID: String, timelineSize: UInt16)?
    var focusOnEventTimelineSizeReceivedArguments: (eventID: String, timelineSize: UInt16)? {
        get { focusOnEventTimelineSizeReceivedArgumentsLock.withLock { focusOnEventTimelineSizeUnderlyingReceivedArguments } }
        set { focusOnEventTimelineSizeReceivedArgumentsLock.withLock { focusOnEventTimelineSizeUnderlyingReceivedArguments = newValue } }
    }
    private let focusOnEventTimelineSizeReceivedInvocationsLock = NSLock()
    private var focusOnEventTimelineSizeUnderlyingReceivedInvocations: [(eventID: String, timelineSize: UInt16)] = []
    var focusOnEventTimelineSizeReceivedInvocations: [(eventID: String, timelineSize: UInt16)] {
        get { focusOnEventTimelineSizeReceivedInvocationsLock.withLock { focusOnEventTimelineSizeUnderlyingReceivedInvocations } }
        set { focusOnEventTimelineSizeReceivedInvocationsLock.withLock { focusOnEventTimelineSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let focusOnEventTimelineSizeReturnValueLock = NSLock()
    private var focusOnEventTimelineSizeUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var focusOnEventTimelineSizeReturnValue: Result<Void, TimelineControllerError>! {
        get { focusOnEventTimelineSizeReturnValueLock.withLock { focusOnEventTimelineSizeUnderlyingReturnValue } }
        set { focusOnEventTimelineSizeReturnValueLock.withLock { focusOnEventTimelineSizeUnderlyingReturnValue = newValue } }
    }
    var focusOnEventTimelineSizeClosure: ((String, UInt16) async -> Result<Void, TimelineControllerError>)?

    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, TimelineControllerError> {
        focusOnEventTimelineSizeCallsCountLock.withLock { focusOnEventTimelineSizeUnderlyingCallsCount += 1 }
        focusOnEventTimelineSizeReceivedArguments = (eventID: eventID, timelineSize: timelineSize)
        focusOnEventTimelineSizeReceivedInvocationsLock.withLock { focusOnEventTimelineSizeUnderlyingReceivedInvocations.append((eventID: eventID, timelineSize: timelineSize)) }
        if let focusOnEventTimelineSizeClosure = focusOnEventTimelineSizeClosure {
            return await focusOnEventTimelineSizeClosure(eventID, timelineSize)
        } else {
            return focusOnEventTimelineSizeReturnValue
        }
    }
    //MARK: - focusLive

    private let focusLiveCallsCountLock = NSLock()
    private var focusLiveUnderlyingCallsCount = 0
    var focusLiveCallsCount: Int {
        get { focusLiveCallsCountLock.withLock { focusLiveUnderlyingCallsCount } }
        set { focusLiveCallsCountLock.withLock { focusLiveUnderlyingCallsCount = newValue } }
    }
    var focusLiveCalled: Bool {
        return focusLiveCallsCount > 0
    }
    var focusLiveClosure: (() -> Void)?

    func focusLive() {
        focusLiveCallsCountLock.withLock { focusLiveUnderlyingCallsCount += 1 }
        focusLiveClosure?()
    }
    //MARK: - paginateBackwards

    private let paginateBackwardsRequestSizeCallsCountLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingCallsCount = 0
    var paginateBackwardsRequestSizeCallsCount: Int {
        get { paginateBackwardsRequestSizeCallsCountLock.withLock { paginateBackwardsRequestSizeUnderlyingCallsCount } }
        set { paginateBackwardsRequestSizeCallsCountLock.withLock { paginateBackwardsRequestSizeUnderlyingCallsCount = newValue } }
    }
    var paginateBackwardsRequestSizeCalled: Bool {
        return paginateBackwardsRequestSizeCallsCount > 0
    }
    private let paginateBackwardsRequestSizeReceivedRequestSizeLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingReceivedRequestSize: UInt16?
    var paginateBackwardsRequestSizeReceivedRequestSize: UInt16? {
        get { paginateBackwardsRequestSizeReceivedRequestSizeLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedRequestSize } }
        set { paginateBackwardsRequestSizeReceivedRequestSizeLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedRequestSize = newValue } }
    }
    private let paginateBackwardsRequestSizeReceivedInvocationsLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingReceivedInvocations: [UInt16] = []
    var paginateBackwardsRequestSizeReceivedInvocations: [UInt16] {
        get { paginateBackwardsRequestSizeReceivedInvocationsLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedInvocations } }
        set { paginateBackwardsRequestSizeReceivedInvocationsLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let paginateBackwardsRequestSizeReturnValueLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var paginateBackwardsRequestSizeReturnValue: Result<Void, TimelineControllerError>! {
        get { paginateBackwardsRequestSizeReturnValueLock.withLock { paginateBackwardsRequestSizeUnderlyingReturnValue } }
        set { paginateBackwardsRequestSizeReturnValueLock.withLock { paginateBackwardsRequestSizeUnderlyingReturnValue = newValue } }
    }
    var paginateBackwardsRequestSizeClosure: ((UInt16) async -> Result<Void, TimelineControllerError>)?

    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
        paginateBackwardsRequestSizeCallsCountLock.withLock { paginateBackwardsRequestSizeUnderlyingCallsCount += 1 }
        paginateBackwardsRequestSizeReceivedRequestSize = requestSize
        paginateBackwardsRequestSizeReceivedInvocationsLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedInvocations.append(requestSize) }
        if let paginateBackwardsRequestSizeClosure = paginateBackwardsRequestSizeClosure {
            return await paginateBackwardsRequestSizeClosure(requestSize)
        } else {
            return paginateBackwardsRequestSizeReturnValue
        }
    }
    //MARK: - paginateForwards

    private let paginateForwardsRequestSizeCallsCountLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingCallsCount = 0
    var paginateForwardsRequestSizeCallsCount: Int {
        get { paginateForwardsRequestSizeCallsCountLock.withLock { paginateForwardsRequestSizeUnderlyingCallsCount } }
        set { paginateForwardsRequestSizeCallsCountLock.withLock { paginateForwardsRequestSizeUnderlyingCallsCount = newValue } }
    }
    var paginateForwardsRequestSizeCalled: Bool {
        return paginateForwardsRequestSizeCallsCount > 0
    }
    private let paginateForwardsRequestSizeReceivedRequestSizeLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingReceivedRequestSize: UInt16?
    var paginateForwardsRequestSizeReceivedRequestSize: UInt16? {
        get { paginateForwardsRequestSizeReceivedRequestSizeLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedRequestSize } }
        set { paginateForwardsRequestSizeReceivedRequestSizeLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedRequestSize = newValue } }
    }
    private let paginateForwardsRequestSizeReceivedInvocationsLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingReceivedInvocations: [UInt16] = []
    var paginateForwardsRequestSizeReceivedInvocations: [UInt16] {
        get { paginateForwardsRequestSizeReceivedInvocationsLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedInvocations } }
        set { paginateForwardsRequestSizeReceivedInvocationsLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let paginateForwardsRequestSizeReturnValueLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var paginateForwardsRequestSizeReturnValue: Result<Void, TimelineControllerError>! {
        get { paginateForwardsRequestSizeReturnValueLock.withLock { paginateForwardsRequestSizeUnderlyingReturnValue } }
        set { paginateForwardsRequestSizeReturnValueLock.withLock { paginateForwardsRequestSizeUnderlyingReturnValue = newValue } }
    }
    var paginateForwardsRequestSizeClosure: ((UInt16) async -> Result<Void, TimelineControllerError>)?

    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
        paginateForwardsRequestSizeCallsCountLock.withLock { paginateForwardsRequestSizeUnderlyingCallsCount += 1 }
        paginateForwardsRequestSizeReceivedRequestSize = requestSize
        paginateForwardsRequestSizeReceivedInvocationsLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedInvocations.append(requestSize) }
        if let paginateForwardsRequestSizeClosure = paginateForwardsRequestSizeClosure {
            return await paginateForwardsRequestSizeClosure(requestSize)
        } else {
            return paginateForwardsRequestSizeReturnValue
        }
    }
    //MARK: - sendReadReceipt

    private let sendReadReceiptForCallsCountLock = NSLock()
    private var sendReadReceiptForUnderlyingCallsCount = 0
    var sendReadReceiptForCallsCount: Int {
        get { sendReadReceiptForCallsCountLock.withLock { sendReadReceiptForUnderlyingCallsCount } }
        set { sendReadReceiptForCallsCountLock.withLock { sendReadReceiptForUnderlyingCallsCount = newValue } }
    }
    var sendReadReceiptForCalled: Bool {
        return sendReadReceiptForCallsCount > 0
    }
    private let sendReadReceiptForReceivedItemIDLock = NSLock()
    private var sendReadReceiptForUnderlyingReceivedItemID: TimelineItemIdentifier?
    var sendReadReceiptForReceivedItemID: TimelineItemIdentifier? {
        get { sendReadReceiptForReceivedItemIDLock.withLock { sendReadReceiptForUnderlyingReceivedItemID } }
        set { sendReadReceiptForReceivedItemIDLock.withLock { sendReadReceiptForUnderlyingReceivedItemID = newValue } }
    }
    private let sendReadReceiptForReceivedInvocationsLock = NSLock()
    private var sendReadReceiptForUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var sendReadReceiptForReceivedInvocations: [TimelineItemIdentifier] {
        get { sendReadReceiptForReceivedInvocationsLock.withLock { sendReadReceiptForUnderlyingReceivedInvocations } }
        set { sendReadReceiptForReceivedInvocationsLock.withLock { sendReadReceiptForUnderlyingReceivedInvocations = newValue } }
    }
    var sendReadReceiptForClosure: ((TimelineItemIdentifier) async -> Void)?

    func sendReadReceipt(for itemID: TimelineItemIdentifier) async {
        sendReadReceiptForCallsCountLock.withLock { sendReadReceiptForUnderlyingCallsCount += 1 }
        sendReadReceiptForReceivedItemID = itemID
        sendReadReceiptForReceivedInvocationsLock.withLock { sendReadReceiptForUnderlyingReceivedInvocations.append(itemID) }
        await sendReadReceiptForClosure?(itemID)
    }
    //MARK: - edit

    private let editMessageHtmlIntentionalMentionsCallsCountLock = NSLock()
    private var editMessageHtmlIntentionalMentionsUnderlyingCallsCount = 0
    var editMessageHtmlIntentionalMentionsCallsCount: Int {
        get { editMessageHtmlIntentionalMentionsCallsCountLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingCallsCount } }
        set { editMessageHtmlIntentionalMentionsCallsCountLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingCallsCount = newValue } }
    }
    var editMessageHtmlIntentionalMentionsCalled: Bool {
        return editMessageHtmlIntentionalMentionsCallsCount > 0
    }
    private let editMessageHtmlIntentionalMentionsReceivedArgumentsLock = NSLock()
    private var editMessageHtmlIntentionalMentionsUnderlyingReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)?
    var editMessageHtmlIntentionalMentionsReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)? {
        get { editMessageHtmlIntentionalMentionsReceivedArgumentsLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingReceivedArguments } }
        set { editMessageHtmlIntentionalMentionsReceivedArgumentsLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingReceivedArguments = newValue } }
    }
    private let editMessageHtmlIntentionalMentionsReceivedInvocationsLock = NSLock()
    private var editMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)] = []
    var editMessageHtmlIntentionalMentionsReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)] {
        get { editMessageHtmlIntentionalMentionsReceivedInvocationsLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations } }
        set { editMessageHtmlIntentionalMentionsReceivedInvocationsLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations = newValue } }
    }
    var editMessageHtmlIntentionalMentionsClosure: ((TimelineItemIdentifier.EventOrTransactionID, String, String?, IntentionalMentions) async -> Void)?

    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions) async {
        editMessageHtmlIntentionalMentionsCallsCountLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingCallsCount += 1 }
        editMessageHtmlIntentionalMentionsReceivedArguments = (eventOrTransactionID: eventOrTransactionID, message: message, html: html, intentionalMentions: intentionalMentions)
        editMessageHtmlIntentionalMentionsReceivedInvocationsLock.withLock { editMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations.append((eventOrTransactionID: eventOrTransactionID, message: message, html: html, intentionalMentions: intentionalMentions)) }
        await editMessageHtmlIntentionalMentionsClosure?(eventOrTransactionID, message, html, intentionalMentions)
    }
    //MARK: - editCaption

    private let editCaptionMessageHtmlIntentionalMentionsCallsCountLock = NSLock()
    private var editCaptionMessageHtmlIntentionalMentionsUnderlyingCallsCount = 0
    var editCaptionMessageHtmlIntentionalMentionsCallsCount: Int {
        get { editCaptionMessageHtmlIntentionalMentionsCallsCountLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingCallsCount } }
        set { editCaptionMessageHtmlIntentionalMentionsCallsCountLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingCallsCount = newValue } }
    }
    var editCaptionMessageHtmlIntentionalMentionsCalled: Bool {
        return editCaptionMessageHtmlIntentionalMentionsCallsCount > 0
    }
    private let editCaptionMessageHtmlIntentionalMentionsReceivedArgumentsLock = NSLock()
    private var editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)?
    var editCaptionMessageHtmlIntentionalMentionsReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)? {
        get { editCaptionMessageHtmlIntentionalMentionsReceivedArgumentsLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedArguments } }
        set { editCaptionMessageHtmlIntentionalMentionsReceivedArgumentsLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedArguments = newValue } }
    }
    private let editCaptionMessageHtmlIntentionalMentionsReceivedInvocationsLock = NSLock()
    private var editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)] = []
    var editCaptionMessageHtmlIntentionalMentionsReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions)] {
        get { editCaptionMessageHtmlIntentionalMentionsReceivedInvocationsLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations } }
        set { editCaptionMessageHtmlIntentionalMentionsReceivedInvocationsLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations = newValue } }
    }
    var editCaptionMessageHtmlIntentionalMentionsClosure: ((TimelineItemIdentifier.EventOrTransactionID, String, String?, IntentionalMentions) async -> Void)?

    func editCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, message: String, html: String?, intentionalMentions: IntentionalMentions) async {
        editCaptionMessageHtmlIntentionalMentionsCallsCountLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingCallsCount += 1 }
        editCaptionMessageHtmlIntentionalMentionsReceivedArguments = (eventOrTransactionID: eventOrTransactionID, message: message, html: html, intentionalMentions: intentionalMentions)
        editCaptionMessageHtmlIntentionalMentionsReceivedInvocationsLock.withLock { editCaptionMessageHtmlIntentionalMentionsUnderlyingReceivedInvocations.append((eventOrTransactionID: eventOrTransactionID, message: message, html: html, intentionalMentions: intentionalMentions)) }
        await editCaptionMessageHtmlIntentionalMentionsClosure?(eventOrTransactionID, message, html, intentionalMentions)
    }
    //MARK: - removeCaption

    private let removeCaptionCallsCountLock = NSLock()
    private var removeCaptionUnderlyingCallsCount = 0
    var removeCaptionCallsCount: Int {
        get { removeCaptionCallsCountLock.withLock { removeCaptionUnderlyingCallsCount } }
        set { removeCaptionCallsCountLock.withLock { removeCaptionUnderlyingCallsCount = newValue } }
    }
    var removeCaptionCalled: Bool {
        return removeCaptionCallsCount > 0
    }
    private let removeCaptionReceivedEventOrTransactionIDLock = NSLock()
    private var removeCaptionUnderlyingReceivedEventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID?
    var removeCaptionReceivedEventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID? {
        get { removeCaptionReceivedEventOrTransactionIDLock.withLock { removeCaptionUnderlyingReceivedEventOrTransactionID } }
        set { removeCaptionReceivedEventOrTransactionIDLock.withLock { removeCaptionUnderlyingReceivedEventOrTransactionID = newValue } }
    }
    private let removeCaptionReceivedInvocationsLock = NSLock()
    private var removeCaptionUnderlyingReceivedInvocations: [TimelineItemIdentifier.EventOrTransactionID] = []
    var removeCaptionReceivedInvocations: [TimelineItemIdentifier.EventOrTransactionID] {
        get { removeCaptionReceivedInvocationsLock.withLock { removeCaptionUnderlyingReceivedInvocations } }
        set { removeCaptionReceivedInvocationsLock.withLock { removeCaptionUnderlyingReceivedInvocations = newValue } }
    }
    var removeCaptionClosure: ((TimelineItemIdentifier.EventOrTransactionID) async -> Void)?

    func removeCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        removeCaptionCallsCountLock.withLock { removeCaptionUnderlyingCallsCount += 1 }
        removeCaptionReceivedEventOrTransactionID = eventOrTransactionID
        removeCaptionReceivedInvocationsLock.withLock { removeCaptionUnderlyingReceivedInvocations.append(eventOrTransactionID) }
        await removeCaptionClosure?(eventOrTransactionID)
    }
    //MARK: - toggleReaction

    private let toggleReactionToCallsCountLock = NSLock()
    private var toggleReactionToUnderlyingCallsCount = 0
    var toggleReactionToCallsCount: Int {
        get { toggleReactionToCallsCountLock.withLock { toggleReactionToUnderlyingCallsCount } }
        set { toggleReactionToCallsCountLock.withLock { toggleReactionToUnderlyingCallsCount = newValue } }
    }
    var toggleReactionToCalled: Bool {
        return toggleReactionToCallsCount > 0
    }
    private let toggleReactionToReceivedArgumentsLock = NSLock()
    private var toggleReactionToUnderlyingReceivedArguments: (reaction: String, eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID)?
    var toggleReactionToReceivedArguments: (reaction: String, eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID)? {
        get { toggleReactionToReceivedArgumentsLock.withLock { toggleReactionToUnderlyingReceivedArguments } }
        set { toggleReactionToReceivedArgumentsLock.withLock { toggleReactionToUnderlyingReceivedArguments = newValue } }
    }
    private let toggleReactionToReceivedInvocationsLock = NSLock()
    private var toggleReactionToUnderlyingReceivedInvocations: [(reaction: String, eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID)] = []
    var toggleReactionToReceivedInvocations: [(reaction: String, eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID)] {
        get { toggleReactionToReceivedInvocationsLock.withLock { toggleReactionToUnderlyingReceivedInvocations } }
        set { toggleReactionToReceivedInvocationsLock.withLock { toggleReactionToUnderlyingReceivedInvocations = newValue } }
    }
    var toggleReactionToClosure: ((String, TimelineItemIdentifier.EventOrTransactionID) async -> Void)?

    func toggleReaction(_ reaction: String, to eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        toggleReactionToCallsCountLock.withLock { toggleReactionToUnderlyingCallsCount += 1 }
        toggleReactionToReceivedArguments = (reaction: reaction, eventOrTransactionID: eventOrTransactionID)
        toggleReactionToReceivedInvocationsLock.withLock { toggleReactionToUnderlyingReceivedInvocations.append((reaction: reaction, eventOrTransactionID: eventOrTransactionID)) }
        await toggleReactionToClosure?(reaction, eventOrTransactionID)
    }
    //MARK: - redact

    private let redactCallsCountLock = NSLock()
    private var redactUnderlyingCallsCount = 0
    var redactCallsCount: Int {
        get { redactCallsCountLock.withLock { redactUnderlyingCallsCount } }
        set { redactCallsCountLock.withLock { redactUnderlyingCallsCount = newValue } }
    }
    var redactCalled: Bool {
        return redactCallsCount > 0
    }
    private let redactReceivedEventOrTransactionIDLock = NSLock()
    private var redactUnderlyingReceivedEventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID?
    var redactReceivedEventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID? {
        get { redactReceivedEventOrTransactionIDLock.withLock { redactUnderlyingReceivedEventOrTransactionID } }
        set { redactReceivedEventOrTransactionIDLock.withLock { redactUnderlyingReceivedEventOrTransactionID = newValue } }
    }
    private let redactReceivedInvocationsLock = NSLock()
    private var redactUnderlyingReceivedInvocations: [TimelineItemIdentifier.EventOrTransactionID] = []
    var redactReceivedInvocations: [TimelineItemIdentifier.EventOrTransactionID] {
        get { redactReceivedInvocationsLock.withLock { redactUnderlyingReceivedInvocations } }
        set { redactReceivedInvocationsLock.withLock { redactUnderlyingReceivedInvocations = newValue } }
    }
    var redactClosure: ((TimelineItemIdentifier.EventOrTransactionID) async -> Void)?

    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        redactCallsCountLock.withLock { redactUnderlyingCallsCount += 1 }
        redactReceivedEventOrTransactionID = eventOrTransactionID
        redactReceivedInvocationsLock.withLock { redactUnderlyingReceivedInvocations.append(eventOrTransactionID) }
        await redactClosure?(eventOrTransactionID)
    }
    //MARK: - pin

    private let pinEventIDCallsCountLock = NSLock()
    private var pinEventIDUnderlyingCallsCount = 0
    var pinEventIDCallsCount: Int {
        get { pinEventIDCallsCountLock.withLock { pinEventIDUnderlyingCallsCount } }
        set { pinEventIDCallsCountLock.withLock { pinEventIDUnderlyingCallsCount = newValue } }
    }
    var pinEventIDCalled: Bool {
        return pinEventIDCallsCount > 0
    }
    private let pinEventIDReceivedEventIDLock = NSLock()
    private var pinEventIDUnderlyingReceivedEventID: String?
    var pinEventIDReceivedEventID: String? {
        get { pinEventIDReceivedEventIDLock.withLock { pinEventIDUnderlyingReceivedEventID } }
        set { pinEventIDReceivedEventIDLock.withLock { pinEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let pinEventIDReceivedInvocationsLock = NSLock()
    private var pinEventIDUnderlyingReceivedInvocations: [String] = []
    var pinEventIDReceivedInvocations: [String] {
        get { pinEventIDReceivedInvocationsLock.withLock { pinEventIDUnderlyingReceivedInvocations } }
        set { pinEventIDReceivedInvocationsLock.withLock { pinEventIDUnderlyingReceivedInvocations = newValue } }
    }
    var pinEventIDClosure: ((String) async -> Void)?

    func pin(eventID: String) async {
        pinEventIDCallsCountLock.withLock { pinEventIDUnderlyingCallsCount += 1 }
        pinEventIDReceivedEventID = eventID
        pinEventIDReceivedInvocationsLock.withLock { pinEventIDUnderlyingReceivedInvocations.append(eventID) }
        await pinEventIDClosure?(eventID)
    }
    //MARK: - unpin

    private let unpinEventIDCallsCountLock = NSLock()
    private var unpinEventIDUnderlyingCallsCount = 0
    var unpinEventIDCallsCount: Int {
        get { unpinEventIDCallsCountLock.withLock { unpinEventIDUnderlyingCallsCount } }
        set { unpinEventIDCallsCountLock.withLock { unpinEventIDUnderlyingCallsCount = newValue } }
    }
    var unpinEventIDCalled: Bool {
        return unpinEventIDCallsCount > 0
    }
    private let unpinEventIDReceivedEventIDLock = NSLock()
    private var unpinEventIDUnderlyingReceivedEventID: String?
    var unpinEventIDReceivedEventID: String? {
        get { unpinEventIDReceivedEventIDLock.withLock { unpinEventIDUnderlyingReceivedEventID } }
        set { unpinEventIDReceivedEventIDLock.withLock { unpinEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let unpinEventIDReceivedInvocationsLock = NSLock()
    private var unpinEventIDUnderlyingReceivedInvocations: [String] = []
    var unpinEventIDReceivedInvocations: [String] {
        get { unpinEventIDReceivedInvocationsLock.withLock { unpinEventIDUnderlyingReceivedInvocations } }
        set { unpinEventIDReceivedInvocationsLock.withLock { unpinEventIDUnderlyingReceivedInvocations = newValue } }
    }
    var unpinEventIDClosure: ((String) async -> Void)?

    func unpin(eventID: String) async {
        unpinEventIDCallsCountLock.withLock { unpinEventIDUnderlyingCallsCount += 1 }
        unpinEventIDReceivedEventID = eventID
        unpinEventIDReceivedInvocationsLock.withLock { unpinEventIDUnderlyingReceivedInvocations.append(eventID) }
        await unpinEventIDClosure?(eventID)
    }
    //MARK: - messageEventContent

    private let messageEventContentForCallsCountLock = NSLock()
    private var messageEventContentForUnderlyingCallsCount = 0
    var messageEventContentForCallsCount: Int {
        get { messageEventContentForCallsCountLock.withLock { messageEventContentForUnderlyingCallsCount } }
        set { messageEventContentForCallsCountLock.withLock { messageEventContentForUnderlyingCallsCount = newValue } }
    }
    var messageEventContentForCalled: Bool {
        return messageEventContentForCallsCount > 0
    }
    private let messageEventContentForReceivedItemIDLock = NSLock()
    private var messageEventContentForUnderlyingReceivedItemID: TimelineItemIdentifier?
    var messageEventContentForReceivedItemID: TimelineItemIdentifier? {
        get { messageEventContentForReceivedItemIDLock.withLock { messageEventContentForUnderlyingReceivedItemID } }
        set { messageEventContentForReceivedItemIDLock.withLock { messageEventContentForUnderlyingReceivedItemID = newValue } }
    }
    private let messageEventContentForReceivedInvocationsLock = NSLock()
    private var messageEventContentForUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var messageEventContentForReceivedInvocations: [TimelineItemIdentifier] {
        get { messageEventContentForReceivedInvocationsLock.withLock { messageEventContentForUnderlyingReceivedInvocations } }
        set { messageEventContentForReceivedInvocationsLock.withLock { messageEventContentForUnderlyingReceivedInvocations = newValue } }
    }

    private let messageEventContentForReturnValueLock = NSLock()
    private var messageEventContentForUnderlyingReturnValue: RoomMessageEventContentWithoutRelation?
    var messageEventContentForReturnValue: RoomMessageEventContentWithoutRelation? {
        get { messageEventContentForReturnValueLock.withLock { messageEventContentForUnderlyingReturnValue } }
        set { messageEventContentForReturnValueLock.withLock { messageEventContentForUnderlyingReturnValue = newValue } }
    }
    var messageEventContentForClosure: ((TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?)?

    func messageEventContent(for itemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation? {
        messageEventContentForCallsCountLock.withLock { messageEventContentForUnderlyingCallsCount += 1 }
        messageEventContentForReceivedItemID = itemID
        messageEventContentForReceivedInvocationsLock.withLock { messageEventContentForUnderlyingReceivedInvocations.append(itemID) }
        if let messageEventContentForClosure = messageEventContentForClosure {
            return await messageEventContentForClosure(itemID)
        } else {
            return messageEventContentForReturnValue
        }
    }
    //MARK: - debugInfo

    private let debugInfoForCallsCountLock = NSLock()
    private var debugInfoForUnderlyingCallsCount = 0
    var debugInfoForCallsCount: Int {
        get { debugInfoForCallsCountLock.withLock { debugInfoForUnderlyingCallsCount } }
        set { debugInfoForCallsCountLock.withLock { debugInfoForUnderlyingCallsCount = newValue } }
    }
    var debugInfoForCalled: Bool {
        return debugInfoForCallsCount > 0
    }
    private let debugInfoForReceivedItemIDLock = NSLock()
    private var debugInfoForUnderlyingReceivedItemID: TimelineItemIdentifier?
    var debugInfoForReceivedItemID: TimelineItemIdentifier? {
        get { debugInfoForReceivedItemIDLock.withLock { debugInfoForUnderlyingReceivedItemID } }
        set { debugInfoForReceivedItemIDLock.withLock { debugInfoForUnderlyingReceivedItemID = newValue } }
    }
    private let debugInfoForReceivedInvocationsLock = NSLock()
    private var debugInfoForUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var debugInfoForReceivedInvocations: [TimelineItemIdentifier] {
        get { debugInfoForReceivedInvocationsLock.withLock { debugInfoForUnderlyingReceivedInvocations } }
        set { debugInfoForReceivedInvocationsLock.withLock { debugInfoForUnderlyingReceivedInvocations = newValue } }
    }

    private let debugInfoForReturnValueLock = NSLock()
    private var debugInfoForUnderlyingReturnValue: TimelineItemDebugInfo!
    var debugInfoForReturnValue: TimelineItemDebugInfo! {
        get { debugInfoForReturnValueLock.withLock { debugInfoForUnderlyingReturnValue } }
        set { debugInfoForReturnValueLock.withLock { debugInfoForUnderlyingReturnValue = newValue } }
    }
    var debugInfoForClosure: ((TimelineItemIdentifier) -> TimelineItemDebugInfo)?

    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo {
        debugInfoForCallsCountLock.withLock { debugInfoForUnderlyingCallsCount += 1 }
        debugInfoForReceivedItemID = itemID
        debugInfoForReceivedInvocationsLock.withLock { debugInfoForUnderlyingReceivedInvocations.append(itemID) }
        if let debugInfoForClosure = debugInfoForClosure {
            return debugInfoForClosure(itemID)
        } else {
            return debugInfoForReturnValue
        }
    }
    //MARK: - sendHandle

    private let sendHandleForCallsCountLock = NSLock()
    private var sendHandleForUnderlyingCallsCount = 0
    var sendHandleForCallsCount: Int {
        get { sendHandleForCallsCountLock.withLock { sendHandleForUnderlyingCallsCount } }
        set { sendHandleForCallsCountLock.withLock { sendHandleForUnderlyingCallsCount = newValue } }
    }
    var sendHandleForCalled: Bool {
        return sendHandleForCallsCount > 0
    }
    private let sendHandleForReceivedItemIDLock = NSLock()
    private var sendHandleForUnderlyingReceivedItemID: TimelineItemIdentifier?
    var sendHandleForReceivedItemID: TimelineItemIdentifier? {
        get { sendHandleForReceivedItemIDLock.withLock { sendHandleForUnderlyingReceivedItemID } }
        set { sendHandleForReceivedItemIDLock.withLock { sendHandleForUnderlyingReceivedItemID = newValue } }
    }
    private let sendHandleForReceivedInvocationsLock = NSLock()
    private var sendHandleForUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var sendHandleForReceivedInvocations: [TimelineItemIdentifier] {
        get { sendHandleForReceivedInvocationsLock.withLock { sendHandleForUnderlyingReceivedInvocations } }
        set { sendHandleForReceivedInvocationsLock.withLock { sendHandleForUnderlyingReceivedInvocations = newValue } }
    }

    private let sendHandleForReturnValueLock = NSLock()
    private var sendHandleForUnderlyingReturnValue: SendHandleProxy?
    var sendHandleForReturnValue: SendHandleProxy? {
        get { sendHandleForReturnValueLock.withLock { sendHandleForUnderlyingReturnValue } }
        set { sendHandleForReturnValueLock.withLock { sendHandleForUnderlyingReturnValue = newValue } }
    }
    var sendHandleForClosure: ((TimelineItemIdentifier) -> SendHandleProxy?)?

    func sendHandle(for itemID: TimelineItemIdentifier) -> SendHandleProxy? {
        sendHandleForCallsCountLock.withLock { sendHandleForUnderlyingCallsCount += 1 }
        sendHandleForReceivedItemID = itemID
        sendHandleForReceivedInvocationsLock.withLock { sendHandleForUnderlyingReceivedInvocations.append(itemID) }
        if let sendHandleForClosure = sendHandleForClosure {
            return sendHandleForClosure(itemID)
        } else {
            return sendHandleForReturnValue
        }
    }
    //MARK: - eventTimestamp

    private let eventTimestampForCallsCountLock = NSLock()
    private var eventTimestampForUnderlyingCallsCount = 0
    var eventTimestampForCallsCount: Int {
        get { eventTimestampForCallsCountLock.withLock { eventTimestampForUnderlyingCallsCount } }
        set { eventTimestampForCallsCountLock.withLock { eventTimestampForUnderlyingCallsCount = newValue } }
    }
    var eventTimestampForCalled: Bool {
        return eventTimestampForCallsCount > 0
    }
    private let eventTimestampForReceivedItemIDLock = NSLock()
    private var eventTimestampForUnderlyingReceivedItemID: TimelineItemIdentifier?
    var eventTimestampForReceivedItemID: TimelineItemIdentifier? {
        get { eventTimestampForReceivedItemIDLock.withLock { eventTimestampForUnderlyingReceivedItemID } }
        set { eventTimestampForReceivedItemIDLock.withLock { eventTimestampForUnderlyingReceivedItemID = newValue } }
    }
    private let eventTimestampForReceivedInvocationsLock = NSLock()
    private var eventTimestampForUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var eventTimestampForReceivedInvocations: [TimelineItemIdentifier] {
        get { eventTimestampForReceivedInvocationsLock.withLock { eventTimestampForUnderlyingReceivedInvocations } }
        set { eventTimestampForReceivedInvocationsLock.withLock { eventTimestampForUnderlyingReceivedInvocations = newValue } }
    }

    private let eventTimestampForReturnValueLock = NSLock()
    private var eventTimestampForUnderlyingReturnValue: Date?
    var eventTimestampForReturnValue: Date? {
        get { eventTimestampForReturnValueLock.withLock { eventTimestampForUnderlyingReturnValue } }
        set { eventTimestampForReturnValueLock.withLock { eventTimestampForUnderlyingReturnValue = newValue } }
    }
    var eventTimestampForClosure: ((TimelineItemIdentifier) -> Date?)?

    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date? {
        eventTimestampForCallsCountLock.withLock { eventTimestampForUnderlyingCallsCount += 1 }
        eventTimestampForReceivedItemID = itemID
        eventTimestampForReceivedInvocationsLock.withLock { eventTimestampForUnderlyingReceivedInvocations.append(itemID) }
        if let eventTimestampForClosure = eventTimestampForClosure {
            return eventTimestampForClosure(itemID)
        } else {
            return eventTimestampForReturnValue
        }
    }
    //MARK: - sendMessage

    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount = 0
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCount: Int {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount = newValue } }
    }
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsCalled: Bool {
        return sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCount > 0
    }
    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArgumentsLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedArguments: (message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)?
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArguments: (message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)? {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArgumentsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedArguments } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArgumentsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedArguments = newValue } }
    }
    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations: [(message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)] = []
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocations: [(message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)] {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations = newValue } }
    }
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure: ((String, String?, String?, IntentionalMentions) async -> Void)?

    func sendMessage(_ message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions) async {
        sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount += 1 }
        sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArguments = (message: message, html: html, inReplyToEventID: inReplyToEventID, intentionalMentions: intentionalMentions)
        sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations.append((message: message, html: html, inReplyToEventID: inReplyToEventID, intentionalMentions: intentionalMentions)) }
        await sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure?(message, html, inReplyToEventID, intentionalMentions)
    }
    //MARK: - sendAudio

    private let sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendAudioUrlAudioInfoCaptionRequestHandleCallsCount: Int {
        get { sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendAudioUrlAudioInfoCaptionRequestHandleCalled: Bool {
        return sendAudioUrlAudioInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendAudioUrlAudioInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendAudioUrlAudioInfoCaptionRequestHandleReturnValue: Result<Void, TimelineControllerError>! {
        get { sendAudioUrlAudioInfoCaptionRequestHandleReturnValueLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendAudioUrlAudioInfoCaptionRequestHandleReturnValueLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendAudioUrlAudioInfoCaptionRequestHandleClosure: ((URL, AudioInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>)?

    func sendAudio(url: URL, audioInfo: AudioInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendAudioUrlAudioInfoCaptionRequestHandleClosure = sendAudioUrlAudioInfoCaptionRequestHandleClosure {
            return await sendAudioUrlAudioInfoCaptionRequestHandleClosure(url, audioInfo, caption, requestHandle)
        } else {
            return sendAudioUrlAudioInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendFile

    private let sendFileUrlFileInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendFileUrlFileInfoCaptionRequestHandleCallsCount: Int {
        get { sendFileUrlFileInfoCaptionRequestHandleCallsCountLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendFileUrlFileInfoCaptionRequestHandleCallsCountLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendFileUrlFileInfoCaptionRequestHandleCalled: Bool {
        return sendFileUrlFileInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendFileUrlFileInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendFileUrlFileInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendFileUrlFileInfoCaptionRequestHandleReturnValue: Result<Void, TimelineControllerError>! {
        get { sendFileUrlFileInfoCaptionRequestHandleReturnValueLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendFileUrlFileInfoCaptionRequestHandleReturnValueLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendFileUrlFileInfoCaptionRequestHandleClosure: ((URL, FileInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>)?

    func sendFile(url: URL, fileInfo: FileInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        sendFileUrlFileInfoCaptionRequestHandleCallsCountLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendFileUrlFileInfoCaptionRequestHandleClosure = sendFileUrlFileInfoCaptionRequestHandleClosure {
            return await sendFileUrlFileInfoCaptionRequestHandleClosure(url, fileInfo, caption, requestHandle)
        } else {
            return sendFileUrlFileInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendImage

    private let sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCount: Int {
        get { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCalled: Bool {
        return sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValue: Result<Void, TimelineControllerError>! {
        get { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValueLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValueLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure: ((URL, URL, ImageInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>)?

    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure = sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure {
            return await sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure(url, thumbnailURL, imageInfo, caption, requestHandle)
        } else {
            return sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendLocation

    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = 0
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount: Int {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = newValue } }
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCalled: Bool {
        return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount > 0
    }
    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArgumentsLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)?
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)? {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArgumentsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedArguments } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArgumentsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedArguments = newValue } }
    }
    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] = []
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations = newValue } }
    }

    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValueLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue: Result<Void, TimelineControllerError>! {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValueLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValueLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue = newValue } }
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure: ((String, GeoURI, String?, UInt8?, AssetType?) async -> Result<Void, TimelineControllerError>)?

    func sendLocation(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async -> Result<Void, TimelineControllerError> {
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount += 1 }
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments = (body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations.append((body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)) }
        if let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure {
            return await sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure(body, geoURI, description, zoomLevel, assetType)
        } else {
            return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue
        }
    }
    //MARK: - sendVideo

    private let sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCount: Int {
        get { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCalled: Bool {
        return sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValue: Result<Void, TimelineControllerError>! {
        get { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValueLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValueLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure: ((URL, URL, VideoInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>)?

    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure = sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure {
            return await sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure(url, thumbnailURL, videoInfo, caption, requestHandle)
        } else {
            return sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendVoiceMessage

    private let sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock = NSLock()
    private var sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount = 0
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCount: Int {
        get { sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount } }
        set { sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleCalled: Bool {
        return sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCount > 0
    }

    private let sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValueLock = NSLock()
    private var sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue: Result<Void, TimelineControllerError>! {
        get { sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValueLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingReturnValue } }
        set { sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValueLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure: ((URL, AudioInfo, [Float], @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>)?

    func sendVoiceMessage(url: URL, audioInfo: AudioInfo, waveform: [Float], requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount += 1 }
        if let sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure = sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure {
            return await sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure(url, audioInfo, waveform, requestHandle)
        } else {
            return sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue
        }
    }
    //MARK: - createPoll

    private let createPollQuestionAnswersPollKindCallsCountLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingCallsCount = 0
    var createPollQuestionAnswersPollKindCallsCount: Int {
        get { createPollQuestionAnswersPollKindCallsCountLock.withLock { createPollQuestionAnswersPollKindUnderlyingCallsCount } }
        set { createPollQuestionAnswersPollKindCallsCountLock.withLock { createPollQuestionAnswersPollKindUnderlyingCallsCount = newValue } }
    }
    var createPollQuestionAnswersPollKindCalled: Bool {
        return createPollQuestionAnswersPollKindCallsCount > 0
    }
    private let createPollQuestionAnswersPollKindReceivedArgumentsLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)?
    var createPollQuestionAnswersPollKindReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)? {
        get { createPollQuestionAnswersPollKindReceivedArgumentsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedArguments } }
        set { createPollQuestionAnswersPollKindReceivedArgumentsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedArguments = newValue } }
    }
    private let createPollQuestionAnswersPollKindReceivedInvocationsLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] = []
    var createPollQuestionAnswersPollKindReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] {
        get { createPollQuestionAnswersPollKindReceivedInvocationsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedInvocations } }
        set { createPollQuestionAnswersPollKindReceivedInvocationsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedInvocations = newValue } }
    }

    private let createPollQuestionAnswersPollKindReturnValueLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var createPollQuestionAnswersPollKindReturnValue: Result<Void, TimelineControllerError>! {
        get { createPollQuestionAnswersPollKindReturnValueLock.withLock { createPollQuestionAnswersPollKindUnderlyingReturnValue } }
        set { createPollQuestionAnswersPollKindReturnValueLock.withLock { createPollQuestionAnswersPollKindUnderlyingReturnValue = newValue } }
    }
    var createPollQuestionAnswersPollKindClosure: ((String, [String], Poll.Kind) async -> Result<Void, TimelineControllerError>)?

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineControllerError> {
        createPollQuestionAnswersPollKindCallsCountLock.withLock { createPollQuestionAnswersPollKindUnderlyingCallsCount += 1 }
        createPollQuestionAnswersPollKindReceivedArguments = (question: question, answers: answers, pollKind: pollKind)
        createPollQuestionAnswersPollKindReceivedInvocationsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedInvocations.append((question: question, answers: answers, pollKind: pollKind)) }
        if let createPollQuestionAnswersPollKindClosure = createPollQuestionAnswersPollKindClosure {
            return await createPollQuestionAnswersPollKindClosure(question, answers, pollKind)
        } else {
            return createPollQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - editPoll

    private let editPollOriginalQuestionAnswersPollKindCallsCountLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = 0
    var editPollOriginalQuestionAnswersPollKindCallsCount: Int {
        get { editPollOriginalQuestionAnswersPollKindCallsCountLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount } }
        set { editPollOriginalQuestionAnswersPollKindCallsCountLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = newValue } }
    }
    var editPollOriginalQuestionAnswersPollKindCalled: Bool {
        return editPollOriginalQuestionAnswersPollKindCallsCount > 0
    }
    private let editPollOriginalQuestionAnswersPollKindReceivedArgumentsLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingReceivedArguments: (eventID: String, question: String, answers: [String], pollKind: Poll.Kind)?
    var editPollOriginalQuestionAnswersPollKindReceivedArguments: (eventID: String, question: String, answers: [String], pollKind: Poll.Kind)? {
        get { editPollOriginalQuestionAnswersPollKindReceivedArgumentsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedArguments } }
        set { editPollOriginalQuestionAnswersPollKindReceivedArgumentsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedArguments = newValue } }
    }
    private let editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations: [(eventID: String, question: String, answers: [String], pollKind: Poll.Kind)] = []
    var editPollOriginalQuestionAnswersPollKindReceivedInvocations: [(eventID: String, question: String, answers: [String], pollKind: Poll.Kind)] {
        get { editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations } }
        set { editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations = newValue } }
    }

    private let editPollOriginalQuestionAnswersPollKindReturnValueLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var editPollOriginalQuestionAnswersPollKindReturnValue: Result<Void, TimelineControllerError>! {
        get { editPollOriginalQuestionAnswersPollKindReturnValueLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue } }
        set { editPollOriginalQuestionAnswersPollKindReturnValueLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue = newValue } }
    }
    var editPollOriginalQuestionAnswersPollKindClosure: ((String, String, [String], Poll.Kind) async -> Result<Void, TimelineControllerError>)?

    func editPoll(original eventID: String, question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineControllerError> {
        editPollOriginalQuestionAnswersPollKindCallsCountLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount += 1 }
        editPollOriginalQuestionAnswersPollKindReceivedArguments = (eventID: eventID, question: question, answers: answers, pollKind: pollKind)
        editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations.append((eventID: eventID, question: question, answers: answers, pollKind: pollKind)) }
        if let editPollOriginalQuestionAnswersPollKindClosure = editPollOriginalQuestionAnswersPollKindClosure {
            return await editPollOriginalQuestionAnswersPollKindClosure(eventID, question, answers, pollKind)
        } else {
            return editPollOriginalQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - sendPollResponse

    private let sendPollResponsePollStartIDAnswersCallsCountLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingCallsCount = 0
    var sendPollResponsePollStartIDAnswersCallsCount: Int {
        get { sendPollResponsePollStartIDAnswersCallsCountLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingCallsCount } }
        set { sendPollResponsePollStartIDAnswersCallsCountLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingCallsCount = newValue } }
    }
    var sendPollResponsePollStartIDAnswersCalled: Bool {
        return sendPollResponsePollStartIDAnswersCallsCount > 0
    }
    private let sendPollResponsePollStartIDAnswersReceivedArgumentsLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingReceivedArguments: (pollStartID: String, answers: [String])?
    var sendPollResponsePollStartIDAnswersReceivedArguments: (pollStartID: String, answers: [String])? {
        get { sendPollResponsePollStartIDAnswersReceivedArgumentsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedArguments } }
        set { sendPollResponsePollStartIDAnswersReceivedArgumentsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedArguments = newValue } }
    }
    private let sendPollResponsePollStartIDAnswersReceivedInvocationsLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations: [(pollStartID: String, answers: [String])] = []
    var sendPollResponsePollStartIDAnswersReceivedInvocations: [(pollStartID: String, answers: [String])] {
        get { sendPollResponsePollStartIDAnswersReceivedInvocationsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations } }
        set { sendPollResponsePollStartIDAnswersReceivedInvocationsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations = newValue } }
    }

    private let sendPollResponsePollStartIDAnswersReturnValueLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var sendPollResponsePollStartIDAnswersReturnValue: Result<Void, TimelineControllerError>! {
        get { sendPollResponsePollStartIDAnswersReturnValueLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReturnValue } }
        set { sendPollResponsePollStartIDAnswersReturnValueLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReturnValue = newValue } }
    }
    var sendPollResponsePollStartIDAnswersClosure: ((String, [String]) async -> Result<Void, TimelineControllerError>)?

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineControllerError> {
        sendPollResponsePollStartIDAnswersCallsCountLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingCallsCount += 1 }
        sendPollResponsePollStartIDAnswersReceivedArguments = (pollStartID: pollStartID, answers: answers)
        sendPollResponsePollStartIDAnswersReceivedInvocationsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations.append((pollStartID: pollStartID, answers: answers)) }
        if let sendPollResponsePollStartIDAnswersClosure = sendPollResponsePollStartIDAnswersClosure {
            return await sendPollResponsePollStartIDAnswersClosure(pollStartID, answers)
        } else {
            return sendPollResponsePollStartIDAnswersReturnValue
        }
    }
    //MARK: - endPoll

    private let endPollPollStartIDTextCallsCountLock = NSLock()
    private var endPollPollStartIDTextUnderlyingCallsCount = 0
    var endPollPollStartIDTextCallsCount: Int {
        get { endPollPollStartIDTextCallsCountLock.withLock { endPollPollStartIDTextUnderlyingCallsCount } }
        set { endPollPollStartIDTextCallsCountLock.withLock { endPollPollStartIDTextUnderlyingCallsCount = newValue } }
    }
    var endPollPollStartIDTextCalled: Bool {
        return endPollPollStartIDTextCallsCount > 0
    }
    private let endPollPollStartIDTextReceivedArgumentsLock = NSLock()
    private var endPollPollStartIDTextUnderlyingReceivedArguments: (pollStartID: String, text: String)?
    var endPollPollStartIDTextReceivedArguments: (pollStartID: String, text: String)? {
        get { endPollPollStartIDTextReceivedArgumentsLock.withLock { endPollPollStartIDTextUnderlyingReceivedArguments } }
        set { endPollPollStartIDTextReceivedArgumentsLock.withLock { endPollPollStartIDTextUnderlyingReceivedArguments = newValue } }
    }
    private let endPollPollStartIDTextReceivedInvocationsLock = NSLock()
    private var endPollPollStartIDTextUnderlyingReceivedInvocations: [(pollStartID: String, text: String)] = []
    var endPollPollStartIDTextReceivedInvocations: [(pollStartID: String, text: String)] {
        get { endPollPollStartIDTextReceivedInvocationsLock.withLock { endPollPollStartIDTextUnderlyingReceivedInvocations } }
        set { endPollPollStartIDTextReceivedInvocationsLock.withLock { endPollPollStartIDTextUnderlyingReceivedInvocations = newValue } }
    }

    private let endPollPollStartIDTextReturnValueLock = NSLock()
    private var endPollPollStartIDTextUnderlyingReturnValue: Result<Void, TimelineControllerError>!
    var endPollPollStartIDTextReturnValue: Result<Void, TimelineControllerError>! {
        get { endPollPollStartIDTextReturnValueLock.withLock { endPollPollStartIDTextUnderlyingReturnValue } }
        set { endPollPollStartIDTextReturnValueLock.withLock { endPollPollStartIDTextUnderlyingReturnValue = newValue } }
    }
    var endPollPollStartIDTextClosure: ((String, String) async -> Result<Void, TimelineControllerError>)?

    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineControllerError> {
        endPollPollStartIDTextCallsCountLock.withLock { endPollPollStartIDTextUnderlyingCallsCount += 1 }
        endPollPollStartIDTextReceivedArguments = (pollStartID: pollStartID, text: text)
        endPollPollStartIDTextReceivedInvocationsLock.withLock { endPollPollStartIDTextUnderlyingReceivedInvocations.append((pollStartID: pollStartID, text: text)) }
        if let endPollPollStartIDTextClosure = endPollPollStartIDTextClosure {
            return await endPollPollStartIDTextClosure(pollStartID, text)
        } else {
            return endPollPollStartIDTextReturnValue
        }
    }
}
class TimelineItemProviderMock: TimelineItemProviderProtocol, @unchecked Sendable {
    var updatePublisher: AnyPublisher<([TimelineItemProxy], TimelinePaginationState), Never> {
        get { return underlyingUpdatePublisher }
        set(value) { underlyingUpdatePublisher = value }
    }
    var underlyingUpdatePublisher: AnyPublisher<([TimelineItemProxy], TimelinePaginationState), Never>!
    var itemProxies: [TimelineItemProxy] = []
    var paginationState: TimelinePaginationState {
        get { return underlyingPaginationState }
        set(value) { underlyingPaginationState = value }
    }
    var underlyingPaginationState: TimelinePaginationState!
    var kind: TimelineKind {
        get { return underlyingKind }
        set(value) { underlyingKind = value }
    }
    var underlyingKind: TimelineKind!
    var membershipChangePublisher: AnyPublisher<Void, Never> {
        get { return underlyingMembershipChangePublisher }
        set(value) { underlyingMembershipChangePublisher = value }
    }
    var underlyingMembershipChangePublisher: AnyPublisher<Void, Never>!

}
class TimelineProxyMock: TimelineProxyProtocol, @unchecked Sendable {
    var timelineItemProvider: TimelineItemProviderProtocol {
        get { return underlyingTimelineItemProvider }
        set(value) { underlyingTimelineItemProvider = value }
    }
    var underlyingTimelineItemProvider: TimelineItemProviderProtocol!

    //MARK: - subscribeForUpdates

    private let subscribeForUpdatesCallsCountLock = NSLock()
    private var subscribeForUpdatesUnderlyingCallsCount = 0
    var subscribeForUpdatesCallsCount: Int {
        get { subscribeForUpdatesCallsCountLock.withLock { subscribeForUpdatesUnderlyingCallsCount } }
        set { subscribeForUpdatesCallsCountLock.withLock { subscribeForUpdatesUnderlyingCallsCount = newValue } }
    }
    var subscribeForUpdatesCalled: Bool {
        return subscribeForUpdatesCallsCount > 0
    }
    var subscribeForUpdatesClosure: (() async -> Void)?

    func subscribeForUpdates() async {
        subscribeForUpdatesCallsCountLock.withLock { subscribeForUpdatesUnderlyingCallsCount += 1 }
        await subscribeForUpdatesClosure?()
    }
    //MARK: - fetchDetails

    private let fetchDetailsForCallsCountLock = NSLock()
    private var fetchDetailsForUnderlyingCallsCount = 0
    var fetchDetailsForCallsCount: Int {
        get { fetchDetailsForCallsCountLock.withLock { fetchDetailsForUnderlyingCallsCount } }
        set { fetchDetailsForCallsCountLock.withLock { fetchDetailsForUnderlyingCallsCount = newValue } }
    }
    var fetchDetailsForCalled: Bool {
        return fetchDetailsForCallsCount > 0
    }
    private let fetchDetailsForReceivedEventIDLock = NSLock()
    private var fetchDetailsForUnderlyingReceivedEventID: String?
    var fetchDetailsForReceivedEventID: String? {
        get { fetchDetailsForReceivedEventIDLock.withLock { fetchDetailsForUnderlyingReceivedEventID } }
        set { fetchDetailsForReceivedEventIDLock.withLock { fetchDetailsForUnderlyingReceivedEventID = newValue } }
    }
    private let fetchDetailsForReceivedInvocationsLock = NSLock()
    private var fetchDetailsForUnderlyingReceivedInvocations: [String] = []
    var fetchDetailsForReceivedInvocations: [String] {
        get { fetchDetailsForReceivedInvocationsLock.withLock { fetchDetailsForUnderlyingReceivedInvocations } }
        set { fetchDetailsForReceivedInvocationsLock.withLock { fetchDetailsForUnderlyingReceivedInvocations = newValue } }
    }
    var fetchDetailsForClosure: ((String) -> Void)?

    func fetchDetails(for eventID: String) {
        fetchDetailsForCallsCountLock.withLock { fetchDetailsForUnderlyingCallsCount += 1 }
        fetchDetailsForReceivedEventID = eventID
        fetchDetailsForReceivedInvocationsLock.withLock { fetchDetailsForUnderlyingReceivedInvocations.append(eventID) }
        fetchDetailsForClosure?(eventID)
    }
    //MARK: - messageEventContent

    private let messageEventContentForCallsCountLock = NSLock()
    private var messageEventContentForUnderlyingCallsCount = 0
    var messageEventContentForCallsCount: Int {
        get { messageEventContentForCallsCountLock.withLock { messageEventContentForUnderlyingCallsCount } }
        set { messageEventContentForCallsCountLock.withLock { messageEventContentForUnderlyingCallsCount = newValue } }
    }
    var messageEventContentForCalled: Bool {
        return messageEventContentForCallsCount > 0
    }
    private let messageEventContentForReceivedTimelineItemIDLock = NSLock()
    private var messageEventContentForUnderlyingReceivedTimelineItemID: TimelineItemIdentifier?
    var messageEventContentForReceivedTimelineItemID: TimelineItemIdentifier? {
        get { messageEventContentForReceivedTimelineItemIDLock.withLock { messageEventContentForUnderlyingReceivedTimelineItemID } }
        set { messageEventContentForReceivedTimelineItemIDLock.withLock { messageEventContentForUnderlyingReceivedTimelineItemID = newValue } }
    }
    private let messageEventContentForReceivedInvocationsLock = NSLock()
    private var messageEventContentForUnderlyingReceivedInvocations: [TimelineItemIdentifier] = []
    var messageEventContentForReceivedInvocations: [TimelineItemIdentifier] {
        get { messageEventContentForReceivedInvocationsLock.withLock { messageEventContentForUnderlyingReceivedInvocations } }
        set { messageEventContentForReceivedInvocationsLock.withLock { messageEventContentForUnderlyingReceivedInvocations = newValue } }
    }

    private let messageEventContentForReturnValueLock = NSLock()
    private var messageEventContentForUnderlyingReturnValue: RoomMessageEventContentWithoutRelation?
    var messageEventContentForReturnValue: RoomMessageEventContentWithoutRelation? {
        get { messageEventContentForReturnValueLock.withLock { messageEventContentForUnderlyingReturnValue } }
        set { messageEventContentForReturnValueLock.withLock { messageEventContentForUnderlyingReturnValue = newValue } }
    }
    var messageEventContentForClosure: ((TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?)?

    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation? {
        messageEventContentForCallsCountLock.withLock { messageEventContentForUnderlyingCallsCount += 1 }
        messageEventContentForReceivedTimelineItemID = timelineItemID
        messageEventContentForReceivedInvocationsLock.withLock { messageEventContentForUnderlyingReceivedInvocations.append(timelineItemID) }
        if let messageEventContentForClosure = messageEventContentForClosure {
            return await messageEventContentForClosure(timelineItemID)
        } else {
            return messageEventContentForReturnValue
        }
    }
    //MARK: - retryDecryption

    private let retryDecryptionSessionIDsCallsCountLock = NSLock()
    private var retryDecryptionSessionIDsUnderlyingCallsCount = 0
    var retryDecryptionSessionIDsCallsCount: Int {
        get { retryDecryptionSessionIDsCallsCountLock.withLock { retryDecryptionSessionIDsUnderlyingCallsCount } }
        set { retryDecryptionSessionIDsCallsCountLock.withLock { retryDecryptionSessionIDsUnderlyingCallsCount = newValue } }
    }
    var retryDecryptionSessionIDsCalled: Bool {
        return retryDecryptionSessionIDsCallsCount > 0
    }
    private let retryDecryptionSessionIDsReceivedSessionIDsLock = NSLock()
    private var retryDecryptionSessionIDsUnderlyingReceivedSessionIDs: [String]?
    var retryDecryptionSessionIDsReceivedSessionIDs: [String]? {
        get { retryDecryptionSessionIDsReceivedSessionIDsLock.withLock { retryDecryptionSessionIDsUnderlyingReceivedSessionIDs } }
        set { retryDecryptionSessionIDsReceivedSessionIDsLock.withLock { retryDecryptionSessionIDsUnderlyingReceivedSessionIDs = newValue } }
    }
    private let retryDecryptionSessionIDsReceivedInvocationsLock = NSLock()
    private var retryDecryptionSessionIDsUnderlyingReceivedInvocations: [[String]?] = []
    var retryDecryptionSessionIDsReceivedInvocations: [[String]?] {
        get { retryDecryptionSessionIDsReceivedInvocationsLock.withLock { retryDecryptionSessionIDsUnderlyingReceivedInvocations } }
        set { retryDecryptionSessionIDsReceivedInvocationsLock.withLock { retryDecryptionSessionIDsUnderlyingReceivedInvocations = newValue } }
    }
    var retryDecryptionSessionIDsClosure: (([String]?) -> Void)?

    func retryDecryption(sessionIDs: [String]?) {
        retryDecryptionSessionIDsCallsCountLock.withLock { retryDecryptionSessionIDsUnderlyingCallsCount += 1 }
        retryDecryptionSessionIDsReceivedSessionIDs = sessionIDs
        retryDecryptionSessionIDsReceivedInvocationsLock.withLock { retryDecryptionSessionIDsUnderlyingReceivedInvocations.append(sessionIDs) }
        retryDecryptionSessionIDsClosure?(sessionIDs)
    }
    //MARK: - paginateBackwards

    private let paginateBackwardsRequestSizeCallsCountLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingCallsCount = 0
    var paginateBackwardsRequestSizeCallsCount: Int {
        get { paginateBackwardsRequestSizeCallsCountLock.withLock { paginateBackwardsRequestSizeUnderlyingCallsCount } }
        set { paginateBackwardsRequestSizeCallsCountLock.withLock { paginateBackwardsRequestSizeUnderlyingCallsCount = newValue } }
    }
    var paginateBackwardsRequestSizeCalled: Bool {
        return paginateBackwardsRequestSizeCallsCount > 0
    }
    private let paginateBackwardsRequestSizeReceivedRequestSizeLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingReceivedRequestSize: UInt16?
    var paginateBackwardsRequestSizeReceivedRequestSize: UInt16? {
        get { paginateBackwardsRequestSizeReceivedRequestSizeLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedRequestSize } }
        set { paginateBackwardsRequestSizeReceivedRequestSizeLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedRequestSize = newValue } }
    }
    private let paginateBackwardsRequestSizeReceivedInvocationsLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingReceivedInvocations: [UInt16] = []
    var paginateBackwardsRequestSizeReceivedInvocations: [UInt16] {
        get { paginateBackwardsRequestSizeReceivedInvocationsLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedInvocations } }
        set { paginateBackwardsRequestSizeReceivedInvocationsLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let paginateBackwardsRequestSizeReturnValueLock = NSLock()
    private var paginateBackwardsRequestSizeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var paginateBackwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>! {
        get { paginateBackwardsRequestSizeReturnValueLock.withLock { paginateBackwardsRequestSizeUnderlyingReturnValue } }
        set { paginateBackwardsRequestSizeReturnValueLock.withLock { paginateBackwardsRequestSizeUnderlyingReturnValue = newValue } }
    }
    var paginateBackwardsRequestSizeClosure: ((UInt16) async -> Result<Void, TimelineProxyError>)?

    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        paginateBackwardsRequestSizeCallsCountLock.withLock { paginateBackwardsRequestSizeUnderlyingCallsCount += 1 }
        paginateBackwardsRequestSizeReceivedRequestSize = requestSize
        paginateBackwardsRequestSizeReceivedInvocationsLock.withLock { paginateBackwardsRequestSizeUnderlyingReceivedInvocations.append(requestSize) }
        if let paginateBackwardsRequestSizeClosure = paginateBackwardsRequestSizeClosure {
            return await paginateBackwardsRequestSizeClosure(requestSize)
        } else {
            return paginateBackwardsRequestSizeReturnValue
        }
    }
    //MARK: - paginateForwards

    private let paginateForwardsRequestSizeCallsCountLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingCallsCount = 0
    var paginateForwardsRequestSizeCallsCount: Int {
        get { paginateForwardsRequestSizeCallsCountLock.withLock { paginateForwardsRequestSizeUnderlyingCallsCount } }
        set { paginateForwardsRequestSizeCallsCountLock.withLock { paginateForwardsRequestSizeUnderlyingCallsCount = newValue } }
    }
    var paginateForwardsRequestSizeCalled: Bool {
        return paginateForwardsRequestSizeCallsCount > 0
    }
    private let paginateForwardsRequestSizeReceivedRequestSizeLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingReceivedRequestSize: UInt16?
    var paginateForwardsRequestSizeReceivedRequestSize: UInt16? {
        get { paginateForwardsRequestSizeReceivedRequestSizeLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedRequestSize } }
        set { paginateForwardsRequestSizeReceivedRequestSizeLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedRequestSize = newValue } }
    }
    private let paginateForwardsRequestSizeReceivedInvocationsLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingReceivedInvocations: [UInt16] = []
    var paginateForwardsRequestSizeReceivedInvocations: [UInt16] {
        get { paginateForwardsRequestSizeReceivedInvocationsLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedInvocations } }
        set { paginateForwardsRequestSizeReceivedInvocationsLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedInvocations = newValue } }
    }

    private let paginateForwardsRequestSizeReturnValueLock = NSLock()
    private var paginateForwardsRequestSizeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var paginateForwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>! {
        get { paginateForwardsRequestSizeReturnValueLock.withLock { paginateForwardsRequestSizeUnderlyingReturnValue } }
        set { paginateForwardsRequestSizeReturnValueLock.withLock { paginateForwardsRequestSizeUnderlyingReturnValue = newValue } }
    }
    var paginateForwardsRequestSizeClosure: ((UInt16) async -> Result<Void, TimelineProxyError>)?

    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        paginateForwardsRequestSizeCallsCountLock.withLock { paginateForwardsRequestSizeUnderlyingCallsCount += 1 }
        paginateForwardsRequestSizeReceivedRequestSize = requestSize
        paginateForwardsRequestSizeReceivedInvocationsLock.withLock { paginateForwardsRequestSizeUnderlyingReceivedInvocations.append(requestSize) }
        if let paginateForwardsRequestSizeClosure = paginateForwardsRequestSizeClosure {
            return await paginateForwardsRequestSizeClosure(requestSize)
        } else {
            return paginateForwardsRequestSizeReturnValue
        }
    }
    //MARK: - edit

    private let editNewContentCallsCountLock = NSLock()
    private var editNewContentUnderlyingCallsCount = 0
    var editNewContentCallsCount: Int {
        get { editNewContentCallsCountLock.withLock { editNewContentUnderlyingCallsCount } }
        set { editNewContentCallsCountLock.withLock { editNewContentUnderlyingCallsCount = newValue } }
    }
    var editNewContentCalled: Bool {
        return editNewContentCallsCount > 0
    }
    private let editNewContentReceivedArgumentsLock = NSLock()
    private var editNewContentUnderlyingReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent)?
    var editNewContentReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent)? {
        get { editNewContentReceivedArgumentsLock.withLock { editNewContentUnderlyingReceivedArguments } }
        set { editNewContentReceivedArgumentsLock.withLock { editNewContentUnderlyingReceivedArguments = newValue } }
    }
    private let editNewContentReceivedInvocationsLock = NSLock()
    private var editNewContentUnderlyingReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent)] = []
    var editNewContentReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent)] {
        get { editNewContentReceivedInvocationsLock.withLock { editNewContentUnderlyingReceivedInvocations } }
        set { editNewContentReceivedInvocationsLock.withLock { editNewContentUnderlyingReceivedInvocations = newValue } }
    }

    private let editNewContentReturnValueLock = NSLock()
    private var editNewContentUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var editNewContentReturnValue: Result<Void, TimelineProxyError>! {
        get { editNewContentReturnValueLock.withLock { editNewContentUnderlyingReturnValue } }
        set { editNewContentReturnValueLock.withLock { editNewContentUnderlyingReturnValue = newValue } }
    }
    var editNewContentClosure: ((TimelineItemIdentifier.EventOrTransactionID, EditedContent) async -> Result<Void, TimelineProxyError>)?

    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent) async -> Result<Void, TimelineProxyError> {
        editNewContentCallsCountLock.withLock { editNewContentUnderlyingCallsCount += 1 }
        editNewContentReceivedArguments = (eventOrTransactionID: eventOrTransactionID, newContent: newContent)
        editNewContentReceivedInvocationsLock.withLock { editNewContentUnderlyingReceivedInvocations.append((eventOrTransactionID: eventOrTransactionID, newContent: newContent)) }
        if let editNewContentClosure = editNewContentClosure {
            return await editNewContentClosure(eventOrTransactionID, newContent)
        } else {
            return editNewContentReturnValue
        }
    }
    //MARK: - redact

    private let redactReasonCallsCountLock = NSLock()
    private var redactReasonUnderlyingCallsCount = 0
    var redactReasonCallsCount: Int {
        get { redactReasonCallsCountLock.withLock { redactReasonUnderlyingCallsCount } }
        set { redactReasonCallsCountLock.withLock { redactReasonUnderlyingCallsCount = newValue } }
    }
    var redactReasonCalled: Bool {
        return redactReasonCallsCount > 0
    }
    private let redactReasonReceivedArgumentsLock = NSLock()
    private var redactReasonUnderlyingReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?)?
    var redactReasonReceivedArguments: (eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?)? {
        get { redactReasonReceivedArgumentsLock.withLock { redactReasonUnderlyingReceivedArguments } }
        set { redactReasonReceivedArgumentsLock.withLock { redactReasonUnderlyingReceivedArguments = newValue } }
    }
    private let redactReasonReceivedInvocationsLock = NSLock()
    private var redactReasonUnderlyingReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?)] = []
    var redactReasonReceivedInvocations: [(eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?)] {
        get { redactReasonReceivedInvocationsLock.withLock { redactReasonUnderlyingReceivedInvocations } }
        set { redactReasonReceivedInvocationsLock.withLock { redactReasonUnderlyingReceivedInvocations = newValue } }
    }

    private let redactReasonReturnValueLock = NSLock()
    private var redactReasonUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var redactReasonReturnValue: Result<Void, TimelineProxyError>! {
        get { redactReasonReturnValueLock.withLock { redactReasonUnderlyingReturnValue } }
        set { redactReasonReturnValueLock.withLock { redactReasonUnderlyingReturnValue = newValue } }
    }
    var redactReasonClosure: ((TimelineItemIdentifier.EventOrTransactionID, String?) async -> Result<Void, TimelineProxyError>)?

    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?) async -> Result<Void, TimelineProxyError> {
        redactReasonCallsCountLock.withLock { redactReasonUnderlyingCallsCount += 1 }
        redactReasonReceivedArguments = (eventOrTransactionID: eventOrTransactionID, reason: reason)
        redactReasonReceivedInvocationsLock.withLock { redactReasonUnderlyingReceivedInvocations.append((eventOrTransactionID: eventOrTransactionID, reason: reason)) }
        if let redactReasonClosure = redactReasonClosure {
            return await redactReasonClosure(eventOrTransactionID, reason)
        } else {
            return redactReasonReturnValue
        }
    }
    //MARK: - pin

    private let pinEventIDCallsCountLock = NSLock()
    private var pinEventIDUnderlyingCallsCount = 0
    var pinEventIDCallsCount: Int {
        get { pinEventIDCallsCountLock.withLock { pinEventIDUnderlyingCallsCount } }
        set { pinEventIDCallsCountLock.withLock { pinEventIDUnderlyingCallsCount = newValue } }
    }
    var pinEventIDCalled: Bool {
        return pinEventIDCallsCount > 0
    }
    private let pinEventIDReceivedEventIDLock = NSLock()
    private var pinEventIDUnderlyingReceivedEventID: String?
    var pinEventIDReceivedEventID: String? {
        get { pinEventIDReceivedEventIDLock.withLock { pinEventIDUnderlyingReceivedEventID } }
        set { pinEventIDReceivedEventIDLock.withLock { pinEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let pinEventIDReceivedInvocationsLock = NSLock()
    private var pinEventIDUnderlyingReceivedInvocations: [String] = []
    var pinEventIDReceivedInvocations: [String] {
        get { pinEventIDReceivedInvocationsLock.withLock { pinEventIDUnderlyingReceivedInvocations } }
        set { pinEventIDReceivedInvocationsLock.withLock { pinEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let pinEventIDReturnValueLock = NSLock()
    private var pinEventIDUnderlyingReturnValue: Result<Bool, TimelineProxyError>!
    var pinEventIDReturnValue: Result<Bool, TimelineProxyError>! {
        get { pinEventIDReturnValueLock.withLock { pinEventIDUnderlyingReturnValue } }
        set { pinEventIDReturnValueLock.withLock { pinEventIDUnderlyingReturnValue = newValue } }
    }
    var pinEventIDClosure: ((String) async -> Result<Bool, TimelineProxyError>)?

    func pin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        pinEventIDCallsCountLock.withLock { pinEventIDUnderlyingCallsCount += 1 }
        pinEventIDReceivedEventID = eventID
        pinEventIDReceivedInvocationsLock.withLock { pinEventIDUnderlyingReceivedInvocations.append(eventID) }
        if let pinEventIDClosure = pinEventIDClosure {
            return await pinEventIDClosure(eventID)
        } else {
            return pinEventIDReturnValue
        }
    }
    //MARK: - unpin

    private let unpinEventIDCallsCountLock = NSLock()
    private var unpinEventIDUnderlyingCallsCount = 0
    var unpinEventIDCallsCount: Int {
        get { unpinEventIDCallsCountLock.withLock { unpinEventIDUnderlyingCallsCount } }
        set { unpinEventIDCallsCountLock.withLock { unpinEventIDUnderlyingCallsCount = newValue } }
    }
    var unpinEventIDCalled: Bool {
        return unpinEventIDCallsCount > 0
    }
    private let unpinEventIDReceivedEventIDLock = NSLock()
    private var unpinEventIDUnderlyingReceivedEventID: String?
    var unpinEventIDReceivedEventID: String? {
        get { unpinEventIDReceivedEventIDLock.withLock { unpinEventIDUnderlyingReceivedEventID } }
        set { unpinEventIDReceivedEventIDLock.withLock { unpinEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let unpinEventIDReceivedInvocationsLock = NSLock()
    private var unpinEventIDUnderlyingReceivedInvocations: [String] = []
    var unpinEventIDReceivedInvocations: [String] {
        get { unpinEventIDReceivedInvocationsLock.withLock { unpinEventIDUnderlyingReceivedInvocations } }
        set { unpinEventIDReceivedInvocationsLock.withLock { unpinEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let unpinEventIDReturnValueLock = NSLock()
    private var unpinEventIDUnderlyingReturnValue: Result<Bool, TimelineProxyError>!
    var unpinEventIDReturnValue: Result<Bool, TimelineProxyError>! {
        get { unpinEventIDReturnValueLock.withLock { unpinEventIDUnderlyingReturnValue } }
        set { unpinEventIDReturnValueLock.withLock { unpinEventIDUnderlyingReturnValue = newValue } }
    }
    var unpinEventIDClosure: ((String) async -> Result<Bool, TimelineProxyError>)?

    func unpin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        unpinEventIDCallsCountLock.withLock { unpinEventIDUnderlyingCallsCount += 1 }
        unpinEventIDReceivedEventID = eventID
        unpinEventIDReceivedInvocationsLock.withLock { unpinEventIDUnderlyingReceivedInvocations.append(eventID) }
        if let unpinEventIDClosure = unpinEventIDClosure {
            return await unpinEventIDClosure(eventID)
        } else {
            return unpinEventIDReturnValue
        }
    }
    //MARK: - sendAudio

    private let sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendAudioUrlAudioInfoCaptionRequestHandleCallsCount: Int {
        get { sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendAudioUrlAudioInfoCaptionRequestHandleCalled: Bool {
        return sendAudioUrlAudioInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendAudioUrlAudioInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendAudioUrlAudioInfoCaptionRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get { sendAudioUrlAudioInfoCaptionRequestHandleReturnValueLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendAudioUrlAudioInfoCaptionRequestHandleReturnValueLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendAudioUrlAudioInfoCaptionRequestHandleClosure: ((URL, AudioInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendAudio(url: URL, audioInfo: AudioInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendAudioUrlAudioInfoCaptionRequestHandleCallsCountLock.withLock { sendAudioUrlAudioInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendAudioUrlAudioInfoCaptionRequestHandleClosure = sendAudioUrlAudioInfoCaptionRequestHandleClosure {
            return await sendAudioUrlAudioInfoCaptionRequestHandleClosure(url, audioInfo, caption, requestHandle)
        } else {
            return sendAudioUrlAudioInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendFile

    private let sendFileUrlFileInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendFileUrlFileInfoCaptionRequestHandleCallsCount: Int {
        get { sendFileUrlFileInfoCaptionRequestHandleCallsCountLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendFileUrlFileInfoCaptionRequestHandleCallsCountLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendFileUrlFileInfoCaptionRequestHandleCalled: Bool {
        return sendFileUrlFileInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendFileUrlFileInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendFileUrlFileInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendFileUrlFileInfoCaptionRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get { sendFileUrlFileInfoCaptionRequestHandleReturnValueLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendFileUrlFileInfoCaptionRequestHandleReturnValueLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendFileUrlFileInfoCaptionRequestHandleClosure: ((URL, FileInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendFile(url: URL, fileInfo: FileInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendFileUrlFileInfoCaptionRequestHandleCallsCountLock.withLock { sendFileUrlFileInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendFileUrlFileInfoCaptionRequestHandleClosure = sendFileUrlFileInfoCaptionRequestHandleClosure {
            return await sendFileUrlFileInfoCaptionRequestHandleClosure(url, fileInfo, caption, requestHandle)
        } else {
            return sendFileUrlFileInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendImage

    private let sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCount: Int {
        get { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCalled: Bool {
        return sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValueLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValueLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure: ((URL, URL, ImageInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCountLock.withLock { sendImageUrlThumbnailURLImageInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure = sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure {
            return await sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure(url, thumbnailURL, imageInfo, caption, requestHandle)
        } else {
            return sendImageUrlThumbnailURLImageInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendLocation

    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = 0
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount: Int {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount = newValue } }
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCalled: Bool {
        return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCount > 0
    }
    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArgumentsLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)?
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments: (body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)? {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArgumentsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedArguments } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArgumentsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedArguments = newValue } }
    }
    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] = []
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocations: [(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?)] {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations = newValue } }
    }

    private let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValueLock = NSLock()
    private var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue: Result<Void, TimelineProxyError>! {
        get { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValueLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue } }
        set { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValueLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReturnValue = newValue } }
    }
    var sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure: ((String, GeoURI, String?, UInt8?, AssetType?) async -> Result<Void, TimelineProxyError>)?

    func sendLocation(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async -> Result<Void, TimelineProxyError> {
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeCallsCountLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingCallsCount += 1 }
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedArguments = (body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)
        sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReceivedInvocationsLock.withLock { sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeUnderlyingReceivedInvocations.append((body: body, geoURI: geoURI, description: description, zoomLevel: zoomLevel, assetType: assetType)) }
        if let sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure = sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure {
            return await sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeClosure(body, geoURI, description, zoomLevel, assetType)
        } else {
            return sendLocationBodyGeoURIDescriptionZoomLevelAssetTypeReturnValue
        }
    }
    //MARK: - sendVideo

    private let sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock = NSLock()
    private var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount = 0
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCount: Int {
        get { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount } }
        set { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCalled: Bool {
        return sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCount > 0
    }

    private let sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValueLock = NSLock()
    private var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValueLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingReturnValue } }
        set { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValueLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure: ((URL, URL, VideoInfo, String?, @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleCallsCountLock.withLock { sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleUnderlyingCallsCount += 1 }
        if let sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure = sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure {
            return await sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure(url, thumbnailURL, videoInfo, caption, requestHandle)
        } else {
            return sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleReturnValue
        }
    }
    //MARK: - sendVoiceMessage

    private let sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock = NSLock()
    private var sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount = 0
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCount: Int {
        get { sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount } }
        set { sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount = newValue } }
    }
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleCalled: Bool {
        return sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCount > 0
    }

    private let sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValueLock = NSLock()
    private var sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue: Result<Void, TimelineProxyError>! {
        get { sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValueLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingReturnValue } }
        set { sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValueLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingReturnValue = newValue } }
    }
    var sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure: ((URL, AudioInfo, [Float], @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>)?

    func sendVoiceMessage(url: URL, audioInfo: AudioInfo, waveform: [Float], requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendVoiceMessageUrlAudioInfoWaveformRequestHandleCallsCountLock.withLock { sendVoiceMessageUrlAudioInfoWaveformRequestHandleUnderlyingCallsCount += 1 }
        if let sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure = sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure {
            return await sendVoiceMessageUrlAudioInfoWaveformRequestHandleClosure(url, audioInfo, waveform, requestHandle)
        } else {
            return sendVoiceMessageUrlAudioInfoWaveformRequestHandleReturnValue
        }
    }
    //MARK: - sendReadReceipt

    private let sendReadReceiptForTypeCallsCountLock = NSLock()
    private var sendReadReceiptForTypeUnderlyingCallsCount = 0
    var sendReadReceiptForTypeCallsCount: Int {
        get { sendReadReceiptForTypeCallsCountLock.withLock { sendReadReceiptForTypeUnderlyingCallsCount } }
        set { sendReadReceiptForTypeCallsCountLock.withLock { sendReadReceiptForTypeUnderlyingCallsCount = newValue } }
    }
    var sendReadReceiptForTypeCalled: Bool {
        return sendReadReceiptForTypeCallsCount > 0
    }
    private let sendReadReceiptForTypeReceivedArgumentsLock = NSLock()
    private var sendReadReceiptForTypeUnderlyingReceivedArguments: (eventID: String, type: ReceiptType)?
    var sendReadReceiptForTypeReceivedArguments: (eventID: String, type: ReceiptType)? {
        get { sendReadReceiptForTypeReceivedArgumentsLock.withLock { sendReadReceiptForTypeUnderlyingReceivedArguments } }
        set { sendReadReceiptForTypeReceivedArgumentsLock.withLock { sendReadReceiptForTypeUnderlyingReceivedArguments = newValue } }
    }
    private let sendReadReceiptForTypeReceivedInvocationsLock = NSLock()
    private var sendReadReceiptForTypeUnderlyingReceivedInvocations: [(eventID: String, type: ReceiptType)] = []
    var sendReadReceiptForTypeReceivedInvocations: [(eventID: String, type: ReceiptType)] {
        get { sendReadReceiptForTypeReceivedInvocationsLock.withLock { sendReadReceiptForTypeUnderlyingReceivedInvocations } }
        set { sendReadReceiptForTypeReceivedInvocationsLock.withLock { sendReadReceiptForTypeUnderlyingReceivedInvocations = newValue } }
    }

    private let sendReadReceiptForTypeReturnValueLock = NSLock()
    private var sendReadReceiptForTypeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendReadReceiptForTypeReturnValue: Result<Void, TimelineProxyError>! {
        get { sendReadReceiptForTypeReturnValueLock.withLock { sendReadReceiptForTypeUnderlyingReturnValue } }
        set { sendReadReceiptForTypeReturnValueLock.withLock { sendReadReceiptForTypeUnderlyingReturnValue = newValue } }
    }
    var sendReadReceiptForTypeClosure: ((String, ReceiptType) async -> Result<Void, TimelineProxyError>)?

    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError> {
        sendReadReceiptForTypeCallsCountLock.withLock { sendReadReceiptForTypeUnderlyingCallsCount += 1 }
        sendReadReceiptForTypeReceivedArguments = (eventID: eventID, type: type)
        sendReadReceiptForTypeReceivedInvocationsLock.withLock { sendReadReceiptForTypeUnderlyingReceivedInvocations.append((eventID: eventID, type: type)) }
        if let sendReadReceiptForTypeClosure = sendReadReceiptForTypeClosure {
            return await sendReadReceiptForTypeClosure(eventID, type)
        } else {
            return sendReadReceiptForTypeReturnValue
        }
    }
    //MARK: - markAsRead

    private let markAsReadReceiptTypeCallsCountLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingCallsCount = 0
    var markAsReadReceiptTypeCallsCount: Int {
        get { markAsReadReceiptTypeCallsCountLock.withLock { markAsReadReceiptTypeUnderlyingCallsCount } }
        set { markAsReadReceiptTypeCallsCountLock.withLock { markAsReadReceiptTypeUnderlyingCallsCount = newValue } }
    }
    var markAsReadReceiptTypeCalled: Bool {
        return markAsReadReceiptTypeCallsCount > 0
    }
    private let markAsReadReceiptTypeReceivedReceiptTypeLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingReceivedReceiptType: ReceiptType?
    var markAsReadReceiptTypeReceivedReceiptType: ReceiptType? {
        get { markAsReadReceiptTypeReceivedReceiptTypeLock.withLock { markAsReadReceiptTypeUnderlyingReceivedReceiptType } }
        set { markAsReadReceiptTypeReceivedReceiptTypeLock.withLock { markAsReadReceiptTypeUnderlyingReceivedReceiptType = newValue } }
    }
    private let markAsReadReceiptTypeReceivedInvocationsLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingReceivedInvocations: [ReceiptType] = []
    var markAsReadReceiptTypeReceivedInvocations: [ReceiptType] {
        get { markAsReadReceiptTypeReceivedInvocationsLock.withLock { markAsReadReceiptTypeUnderlyingReceivedInvocations } }
        set { markAsReadReceiptTypeReceivedInvocationsLock.withLock { markAsReadReceiptTypeUnderlyingReceivedInvocations = newValue } }
    }

    private let markAsReadReceiptTypeReturnValueLock = NSLock()
    private var markAsReadReceiptTypeUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var markAsReadReceiptTypeReturnValue: Result<Void, TimelineProxyError>! {
        get { markAsReadReceiptTypeReturnValueLock.withLock { markAsReadReceiptTypeUnderlyingReturnValue } }
        set { markAsReadReceiptTypeReturnValueLock.withLock { markAsReadReceiptTypeUnderlyingReturnValue = newValue } }
    }
    var markAsReadReceiptTypeClosure: ((ReceiptType) async -> Result<Void, TimelineProxyError>)?

    func markAsRead(receiptType: ReceiptType) async -> Result<Void, TimelineProxyError> {
        markAsReadReceiptTypeCallsCountLock.withLock { markAsReadReceiptTypeUnderlyingCallsCount += 1 }
        markAsReadReceiptTypeReceivedReceiptType = receiptType
        markAsReadReceiptTypeReceivedInvocationsLock.withLock { markAsReadReceiptTypeUnderlyingReceivedInvocations.append(receiptType) }
        if let markAsReadReceiptTypeClosure = markAsReadReceiptTypeClosure {
            return await markAsReadReceiptTypeClosure(receiptType)
        } else {
            return markAsReadReceiptTypeReturnValue
        }
    }
    //MARK: - sendMessageEventContent

    private let sendMessageEventContentCallsCountLock = NSLock()
    private var sendMessageEventContentUnderlyingCallsCount = 0
    var sendMessageEventContentCallsCount: Int {
        get { sendMessageEventContentCallsCountLock.withLock { sendMessageEventContentUnderlyingCallsCount } }
        set { sendMessageEventContentCallsCountLock.withLock { sendMessageEventContentUnderlyingCallsCount = newValue } }
    }
    var sendMessageEventContentCalled: Bool {
        return sendMessageEventContentCallsCount > 0
    }
    private let sendMessageEventContentReceivedMessageContentLock = NSLock()
    private var sendMessageEventContentUnderlyingReceivedMessageContent: RoomMessageEventContentWithoutRelation?
    var sendMessageEventContentReceivedMessageContent: RoomMessageEventContentWithoutRelation? {
        get { sendMessageEventContentReceivedMessageContentLock.withLock { sendMessageEventContentUnderlyingReceivedMessageContent } }
        set { sendMessageEventContentReceivedMessageContentLock.withLock { sendMessageEventContentUnderlyingReceivedMessageContent = newValue } }
    }
    private let sendMessageEventContentReceivedInvocationsLock = NSLock()
    private var sendMessageEventContentUnderlyingReceivedInvocations: [RoomMessageEventContentWithoutRelation] = []
    var sendMessageEventContentReceivedInvocations: [RoomMessageEventContentWithoutRelation] {
        get { sendMessageEventContentReceivedInvocationsLock.withLock { sendMessageEventContentUnderlyingReceivedInvocations } }
        set { sendMessageEventContentReceivedInvocationsLock.withLock { sendMessageEventContentUnderlyingReceivedInvocations = newValue } }
    }

    private let sendMessageEventContentReturnValueLock = NSLock()
    private var sendMessageEventContentUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendMessageEventContentReturnValue: Result<Void, TimelineProxyError>! {
        get { sendMessageEventContentReturnValueLock.withLock { sendMessageEventContentUnderlyingReturnValue } }
        set { sendMessageEventContentReturnValueLock.withLock { sendMessageEventContentUnderlyingReturnValue = newValue } }
    }
    var sendMessageEventContentClosure: ((RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>)?

    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        sendMessageEventContentCallsCountLock.withLock { sendMessageEventContentUnderlyingCallsCount += 1 }
        sendMessageEventContentReceivedMessageContent = messageContent
        sendMessageEventContentReceivedInvocationsLock.withLock { sendMessageEventContentUnderlyingReceivedInvocations.append(messageContent) }
        if let sendMessageEventContentClosure = sendMessageEventContentClosure {
            return await sendMessageEventContentClosure(messageContent)
        } else {
            return sendMessageEventContentReturnValue
        }
    }
    //MARK: - sendMessage

    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount = 0
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCount: Int {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount = newValue } }
    }
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsCalled: Bool {
        return sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCount > 0
    }
    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArgumentsLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedArguments: (message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)?
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArguments: (message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)? {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArgumentsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedArguments } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArgumentsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedArguments = newValue } }
    }
    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations: [(message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)] = []
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocations: [(message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions)] {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations = newValue } }
    }

    private let sendMessageHtmlInReplyToEventIDIntentionalMentionsReturnValueLock = NSLock()
    private var sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsReturnValue: Result<Void, TimelineProxyError>! {
        get { sendMessageHtmlInReplyToEventIDIntentionalMentionsReturnValueLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReturnValue } }
        set { sendMessageHtmlInReplyToEventIDIntentionalMentionsReturnValueLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReturnValue = newValue } }
    }
    var sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure: ((String, String?, String?, IntentionalMentions) async -> Result<Void, TimelineProxyError>)?

    func sendMessage(_ message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        sendMessageHtmlInReplyToEventIDIntentionalMentionsCallsCountLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingCallsCount += 1 }
        sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedArguments = (message: message, html: html, inReplyToEventID: inReplyToEventID, intentionalMentions: intentionalMentions)
        sendMessageHtmlInReplyToEventIDIntentionalMentionsReceivedInvocationsLock.withLock { sendMessageHtmlInReplyToEventIDIntentionalMentionsUnderlyingReceivedInvocations.append((message: message, html: html, inReplyToEventID: inReplyToEventID, intentionalMentions: intentionalMentions)) }
        if let sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure = sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure {
            return await sendMessageHtmlInReplyToEventIDIntentionalMentionsClosure(message, html, inReplyToEventID, intentionalMentions)
        } else {
            return sendMessageHtmlInReplyToEventIDIntentionalMentionsReturnValue
        }
    }
    //MARK: - toggleReaction

    private let toggleReactionToCallsCountLock = NSLock()
    private var toggleReactionToUnderlyingCallsCount = 0
    var toggleReactionToCallsCount: Int {
        get { toggleReactionToCallsCountLock.withLock { toggleReactionToUnderlyingCallsCount } }
        set { toggleReactionToCallsCountLock.withLock { toggleReactionToUnderlyingCallsCount = newValue } }
    }
    var toggleReactionToCalled: Bool {
        return toggleReactionToCallsCount > 0
    }
    private let toggleReactionToReceivedArgumentsLock = NSLock()
    private var toggleReactionToUnderlyingReceivedArguments: (reaction: String, eventID: TimelineItemIdentifier.EventOrTransactionID)?
    var toggleReactionToReceivedArguments: (reaction: String, eventID: TimelineItemIdentifier.EventOrTransactionID)? {
        get { toggleReactionToReceivedArgumentsLock.withLock { toggleReactionToUnderlyingReceivedArguments } }
        set { toggleReactionToReceivedArgumentsLock.withLock { toggleReactionToUnderlyingReceivedArguments = newValue } }
    }
    private let toggleReactionToReceivedInvocationsLock = NSLock()
    private var toggleReactionToUnderlyingReceivedInvocations: [(reaction: String, eventID: TimelineItemIdentifier.EventOrTransactionID)] = []
    var toggleReactionToReceivedInvocations: [(reaction: String, eventID: TimelineItemIdentifier.EventOrTransactionID)] {
        get { toggleReactionToReceivedInvocationsLock.withLock { toggleReactionToUnderlyingReceivedInvocations } }
        set { toggleReactionToReceivedInvocationsLock.withLock { toggleReactionToUnderlyingReceivedInvocations = newValue } }
    }

    private let toggleReactionToReturnValueLock = NSLock()
    private var toggleReactionToUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var toggleReactionToReturnValue: Result<Void, TimelineProxyError>! {
        get { toggleReactionToReturnValueLock.withLock { toggleReactionToUnderlyingReturnValue } }
        set { toggleReactionToReturnValueLock.withLock { toggleReactionToUnderlyingReturnValue = newValue } }
    }
    var toggleReactionToClosure: ((String, TimelineItemIdentifier.EventOrTransactionID) async -> Result<Void, TimelineProxyError>)?

    func toggleReaction(_ reaction: String, to eventID: TimelineItemIdentifier.EventOrTransactionID) async -> Result<Void, TimelineProxyError> {
        toggleReactionToCallsCountLock.withLock { toggleReactionToUnderlyingCallsCount += 1 }
        toggleReactionToReceivedArguments = (reaction: reaction, eventID: eventID)
        toggleReactionToReceivedInvocationsLock.withLock { toggleReactionToUnderlyingReceivedInvocations.append((reaction: reaction, eventID: eventID)) }
        if let toggleReactionToClosure = toggleReactionToClosure {
            return await toggleReactionToClosure(reaction, eventID)
        } else {
            return toggleReactionToReturnValue
        }
    }
    //MARK: - createPoll

    private let createPollQuestionAnswersPollKindCallsCountLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingCallsCount = 0
    var createPollQuestionAnswersPollKindCallsCount: Int {
        get { createPollQuestionAnswersPollKindCallsCountLock.withLock { createPollQuestionAnswersPollKindUnderlyingCallsCount } }
        set { createPollQuestionAnswersPollKindCallsCountLock.withLock { createPollQuestionAnswersPollKindUnderlyingCallsCount = newValue } }
    }
    var createPollQuestionAnswersPollKindCalled: Bool {
        return createPollQuestionAnswersPollKindCallsCount > 0
    }
    private let createPollQuestionAnswersPollKindReceivedArgumentsLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)?
    var createPollQuestionAnswersPollKindReceivedArguments: (question: String, answers: [String], pollKind: Poll.Kind)? {
        get { createPollQuestionAnswersPollKindReceivedArgumentsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedArguments } }
        set { createPollQuestionAnswersPollKindReceivedArgumentsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedArguments = newValue } }
    }
    private let createPollQuestionAnswersPollKindReceivedInvocationsLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] = []
    var createPollQuestionAnswersPollKindReceivedInvocations: [(question: String, answers: [String], pollKind: Poll.Kind)] {
        get { createPollQuestionAnswersPollKindReceivedInvocationsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedInvocations } }
        set { createPollQuestionAnswersPollKindReceivedInvocationsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedInvocations = newValue } }
    }

    private let createPollQuestionAnswersPollKindReturnValueLock = NSLock()
    private var createPollQuestionAnswersPollKindUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var createPollQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>! {
        get { createPollQuestionAnswersPollKindReturnValueLock.withLock { createPollQuestionAnswersPollKindUnderlyingReturnValue } }
        set { createPollQuestionAnswersPollKindReturnValueLock.withLock { createPollQuestionAnswersPollKindUnderlyingReturnValue = newValue } }
    }
    var createPollQuestionAnswersPollKindClosure: ((String, [String], Poll.Kind) async -> Result<Void, TimelineProxyError>)?

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        createPollQuestionAnswersPollKindCallsCountLock.withLock { createPollQuestionAnswersPollKindUnderlyingCallsCount += 1 }
        createPollQuestionAnswersPollKindReceivedArguments = (question: question, answers: answers, pollKind: pollKind)
        createPollQuestionAnswersPollKindReceivedInvocationsLock.withLock { createPollQuestionAnswersPollKindUnderlyingReceivedInvocations.append((question: question, answers: answers, pollKind: pollKind)) }
        if let createPollQuestionAnswersPollKindClosure = createPollQuestionAnswersPollKindClosure {
            return await createPollQuestionAnswersPollKindClosure(question, answers, pollKind)
        } else {
            return createPollQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - editPoll

    private let editPollOriginalQuestionAnswersPollKindCallsCountLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = 0
    var editPollOriginalQuestionAnswersPollKindCallsCount: Int {
        get { editPollOriginalQuestionAnswersPollKindCallsCountLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount } }
        set { editPollOriginalQuestionAnswersPollKindCallsCountLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount = newValue } }
    }
    var editPollOriginalQuestionAnswersPollKindCalled: Bool {
        return editPollOriginalQuestionAnswersPollKindCallsCount > 0
    }
    private let editPollOriginalQuestionAnswersPollKindReceivedArgumentsLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingReceivedArguments: (eventID: String, question: String, answers: [String], pollKind: Poll.Kind)?
    var editPollOriginalQuestionAnswersPollKindReceivedArguments: (eventID: String, question: String, answers: [String], pollKind: Poll.Kind)? {
        get { editPollOriginalQuestionAnswersPollKindReceivedArgumentsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedArguments } }
        set { editPollOriginalQuestionAnswersPollKindReceivedArgumentsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedArguments = newValue } }
    }
    private let editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations: [(eventID: String, question: String, answers: [String], pollKind: Poll.Kind)] = []
    var editPollOriginalQuestionAnswersPollKindReceivedInvocations: [(eventID: String, question: String, answers: [String], pollKind: Poll.Kind)] {
        get { editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations } }
        set { editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations = newValue } }
    }

    private let editPollOriginalQuestionAnswersPollKindReturnValueLock = NSLock()
    private var editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var editPollOriginalQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>! {
        get { editPollOriginalQuestionAnswersPollKindReturnValueLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue } }
        set { editPollOriginalQuestionAnswersPollKindReturnValueLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReturnValue = newValue } }
    }
    var editPollOriginalQuestionAnswersPollKindClosure: ((String, String, [String], Poll.Kind) async -> Result<Void, TimelineProxyError>)?

    func editPoll(original eventID: String, question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        editPollOriginalQuestionAnswersPollKindCallsCountLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingCallsCount += 1 }
        editPollOriginalQuestionAnswersPollKindReceivedArguments = (eventID: eventID, question: question, answers: answers, pollKind: pollKind)
        editPollOriginalQuestionAnswersPollKindReceivedInvocationsLock.withLock { editPollOriginalQuestionAnswersPollKindUnderlyingReceivedInvocations.append((eventID: eventID, question: question, answers: answers, pollKind: pollKind)) }
        if let editPollOriginalQuestionAnswersPollKindClosure = editPollOriginalQuestionAnswersPollKindClosure {
            return await editPollOriginalQuestionAnswersPollKindClosure(eventID, question, answers, pollKind)
        } else {
            return editPollOriginalQuestionAnswersPollKindReturnValue
        }
    }
    //MARK: - sendPollResponse

    private let sendPollResponsePollStartIDAnswersCallsCountLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingCallsCount = 0
    var sendPollResponsePollStartIDAnswersCallsCount: Int {
        get { sendPollResponsePollStartIDAnswersCallsCountLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingCallsCount } }
        set { sendPollResponsePollStartIDAnswersCallsCountLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingCallsCount = newValue } }
    }
    var sendPollResponsePollStartIDAnswersCalled: Bool {
        return sendPollResponsePollStartIDAnswersCallsCount > 0
    }
    private let sendPollResponsePollStartIDAnswersReceivedArgumentsLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingReceivedArguments: (pollStartID: String, answers: [String])?
    var sendPollResponsePollStartIDAnswersReceivedArguments: (pollStartID: String, answers: [String])? {
        get { sendPollResponsePollStartIDAnswersReceivedArgumentsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedArguments } }
        set { sendPollResponsePollStartIDAnswersReceivedArgumentsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedArguments = newValue } }
    }
    private let sendPollResponsePollStartIDAnswersReceivedInvocationsLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations: [(pollStartID: String, answers: [String])] = []
    var sendPollResponsePollStartIDAnswersReceivedInvocations: [(pollStartID: String, answers: [String])] {
        get { sendPollResponsePollStartIDAnswersReceivedInvocationsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations } }
        set { sendPollResponsePollStartIDAnswersReceivedInvocationsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations = newValue } }
    }

    private let sendPollResponsePollStartIDAnswersReturnValueLock = NSLock()
    private var sendPollResponsePollStartIDAnswersUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var sendPollResponsePollStartIDAnswersReturnValue: Result<Void, TimelineProxyError>! {
        get { sendPollResponsePollStartIDAnswersReturnValueLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReturnValue } }
        set { sendPollResponsePollStartIDAnswersReturnValueLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReturnValue = newValue } }
    }
    var sendPollResponsePollStartIDAnswersClosure: ((String, [String]) async -> Result<Void, TimelineProxyError>)?

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        sendPollResponsePollStartIDAnswersCallsCountLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingCallsCount += 1 }
        sendPollResponsePollStartIDAnswersReceivedArguments = (pollStartID: pollStartID, answers: answers)
        sendPollResponsePollStartIDAnswersReceivedInvocationsLock.withLock { sendPollResponsePollStartIDAnswersUnderlyingReceivedInvocations.append((pollStartID: pollStartID, answers: answers)) }
        if let sendPollResponsePollStartIDAnswersClosure = sendPollResponsePollStartIDAnswersClosure {
            return await sendPollResponsePollStartIDAnswersClosure(pollStartID, answers)
        } else {
            return sendPollResponsePollStartIDAnswersReturnValue
        }
    }
    //MARK: - endPoll

    private let endPollPollStartIDTextCallsCountLock = NSLock()
    private var endPollPollStartIDTextUnderlyingCallsCount = 0
    var endPollPollStartIDTextCallsCount: Int {
        get { endPollPollStartIDTextCallsCountLock.withLock { endPollPollStartIDTextUnderlyingCallsCount } }
        set { endPollPollStartIDTextCallsCountLock.withLock { endPollPollStartIDTextUnderlyingCallsCount = newValue } }
    }
    var endPollPollStartIDTextCalled: Bool {
        return endPollPollStartIDTextCallsCount > 0
    }
    private let endPollPollStartIDTextReceivedArgumentsLock = NSLock()
    private var endPollPollStartIDTextUnderlyingReceivedArguments: (pollStartID: String, text: String)?
    var endPollPollStartIDTextReceivedArguments: (pollStartID: String, text: String)? {
        get { endPollPollStartIDTextReceivedArgumentsLock.withLock { endPollPollStartIDTextUnderlyingReceivedArguments } }
        set { endPollPollStartIDTextReceivedArgumentsLock.withLock { endPollPollStartIDTextUnderlyingReceivedArguments = newValue } }
    }
    private let endPollPollStartIDTextReceivedInvocationsLock = NSLock()
    private var endPollPollStartIDTextUnderlyingReceivedInvocations: [(pollStartID: String, text: String)] = []
    var endPollPollStartIDTextReceivedInvocations: [(pollStartID: String, text: String)] {
        get { endPollPollStartIDTextReceivedInvocationsLock.withLock { endPollPollStartIDTextUnderlyingReceivedInvocations } }
        set { endPollPollStartIDTextReceivedInvocationsLock.withLock { endPollPollStartIDTextUnderlyingReceivedInvocations = newValue } }
    }

    private let endPollPollStartIDTextReturnValueLock = NSLock()
    private var endPollPollStartIDTextUnderlyingReturnValue: Result<Void, TimelineProxyError>!
    var endPollPollStartIDTextReturnValue: Result<Void, TimelineProxyError>! {
        get { endPollPollStartIDTextReturnValueLock.withLock { endPollPollStartIDTextUnderlyingReturnValue } }
        set { endPollPollStartIDTextReturnValueLock.withLock { endPollPollStartIDTextUnderlyingReturnValue = newValue } }
    }
    var endPollPollStartIDTextClosure: ((String, String) async -> Result<Void, TimelineProxyError>)?

    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        endPollPollStartIDTextCallsCountLock.withLock { endPollPollStartIDTextUnderlyingCallsCount += 1 }
        endPollPollStartIDTextReceivedArguments = (pollStartID: pollStartID, text: text)
        endPollPollStartIDTextReceivedInvocationsLock.withLock { endPollPollStartIDTextUnderlyingReceivedInvocations.append((pollStartID: pollStartID, text: text)) }
        if let endPollPollStartIDTextClosure = endPollPollStartIDTextClosure {
            return await endPollPollStartIDTextClosure(pollStartID, text)
        } else {
            return endPollPollStartIDTextReturnValue
        }
    }
    //MARK: - getLoadedReplyDetails

    private let getLoadedReplyDetailsEventIDCallsCountLock = NSLock()
    private var getLoadedReplyDetailsEventIDUnderlyingCallsCount = 0
    var getLoadedReplyDetailsEventIDCallsCount: Int {
        get { getLoadedReplyDetailsEventIDCallsCountLock.withLock { getLoadedReplyDetailsEventIDUnderlyingCallsCount } }
        set { getLoadedReplyDetailsEventIDCallsCountLock.withLock { getLoadedReplyDetailsEventIDUnderlyingCallsCount = newValue } }
    }
    var getLoadedReplyDetailsEventIDCalled: Bool {
        return getLoadedReplyDetailsEventIDCallsCount > 0
    }
    private let getLoadedReplyDetailsEventIDReceivedEventIDLock = NSLock()
    private var getLoadedReplyDetailsEventIDUnderlyingReceivedEventID: String?
    var getLoadedReplyDetailsEventIDReceivedEventID: String? {
        get { getLoadedReplyDetailsEventIDReceivedEventIDLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReceivedEventID } }
        set { getLoadedReplyDetailsEventIDReceivedEventIDLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReceivedEventID = newValue } }
    }
    private let getLoadedReplyDetailsEventIDReceivedInvocationsLock = NSLock()
    private var getLoadedReplyDetailsEventIDUnderlyingReceivedInvocations: [String] = []
    var getLoadedReplyDetailsEventIDReceivedInvocations: [String] {
        get { getLoadedReplyDetailsEventIDReceivedInvocationsLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReceivedInvocations } }
        set { getLoadedReplyDetailsEventIDReceivedInvocationsLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReceivedInvocations = newValue } }
    }

    private let getLoadedReplyDetailsEventIDReturnValueLock = NSLock()
    private var getLoadedReplyDetailsEventIDUnderlyingReturnValue: Result<InReplyToDetails, TimelineProxyError>!
    var getLoadedReplyDetailsEventIDReturnValue: Result<InReplyToDetails, TimelineProxyError>! {
        get { getLoadedReplyDetailsEventIDReturnValueLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReturnValue } }
        set { getLoadedReplyDetailsEventIDReturnValueLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReturnValue = newValue } }
    }
    var getLoadedReplyDetailsEventIDClosure: ((String) async -> Result<InReplyToDetails, TimelineProxyError>)?

    func getLoadedReplyDetails(eventID: String) async -> Result<InReplyToDetails, TimelineProxyError> {
        getLoadedReplyDetailsEventIDCallsCountLock.withLock { getLoadedReplyDetailsEventIDUnderlyingCallsCount += 1 }
        getLoadedReplyDetailsEventIDReceivedEventID = eventID
        getLoadedReplyDetailsEventIDReceivedInvocationsLock.withLock { getLoadedReplyDetailsEventIDUnderlyingReceivedInvocations.append(eventID) }
        if let getLoadedReplyDetailsEventIDClosure = getLoadedReplyDetailsEventIDClosure {
            return await getLoadedReplyDetailsEventIDClosure(eventID)
        } else {
            return getLoadedReplyDetailsEventIDReturnValue
        }
    }
    //MARK: - buildMessageContentFor

    private let buildMessageContentForHtmlIntentionalMentionsCallsCountLock = NSLock()
    private var buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount = 0
    var buildMessageContentForHtmlIntentionalMentionsCallsCount: Int {
        get { buildMessageContentForHtmlIntentionalMentionsCallsCountLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount } }
        set { buildMessageContentForHtmlIntentionalMentionsCallsCountLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount = newValue } }
    }
    var buildMessageContentForHtmlIntentionalMentionsCalled: Bool {
        return buildMessageContentForHtmlIntentionalMentionsCallsCount > 0
    }
    private let buildMessageContentForHtmlIntentionalMentionsReceivedArgumentsLock = NSLock()
    private var buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedArguments: (message: String, html: String?, intentionalMentions: Mentions)?
    var buildMessageContentForHtmlIntentionalMentionsReceivedArguments: (message: String, html: String?, intentionalMentions: Mentions)? {
        get { buildMessageContentForHtmlIntentionalMentionsReceivedArgumentsLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedArguments } }
        set { buildMessageContentForHtmlIntentionalMentionsReceivedArgumentsLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedArguments = newValue } }
    }
    private let buildMessageContentForHtmlIntentionalMentionsReceivedInvocationsLock = NSLock()
    private var buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedInvocations: [(message: String, html: String?, intentionalMentions: Mentions)] = []
    var buildMessageContentForHtmlIntentionalMentionsReceivedInvocations: [(message: String, html: String?, intentionalMentions: Mentions)] {
        get { buildMessageContentForHtmlIntentionalMentionsReceivedInvocationsLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedInvocations } }
        set { buildMessageContentForHtmlIntentionalMentionsReceivedInvocationsLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedInvocations = newValue } }
    }

    private let buildMessageContentForHtmlIntentionalMentionsReturnValueLock = NSLock()
    private var buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue: RoomMessageEventContentWithoutRelation!
    var buildMessageContentForHtmlIntentionalMentionsReturnValue: RoomMessageEventContentWithoutRelation! {
        get { buildMessageContentForHtmlIntentionalMentionsReturnValueLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue } }
        set { buildMessageContentForHtmlIntentionalMentionsReturnValueLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReturnValue = newValue } }
    }
    var buildMessageContentForHtmlIntentionalMentionsClosure: ((String, String?, Mentions) -> RoomMessageEventContentWithoutRelation)?

    func buildMessageContentFor(_ message: String, html: String?, intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        buildMessageContentForHtmlIntentionalMentionsCallsCountLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingCallsCount += 1 }
        buildMessageContentForHtmlIntentionalMentionsReceivedArguments = (message: message, html: html, intentionalMentions: intentionalMentions)
        buildMessageContentForHtmlIntentionalMentionsReceivedInvocationsLock.withLock { buildMessageContentForHtmlIntentionalMentionsUnderlyingReceivedInvocations.append((message: message, html: html, intentionalMentions: intentionalMentions)) }
        if let buildMessageContentForHtmlIntentionalMentionsClosure = buildMessageContentForHtmlIntentionalMentionsClosure {
            return buildMessageContentForHtmlIntentionalMentionsClosure(message, html, intentionalMentions)
        } else {
            return buildMessageContentForHtmlIntentionalMentionsReturnValue
        }
    }
}
class UserDiscoveryServiceMock: UserDiscoveryServiceProtocol, @unchecked Sendable {

    //MARK: - searchProfiles

    private let searchProfilesWithCallsCountLock = NSLock()
    private var searchProfilesWithUnderlyingCallsCount = 0
    var searchProfilesWithCallsCount: Int {
        get { searchProfilesWithCallsCountLock.withLock { searchProfilesWithUnderlyingCallsCount } }
        set { searchProfilesWithCallsCountLock.withLock { searchProfilesWithUnderlyingCallsCount = newValue } }
    }
    var searchProfilesWithCalled: Bool {
        return searchProfilesWithCallsCount > 0
    }
    private let searchProfilesWithReceivedSearchQueryLock = NSLock()
    private var searchProfilesWithUnderlyingReceivedSearchQuery: String?
    var searchProfilesWithReceivedSearchQuery: String? {
        get { searchProfilesWithReceivedSearchQueryLock.withLock { searchProfilesWithUnderlyingReceivedSearchQuery } }
        set { searchProfilesWithReceivedSearchQueryLock.withLock { searchProfilesWithUnderlyingReceivedSearchQuery = newValue } }
    }
    private let searchProfilesWithReceivedInvocationsLock = NSLock()
    private var searchProfilesWithUnderlyingReceivedInvocations: [String] = []
    var searchProfilesWithReceivedInvocations: [String] {
        get { searchProfilesWithReceivedInvocationsLock.withLock { searchProfilesWithUnderlyingReceivedInvocations } }
        set { searchProfilesWithReceivedInvocationsLock.withLock { searchProfilesWithUnderlyingReceivedInvocations = newValue } }
    }

    private let searchProfilesWithReturnValueLock = NSLock()
    private var searchProfilesWithUnderlyingReturnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>!
    var searchProfilesWithReturnValue: Result<[UserProfileProxy], UserDiscoveryErrorType>! {
        get { searchProfilesWithReturnValueLock.withLock { searchProfilesWithUnderlyingReturnValue } }
        set { searchProfilesWithReturnValueLock.withLock { searchProfilesWithUnderlyingReturnValue = newValue } }
    }
    var searchProfilesWithClosure: ((String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType>)?

    func searchProfiles(with searchQuery: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        searchProfilesWithCallsCountLock.withLock { searchProfilesWithUnderlyingCallsCount += 1 }
        searchProfilesWithReceivedSearchQuery = searchQuery
        searchProfilesWithReceivedInvocationsLock.withLock { searchProfilesWithUnderlyingReceivedInvocations.append(searchQuery) }
        if let searchProfilesWithClosure = searchProfilesWithClosure {
            return await searchProfilesWithClosure(searchQuery)
        } else {
            return searchProfilesWithReturnValue
        }
    }
}
class UserIdentityProxyMock: UserIdentityProxyProtocol, @unchecked Sendable {
    var verificationState: UserIdentityVerificationState {
        get { return underlyingVerificationState }
        set(value) { underlyingVerificationState = value }
    }
    var underlyingVerificationState: UserIdentityVerificationState!

}
class UserIndicatorControllerMock: UserIndicatorControllerProtocol, @unchecked Sendable {
    var window: UIWindow?

    //MARK: - submitIndicator

    private let submitIndicatorDelayCallsCountLock = NSLock()
    private var submitIndicatorDelayUnderlyingCallsCount = 0
    var submitIndicatorDelayCallsCount: Int {
        get { submitIndicatorDelayCallsCountLock.withLock { submitIndicatorDelayUnderlyingCallsCount } }
        set { submitIndicatorDelayCallsCountLock.withLock { submitIndicatorDelayUnderlyingCallsCount = newValue } }
    }
    var submitIndicatorDelayCalled: Bool {
        return submitIndicatorDelayCallsCount > 0
    }
    private let submitIndicatorDelayReceivedArgumentsLock = NSLock()
    private var submitIndicatorDelayUnderlyingReceivedArguments: (indicator: UserIndicator, delay: Duration?)?
    var submitIndicatorDelayReceivedArguments: (indicator: UserIndicator, delay: Duration?)? {
        get { submitIndicatorDelayReceivedArgumentsLock.withLock { submitIndicatorDelayUnderlyingReceivedArguments } }
        set { submitIndicatorDelayReceivedArgumentsLock.withLock { submitIndicatorDelayUnderlyingReceivedArguments = newValue } }
    }
    private let submitIndicatorDelayReceivedInvocationsLock = NSLock()
    private var submitIndicatorDelayUnderlyingReceivedInvocations: [(indicator: UserIndicator, delay: Duration?)] = []
    var submitIndicatorDelayReceivedInvocations: [(indicator: UserIndicator, delay: Duration?)] {
        get { submitIndicatorDelayReceivedInvocationsLock.withLock { submitIndicatorDelayUnderlyingReceivedInvocations } }
        set { submitIndicatorDelayReceivedInvocationsLock.withLock { submitIndicatorDelayUnderlyingReceivedInvocations = newValue } }
    }
    var submitIndicatorDelayClosure: ((UserIndicator, Duration?) -> Void)?

    func submitIndicator(_ indicator: UserIndicator, delay: Duration?) {
        submitIndicatorDelayCallsCountLock.withLock { submitIndicatorDelayUnderlyingCallsCount += 1 }
        submitIndicatorDelayReceivedArguments = (indicator: indicator, delay: delay)
        submitIndicatorDelayReceivedInvocationsLock.withLock { submitIndicatorDelayUnderlyingReceivedInvocations.append((indicator: indicator, delay: delay)) }
        submitIndicatorDelayClosure?(indicator, delay)
    }
    //MARK: - retractIndicatorWithId

    private let retractIndicatorWithIdCallsCountLock = NSLock()
    private var retractIndicatorWithIdUnderlyingCallsCount = 0
    var retractIndicatorWithIdCallsCount: Int {
        get { retractIndicatorWithIdCallsCountLock.withLock { retractIndicatorWithIdUnderlyingCallsCount } }
        set { retractIndicatorWithIdCallsCountLock.withLock { retractIndicatorWithIdUnderlyingCallsCount = newValue } }
    }
    var retractIndicatorWithIdCalled: Bool {
        return retractIndicatorWithIdCallsCount > 0
    }
    private let retractIndicatorWithIdReceivedIdLock = NSLock()
    private var retractIndicatorWithIdUnderlyingReceivedId: String?
    var retractIndicatorWithIdReceivedId: String? {
        get { retractIndicatorWithIdReceivedIdLock.withLock { retractIndicatorWithIdUnderlyingReceivedId } }
        set { retractIndicatorWithIdReceivedIdLock.withLock { retractIndicatorWithIdUnderlyingReceivedId = newValue } }
    }
    private let retractIndicatorWithIdReceivedInvocationsLock = NSLock()
    private var retractIndicatorWithIdUnderlyingReceivedInvocations: [String] = []
    var retractIndicatorWithIdReceivedInvocations: [String] {
        get { retractIndicatorWithIdReceivedInvocationsLock.withLock { retractIndicatorWithIdUnderlyingReceivedInvocations } }
        set { retractIndicatorWithIdReceivedInvocationsLock.withLock { retractIndicatorWithIdUnderlyingReceivedInvocations = newValue } }
    }
    var retractIndicatorWithIdClosure: ((String) -> Void)?

    func retractIndicatorWithId(_ id: String) {
        retractIndicatorWithIdCallsCountLock.withLock { retractIndicatorWithIdUnderlyingCallsCount += 1 }
        retractIndicatorWithIdReceivedId = id
        retractIndicatorWithIdReceivedInvocationsLock.withLock { retractIndicatorWithIdUnderlyingReceivedInvocations.append(id) }
        retractIndicatorWithIdClosure?(id)
    }
    //MARK: - retractAllIndicators

    private let retractAllIndicatorsCallsCountLock = NSLock()
    private var retractAllIndicatorsUnderlyingCallsCount = 0
    var retractAllIndicatorsCallsCount: Int {
        get { retractAllIndicatorsCallsCountLock.withLock { retractAllIndicatorsUnderlyingCallsCount } }
        set { retractAllIndicatorsCallsCountLock.withLock { retractAllIndicatorsUnderlyingCallsCount = newValue } }
    }
    var retractAllIndicatorsCalled: Bool {
        return retractAllIndicatorsCallsCount > 0
    }
    var retractAllIndicatorsClosure: (() -> Void)?

    func retractAllIndicators() {
        retractAllIndicatorsCallsCountLock.withLock { retractAllIndicatorsUnderlyingCallsCount += 1 }
        retractAllIndicatorsClosure?()
    }
    //MARK: - start

    private let startCallsCountLock = NSLock()
    private var startUnderlyingCallsCount = 0
    var startCallsCount: Int {
        get { startCallsCountLock.withLock { startUnderlyingCallsCount } }
        set { startCallsCountLock.withLock { startUnderlyingCallsCount = newValue } }
    }
    var startCalled: Bool {
        return startCallsCount > 0
    }
    var startClosure: (() -> Void)?

    func start() {
        startCallsCountLock.withLock { startUnderlyingCallsCount += 1 }
        startClosure?()
    }
    //MARK: - stop

    private let stopCallsCountLock = NSLock()
    private var stopUnderlyingCallsCount = 0
    var stopCallsCount: Int {
        get { stopCallsCountLock.withLock { stopUnderlyingCallsCount } }
        set { stopCallsCountLock.withLock { stopUnderlyingCallsCount = newValue } }
    }
    var stopCalled: Bool {
        return stopCallsCount > 0
    }
    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCountLock.withLock { stopUnderlyingCallsCount += 1 }
        stopClosure?()
    }
    //MARK: - toPresentable

    private let toPresentableCallsCountLock = NSLock()
    private var toPresentableUnderlyingCallsCount = 0
    var toPresentableCallsCount: Int {
        get { toPresentableCallsCountLock.withLock { toPresentableUnderlyingCallsCount } }
        set { toPresentableCallsCountLock.withLock { toPresentableUnderlyingCallsCount = newValue } }
    }
    var toPresentableCalled: Bool {
        return toPresentableCallsCount > 0
    }

    private let toPresentableReturnValueLock = NSLock()
    private var toPresentableUnderlyingReturnValue: AnyView!
    var toPresentableReturnValue: AnyView! {
        get { toPresentableReturnValueLock.withLock { toPresentableUnderlyingReturnValue } }
        set { toPresentableReturnValueLock.withLock { toPresentableUnderlyingReturnValue = newValue } }
    }
    var toPresentableClosure: (() -> AnyView)?

    func toPresentable() -> AnyView {
        toPresentableCallsCountLock.withLock { toPresentableUnderlyingCallsCount += 1 }
        if let toPresentableClosure = toPresentableClosure {
            return toPresentableClosure()
        } else {
            return toPresentableReturnValue
        }
    }
}
class UserNotificationCenterMock: UserNotificationCenterProtocol, @unchecked Sendable {
    weak var delegate: UNUserNotificationCenterDelegate?

    //MARK: - add

    var addThrowableError: Error?
    private let addCallsCountLock = NSLock()
    private var addUnderlyingCallsCount = 0
    var addCallsCount: Int {
        get { addCallsCountLock.withLock { addUnderlyingCallsCount } }
        set { addCallsCountLock.withLock { addUnderlyingCallsCount = newValue } }
    }
    var addCalled: Bool {
        return addCallsCount > 0
    }
    private let addReceivedRequestLock = NSLock()
    private var addUnderlyingReceivedRequest: UNNotificationRequest?
    var addReceivedRequest: UNNotificationRequest? {
        get { addReceivedRequestLock.withLock { addUnderlyingReceivedRequest } }
        set { addReceivedRequestLock.withLock { addUnderlyingReceivedRequest = newValue } }
    }
    private let addReceivedInvocationsLock = NSLock()
    private var addUnderlyingReceivedInvocations: [UNNotificationRequest] = []
    var addReceivedInvocations: [UNNotificationRequest] {
        get { addReceivedInvocationsLock.withLock { addUnderlyingReceivedInvocations } }
        set { addReceivedInvocationsLock.withLock { addUnderlyingReceivedInvocations = newValue } }
    }
    var addClosure: ((UNNotificationRequest) async throws -> Void)?

    func add(_ request: UNNotificationRequest) async throws {
        if let error = addThrowableError {
            throw error
        }
        addCallsCountLock.withLock { addUnderlyingCallsCount += 1 }
        addReceivedRequest = request
        addReceivedInvocationsLock.withLock { addUnderlyingReceivedInvocations.append(request) }
        try await addClosure?(request)
    }
    //MARK: - requestAuthorization

    var requestAuthorizationOptionsThrowableError: Error?
    private let requestAuthorizationOptionsCallsCountLock = NSLock()
    private var requestAuthorizationOptionsUnderlyingCallsCount = 0
    var requestAuthorizationOptionsCallsCount: Int {
        get { requestAuthorizationOptionsCallsCountLock.withLock { requestAuthorizationOptionsUnderlyingCallsCount } }
        set { requestAuthorizationOptionsCallsCountLock.withLock { requestAuthorizationOptionsUnderlyingCallsCount = newValue } }
    }
    var requestAuthorizationOptionsCalled: Bool {
        return requestAuthorizationOptionsCallsCount > 0
    }
    private let requestAuthorizationOptionsReceivedOptionsLock = NSLock()
    private var requestAuthorizationOptionsUnderlyingReceivedOptions: UNAuthorizationOptions?
    var requestAuthorizationOptionsReceivedOptions: UNAuthorizationOptions? {
        get { requestAuthorizationOptionsReceivedOptionsLock.withLock { requestAuthorizationOptionsUnderlyingReceivedOptions } }
        set { requestAuthorizationOptionsReceivedOptionsLock.withLock { requestAuthorizationOptionsUnderlyingReceivedOptions = newValue } }
    }
    private let requestAuthorizationOptionsReceivedInvocationsLock = NSLock()
    private var requestAuthorizationOptionsUnderlyingReceivedInvocations: [UNAuthorizationOptions] = []
    var requestAuthorizationOptionsReceivedInvocations: [UNAuthorizationOptions] {
        get { requestAuthorizationOptionsReceivedInvocationsLock.withLock { requestAuthorizationOptionsUnderlyingReceivedInvocations } }
        set { requestAuthorizationOptionsReceivedInvocationsLock.withLock { requestAuthorizationOptionsUnderlyingReceivedInvocations = newValue } }
    }

    private let requestAuthorizationOptionsReturnValueLock = NSLock()
    private var requestAuthorizationOptionsUnderlyingReturnValue: Bool!
    var requestAuthorizationOptionsReturnValue: Bool! {
        get { requestAuthorizationOptionsReturnValueLock.withLock { requestAuthorizationOptionsUnderlyingReturnValue } }
        set { requestAuthorizationOptionsReturnValueLock.withLock { requestAuthorizationOptionsUnderlyingReturnValue = newValue } }
    }
    var requestAuthorizationOptionsClosure: ((UNAuthorizationOptions) async throws -> Bool)?

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        if let error = requestAuthorizationOptionsThrowableError {
            throw error
        }
        requestAuthorizationOptionsCallsCountLock.withLock { requestAuthorizationOptionsUnderlyingCallsCount += 1 }
        requestAuthorizationOptionsReceivedOptions = options
        requestAuthorizationOptionsReceivedInvocationsLock.withLock { requestAuthorizationOptionsUnderlyingReceivedInvocations.append(options) }
        if let requestAuthorizationOptionsClosure = requestAuthorizationOptionsClosure {
            return try await requestAuthorizationOptionsClosure(options)
        } else {
            return requestAuthorizationOptionsReturnValue
        }
    }
    //MARK: - deliveredNotifications

    private let deliveredNotificationsCallsCountLock = NSLock()
    private var deliveredNotificationsUnderlyingCallsCount = 0
    var deliveredNotificationsCallsCount: Int {
        get { deliveredNotificationsCallsCountLock.withLock { deliveredNotificationsUnderlyingCallsCount } }
        set { deliveredNotificationsCallsCountLock.withLock { deliveredNotificationsUnderlyingCallsCount = newValue } }
    }
    var deliveredNotificationsCalled: Bool {
        return deliveredNotificationsCallsCount > 0
    }

    private let deliveredNotificationsReturnValueLock = NSLock()
    private var deliveredNotificationsUnderlyingReturnValue: [UNNotification]!
    var deliveredNotificationsReturnValue: [UNNotification]! {
        get { deliveredNotificationsReturnValueLock.withLock { deliveredNotificationsUnderlyingReturnValue } }
        set { deliveredNotificationsReturnValueLock.withLock { deliveredNotificationsUnderlyingReturnValue = newValue } }
    }
    var deliveredNotificationsClosure: (() async -> [UNNotification])?

    func deliveredNotifications() async -> [UNNotification] {
        deliveredNotificationsCallsCountLock.withLock { deliveredNotificationsUnderlyingCallsCount += 1 }
        if let deliveredNotificationsClosure = deliveredNotificationsClosure {
            return await deliveredNotificationsClosure()
        } else {
            return deliveredNotificationsReturnValue
        }
    }
    //MARK: - removeDeliveredNotifications

    private let removeDeliveredNotificationsWithIdentifiersCallsCountLock = NSLock()
    private var removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount = 0
    var removeDeliveredNotificationsWithIdentifiersCallsCount: Int {
        get { removeDeliveredNotificationsWithIdentifiersCallsCountLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount } }
        set { removeDeliveredNotificationsWithIdentifiersCallsCountLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount = newValue } }
    }
    var removeDeliveredNotificationsWithIdentifiersCalled: Bool {
        return removeDeliveredNotificationsWithIdentifiersCallsCount > 0
    }
    private let removeDeliveredNotificationsWithIdentifiersReceivedIdentifiersLock = NSLock()
    private var removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedIdentifiers: [String]?
    var removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers: [String]? {
        get { removeDeliveredNotificationsWithIdentifiersReceivedIdentifiersLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedIdentifiers } }
        set { removeDeliveredNotificationsWithIdentifiersReceivedIdentifiersLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedIdentifiers = newValue } }
    }
    private let removeDeliveredNotificationsWithIdentifiersReceivedInvocationsLock = NSLock()
    private var removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedInvocations: [[String]] = []
    var removeDeliveredNotificationsWithIdentifiersReceivedInvocations: [[String]] {
        get { removeDeliveredNotificationsWithIdentifiersReceivedInvocationsLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedInvocations } }
        set { removeDeliveredNotificationsWithIdentifiersReceivedInvocationsLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedInvocations = newValue } }
    }
    var removeDeliveredNotificationsWithIdentifiersClosure: (([String]) -> Void)?

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsWithIdentifiersCallsCountLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingCallsCount += 1 }
        removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers = identifiers
        removeDeliveredNotificationsWithIdentifiersReceivedInvocationsLock.withLock { removeDeliveredNotificationsWithIdentifiersUnderlyingReceivedInvocations.append(identifiers) }
        removeDeliveredNotificationsWithIdentifiersClosure?(identifiers)
    }
    //MARK: - setNotificationCategories

    private let setNotificationCategoriesCallsCountLock = NSLock()
    private var setNotificationCategoriesUnderlyingCallsCount = 0
    var setNotificationCategoriesCallsCount: Int {
        get { setNotificationCategoriesCallsCountLock.withLock { setNotificationCategoriesUnderlyingCallsCount } }
        set { setNotificationCategoriesCallsCountLock.withLock { setNotificationCategoriesUnderlyingCallsCount = newValue } }
    }
    var setNotificationCategoriesCalled: Bool {
        return setNotificationCategoriesCallsCount > 0
    }
    private let setNotificationCategoriesReceivedCategoriesLock = NSLock()
    private var setNotificationCategoriesUnderlyingReceivedCategories: Set<UNNotificationCategory>?
    var setNotificationCategoriesReceivedCategories: Set<UNNotificationCategory>? {
        get { setNotificationCategoriesReceivedCategoriesLock.withLock { setNotificationCategoriesUnderlyingReceivedCategories } }
        set { setNotificationCategoriesReceivedCategoriesLock.withLock { setNotificationCategoriesUnderlyingReceivedCategories = newValue } }
    }
    private let setNotificationCategoriesReceivedInvocationsLock = NSLock()
    private var setNotificationCategoriesUnderlyingReceivedInvocations: [Set<UNNotificationCategory>] = []
    var setNotificationCategoriesReceivedInvocations: [Set<UNNotificationCategory>] {
        get { setNotificationCategoriesReceivedInvocationsLock.withLock { setNotificationCategoriesUnderlyingReceivedInvocations } }
        set { setNotificationCategoriesReceivedInvocationsLock.withLock { setNotificationCategoriesUnderlyingReceivedInvocations = newValue } }
    }
    var setNotificationCategoriesClosure: ((Set<UNNotificationCategory>) -> Void)?

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        setNotificationCategoriesCallsCountLock.withLock { setNotificationCategoriesUnderlyingCallsCount += 1 }
        setNotificationCategoriesReceivedCategories = categories
        setNotificationCategoriesReceivedInvocationsLock.withLock { setNotificationCategoriesUnderlyingReceivedInvocations.append(categories) }
        setNotificationCategoriesClosure?(categories)
    }
    //MARK: - authorizationStatus

    private let authorizationStatusCallsCountLock = NSLock()
    private var authorizationStatusUnderlyingCallsCount = 0
    var authorizationStatusCallsCount: Int {
        get { authorizationStatusCallsCountLock.withLock { authorizationStatusUnderlyingCallsCount } }
        set { authorizationStatusCallsCountLock.withLock { authorizationStatusUnderlyingCallsCount = newValue } }
    }
    var authorizationStatusCalled: Bool {
        return authorizationStatusCallsCount > 0
    }

    private let authorizationStatusReturnValueLock = NSLock()
    private var authorizationStatusUnderlyingReturnValue: UNAuthorizationStatus!
    var authorizationStatusReturnValue: UNAuthorizationStatus! {
        get { authorizationStatusReturnValueLock.withLock { authorizationStatusUnderlyingReturnValue } }
        set { authorizationStatusReturnValueLock.withLock { authorizationStatusUnderlyingReturnValue = newValue } }
    }
    var authorizationStatusClosure: (() async -> UNAuthorizationStatus)?

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusCallsCountLock.withLock { authorizationStatusUnderlyingCallsCount += 1 }
        if let authorizationStatusClosure = authorizationStatusClosure {
            return await authorizationStatusClosure()
        } else {
            return authorizationStatusReturnValue
        }
    }
    //MARK: - notificationSettings

    private let notificationSettingsCallsCountLock = NSLock()
    private var notificationSettingsUnderlyingCallsCount = 0
    var notificationSettingsCallsCount: Int {
        get { notificationSettingsCallsCountLock.withLock { notificationSettingsUnderlyingCallsCount } }
        set { notificationSettingsCallsCountLock.withLock { notificationSettingsUnderlyingCallsCount = newValue } }
    }
    var notificationSettingsCalled: Bool {
        return notificationSettingsCallsCount > 0
    }

    private let notificationSettingsReturnValueLock = NSLock()
    private var notificationSettingsUnderlyingReturnValue: UNNotificationSettings!
    var notificationSettingsReturnValue: UNNotificationSettings! {
        get { notificationSettingsReturnValueLock.withLock { notificationSettingsUnderlyingReturnValue } }
        set { notificationSettingsReturnValueLock.withLock { notificationSettingsUnderlyingReturnValue = newValue } }
    }
    var notificationSettingsClosure: (() async -> UNNotificationSettings)?

    func notificationSettings() async -> UNNotificationSettings {
        notificationSettingsCallsCountLock.withLock { notificationSettingsUnderlyingCallsCount += 1 }
        if let notificationSettingsClosure = notificationSettingsClosure {
            return await notificationSettingsClosure()
        } else {
            return notificationSettingsReturnValue
        }
    }
}
class UserSessionMock: UserSessionProtocol, @unchecked Sendable {
    var clientProxy: ClientProxyProtocol {
        get { return underlyingClientProxy }
        set(value) { underlyingClientProxy = value }
    }
    var underlyingClientProxy: ClientProxyProtocol!
    var mediaProvider: MediaProviderProtocol {
        get { return underlyingMediaProvider }
        set(value) { underlyingMediaProvider = value }
    }
    var underlyingMediaProvider: MediaProviderProtocol!
    var voiceMessageMediaManager: VoiceMessageMediaManagerProtocol {
        get { return underlyingVoiceMessageMediaManager }
        set(value) { underlyingVoiceMessageMediaManager = value }
    }
    var underlyingVoiceMessageMediaManager: VoiceMessageMediaManagerProtocol!
    var liveLocationManager: LiveLocationManagerProtocol {
        get { return underlyingLiveLocationManager }
        set(value) { underlyingLiveLocationManager = value }
    }
    var underlyingLiveLocationManager: LiveLocationManagerProtocol!
    var sessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never> {
        get { return underlyingSessionSecurityStatePublisher }
        set(value) { underlyingSessionSecurityStatePublisher = value }
    }
    var underlyingSessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never>!
    var callbacks: PassthroughSubject<UserSessionCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<UserSessionCallback, Never>!

}
class UserSessionStoreMock: UserSessionStoreProtocol, @unchecked Sendable {
    var hasSessions: Bool {
        get { return underlyingHasSessions }
        set(value) { underlyingHasSessions = value }
    }
    var underlyingHasSessions: Bool!
    var userIDs: [String] = []
    var clientSessionDelegate: ClientSessionDelegate {
        get { return underlyingClientSessionDelegate }
        set(value) { underlyingClientSessionDelegate = value }
    }
    var underlyingClientSessionDelegate: ClientSessionDelegate!

    //MARK: - reset

    private let resetCallsCountLock = NSLock()
    private var resetUnderlyingCallsCount = 0
    var resetCallsCount: Int {
        get { resetCallsCountLock.withLock { resetUnderlyingCallsCount } }
        set { resetCallsCountLock.withLock { resetUnderlyingCallsCount = newValue } }
    }
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCountLock.withLock { resetUnderlyingCallsCount += 1 }
        resetClosure?()
    }
    //MARK: - restoreUserSession

    private let restoreUserSessionCallsCountLock = NSLock()
    private var restoreUserSessionUnderlyingCallsCount = 0
    var restoreUserSessionCallsCount: Int {
        get { restoreUserSessionCallsCountLock.withLock { restoreUserSessionUnderlyingCallsCount } }
        set { restoreUserSessionCallsCountLock.withLock { restoreUserSessionUnderlyingCallsCount = newValue } }
    }
    var restoreUserSessionCalled: Bool {
        return restoreUserSessionCallsCount > 0
    }

    private let restoreUserSessionReturnValueLock = NSLock()
    private var restoreUserSessionUnderlyingReturnValue: Result<UserSessionProtocol, UserSessionStoreError>!
    var restoreUserSessionReturnValue: Result<UserSessionProtocol, UserSessionStoreError>! {
        get { restoreUserSessionReturnValueLock.withLock { restoreUserSessionUnderlyingReturnValue } }
        set { restoreUserSessionReturnValueLock.withLock { restoreUserSessionUnderlyingReturnValue = newValue } }
    }
    var restoreUserSessionClosure: (() async -> Result<UserSessionProtocol, UserSessionStoreError>)?

    func restoreUserSession() async -> Result<UserSessionProtocol, UserSessionStoreError> {
        restoreUserSessionCallsCountLock.withLock { restoreUserSessionUnderlyingCallsCount += 1 }
        if let restoreUserSessionClosure = restoreUserSessionClosure {
            return await restoreUserSessionClosure()
        } else {
            return restoreUserSessionReturnValue
        }
    }
    //MARK: - userSession

    private let userSessionForSessionDirectoriesPassphraseCallsCountLock = NSLock()
    private var userSessionForSessionDirectoriesPassphraseUnderlyingCallsCount = 0
    var userSessionForSessionDirectoriesPassphraseCallsCount: Int {
        get { userSessionForSessionDirectoriesPassphraseCallsCountLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingCallsCount } }
        set { userSessionForSessionDirectoriesPassphraseCallsCountLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingCallsCount = newValue } }
    }
    var userSessionForSessionDirectoriesPassphraseCalled: Bool {
        return userSessionForSessionDirectoriesPassphraseCallsCount > 0
    }
    private let userSessionForSessionDirectoriesPassphraseReceivedArgumentsLock = NSLock()
    private var userSessionForSessionDirectoriesPassphraseUnderlyingReceivedArguments: (client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String)?
    var userSessionForSessionDirectoriesPassphraseReceivedArguments: (client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String)? {
        get { userSessionForSessionDirectoriesPassphraseReceivedArgumentsLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReceivedArguments } }
        set { userSessionForSessionDirectoriesPassphraseReceivedArgumentsLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReceivedArguments = newValue } }
    }
    private let userSessionForSessionDirectoriesPassphraseReceivedInvocationsLock = NSLock()
    private var userSessionForSessionDirectoriesPassphraseUnderlyingReceivedInvocations: [(client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String)] = []
    var userSessionForSessionDirectoriesPassphraseReceivedInvocations: [(client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String)] {
        get { userSessionForSessionDirectoriesPassphraseReceivedInvocationsLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReceivedInvocations } }
        set { userSessionForSessionDirectoriesPassphraseReceivedInvocationsLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReceivedInvocations = newValue } }
    }

    private let userSessionForSessionDirectoriesPassphraseReturnValueLock = NSLock()
    private var userSessionForSessionDirectoriesPassphraseUnderlyingReturnValue: Result<UserSessionProtocol, UserSessionStoreError>!
    var userSessionForSessionDirectoriesPassphraseReturnValue: Result<UserSessionProtocol, UserSessionStoreError>! {
        get { userSessionForSessionDirectoriesPassphraseReturnValueLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReturnValue } }
        set { userSessionForSessionDirectoriesPassphraseReturnValueLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReturnValue = newValue } }
    }
    var userSessionForSessionDirectoriesPassphraseClosure: ((ClientProtocol, SessionDirectories, String) async -> Result<UserSessionProtocol, UserSessionStoreError>)?

    func userSession(for client: ClientProtocol, sessionDirectories: SessionDirectories, passphrase: String) async -> Result<UserSessionProtocol, UserSessionStoreError> {
        userSessionForSessionDirectoriesPassphraseCallsCountLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingCallsCount += 1 }
        userSessionForSessionDirectoriesPassphraseReceivedArguments = (client: client, sessionDirectories: sessionDirectories, passphrase: passphrase)
        userSessionForSessionDirectoriesPassphraseReceivedInvocationsLock.withLock { userSessionForSessionDirectoriesPassphraseUnderlyingReceivedInvocations.append((client: client, sessionDirectories: sessionDirectories, passphrase: passphrase)) }
        if let userSessionForSessionDirectoriesPassphraseClosure = userSessionForSessionDirectoriesPassphraseClosure {
            return await userSessionForSessionDirectoriesPassphraseClosure(client, sessionDirectories, passphrase)
        } else {
            return userSessionForSessionDirectoriesPassphraseReturnValue
        }
    }
    //MARK: - logout

    private let logoutUserSessionCallsCountLock = NSLock()
    private var logoutUserSessionUnderlyingCallsCount = 0
    var logoutUserSessionCallsCount: Int {
        get { logoutUserSessionCallsCountLock.withLock { logoutUserSessionUnderlyingCallsCount } }
        set { logoutUserSessionCallsCountLock.withLock { logoutUserSessionUnderlyingCallsCount = newValue } }
    }
    var logoutUserSessionCalled: Bool {
        return logoutUserSessionCallsCount > 0
    }
    private let logoutUserSessionReceivedUserSessionLock = NSLock()
    private var logoutUserSessionUnderlyingReceivedUserSession: UserSessionProtocol?
    var logoutUserSessionReceivedUserSession: UserSessionProtocol? {
        get { logoutUserSessionReceivedUserSessionLock.withLock { logoutUserSessionUnderlyingReceivedUserSession } }
        set { logoutUserSessionReceivedUserSessionLock.withLock { logoutUserSessionUnderlyingReceivedUserSession = newValue } }
    }
    private let logoutUserSessionReceivedInvocationsLock = NSLock()
    private var logoutUserSessionUnderlyingReceivedInvocations: [UserSessionProtocol] = []
    var logoutUserSessionReceivedInvocations: [UserSessionProtocol] {
        get { logoutUserSessionReceivedInvocationsLock.withLock { logoutUserSessionUnderlyingReceivedInvocations } }
        set { logoutUserSessionReceivedInvocationsLock.withLock { logoutUserSessionUnderlyingReceivedInvocations = newValue } }
    }
    var logoutUserSessionClosure: ((UserSessionProtocol) -> Void)?

    func logout(userSession: UserSessionProtocol) {
        logoutUserSessionCallsCountLock.withLock { logoutUserSessionUnderlyingCallsCount += 1 }
        logoutUserSessionReceivedUserSession = userSession
        logoutUserSessionReceivedInvocationsLock.withLock { logoutUserSessionUnderlyingReceivedInvocations.append(userSession) }
        logoutUserSessionClosure?(userSession)
    }
}
class VoiceMessageCacheMock: VoiceMessageCacheProtocol, @unchecked Sendable {
    var urlForRecording: URL {
        get { return underlyingUrlForRecording }
        set(value) { underlyingUrlForRecording = value }
    }
    var underlyingUrlForRecording: URL!

    //MARK: - fileURL

    private let fileURLForCallsCountLock = NSLock()
    private var fileURLForUnderlyingCallsCount = 0
    var fileURLForCallsCount: Int {
        get { fileURLForCallsCountLock.withLock { fileURLForUnderlyingCallsCount } }
        set { fileURLForCallsCountLock.withLock { fileURLForUnderlyingCallsCount = newValue } }
    }
    var fileURLForCalled: Bool {
        return fileURLForCallsCount > 0
    }
    private let fileURLForReceivedMediaSourceLock = NSLock()
    private var fileURLForUnderlyingReceivedMediaSource: MediaSourceProxy?
    var fileURLForReceivedMediaSource: MediaSourceProxy? {
        get { fileURLForReceivedMediaSourceLock.withLock { fileURLForUnderlyingReceivedMediaSource } }
        set { fileURLForReceivedMediaSourceLock.withLock { fileURLForUnderlyingReceivedMediaSource = newValue } }
    }
    private let fileURLForReceivedInvocationsLock = NSLock()
    private var fileURLForUnderlyingReceivedInvocations: [MediaSourceProxy] = []
    var fileURLForReceivedInvocations: [MediaSourceProxy] {
        get { fileURLForReceivedInvocationsLock.withLock { fileURLForUnderlyingReceivedInvocations } }
        set { fileURLForReceivedInvocationsLock.withLock { fileURLForUnderlyingReceivedInvocations = newValue } }
    }

    private let fileURLForReturnValueLock = NSLock()
    private var fileURLForUnderlyingReturnValue: URL?
    var fileURLForReturnValue: URL? {
        get { fileURLForReturnValueLock.withLock { fileURLForUnderlyingReturnValue } }
        set { fileURLForReturnValueLock.withLock { fileURLForUnderlyingReturnValue = newValue } }
    }
    var fileURLForClosure: ((MediaSourceProxy) -> URL?)?

    func fileURL(for mediaSource: MediaSourceProxy) -> URL? {
        fileURLForCallsCountLock.withLock { fileURLForUnderlyingCallsCount += 1 }
        fileURLForReceivedMediaSource = mediaSource
        fileURLForReceivedInvocationsLock.withLock { fileURLForUnderlyingReceivedInvocations.append(mediaSource) }
        if let fileURLForClosure = fileURLForClosure {
            return fileURLForClosure(mediaSource)
        } else {
            return fileURLForReturnValue
        }
    }
    //MARK: - cache

    private let cacheMediaSourceUsingMoveCallsCountLock = NSLock()
    private var cacheMediaSourceUsingMoveUnderlyingCallsCount = 0
    var cacheMediaSourceUsingMoveCallsCount: Int {
        get { cacheMediaSourceUsingMoveCallsCountLock.withLock { cacheMediaSourceUsingMoveUnderlyingCallsCount } }
        set { cacheMediaSourceUsingMoveCallsCountLock.withLock { cacheMediaSourceUsingMoveUnderlyingCallsCount = newValue } }
    }
    var cacheMediaSourceUsingMoveCalled: Bool {
        return cacheMediaSourceUsingMoveCallsCount > 0
    }
    private let cacheMediaSourceUsingMoveReceivedArgumentsLock = NSLock()
    private var cacheMediaSourceUsingMoveUnderlyingReceivedArguments: (mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)?
    var cacheMediaSourceUsingMoveReceivedArguments: (mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)? {
        get { cacheMediaSourceUsingMoveReceivedArgumentsLock.withLock { cacheMediaSourceUsingMoveUnderlyingReceivedArguments } }
        set { cacheMediaSourceUsingMoveReceivedArgumentsLock.withLock { cacheMediaSourceUsingMoveUnderlyingReceivedArguments = newValue } }
    }
    private let cacheMediaSourceUsingMoveReceivedInvocationsLock = NSLock()
    private var cacheMediaSourceUsingMoveUnderlyingReceivedInvocations: [(mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)] = []
    var cacheMediaSourceUsingMoveReceivedInvocations: [(mediaSource: MediaSourceProxy, fileURL: URL, move: Bool)] {
        get { cacheMediaSourceUsingMoveReceivedInvocationsLock.withLock { cacheMediaSourceUsingMoveUnderlyingReceivedInvocations } }
        set { cacheMediaSourceUsingMoveReceivedInvocationsLock.withLock { cacheMediaSourceUsingMoveUnderlyingReceivedInvocations = newValue } }
    }

    private let cacheMediaSourceUsingMoveReturnValueLock = NSLock()
    private var cacheMediaSourceUsingMoveUnderlyingReturnValue: Result<URL, VoiceMessageCacheError>!
    var cacheMediaSourceUsingMoveReturnValue: Result<URL, VoiceMessageCacheError>! {
        get { cacheMediaSourceUsingMoveReturnValueLock.withLock { cacheMediaSourceUsingMoveUnderlyingReturnValue } }
        set { cacheMediaSourceUsingMoveReturnValueLock.withLock { cacheMediaSourceUsingMoveUnderlyingReturnValue = newValue } }
    }
    var cacheMediaSourceUsingMoveClosure: ((MediaSourceProxy, URL, Bool) -> Result<URL, VoiceMessageCacheError>)?

    func cache(mediaSource: MediaSourceProxy, using fileURL: URL, move: Bool) -> Result<URL, VoiceMessageCacheError> {
        cacheMediaSourceUsingMoveCallsCountLock.withLock { cacheMediaSourceUsingMoveUnderlyingCallsCount += 1 }
        cacheMediaSourceUsingMoveReceivedArguments = (mediaSource: mediaSource, fileURL: fileURL, move: move)
        cacheMediaSourceUsingMoveReceivedInvocationsLock.withLock { cacheMediaSourceUsingMoveUnderlyingReceivedInvocations.append((mediaSource: mediaSource, fileURL: fileURL, move: move)) }
        if let cacheMediaSourceUsingMoveClosure = cacheMediaSourceUsingMoveClosure {
            return cacheMediaSourceUsingMoveClosure(mediaSource, fileURL, move)
        } else {
            return cacheMediaSourceUsingMoveReturnValue
        }
    }
    //MARK: - clearCache

    private let clearCacheCallsCountLock = NSLock()
    private var clearCacheUnderlyingCallsCount = 0
    var clearCacheCallsCount: Int {
        get { clearCacheCallsCountLock.withLock { clearCacheUnderlyingCallsCount } }
        set { clearCacheCallsCountLock.withLock { clearCacheUnderlyingCallsCount = newValue } }
    }
    var clearCacheCalled: Bool {
        return clearCacheCallsCount > 0
    }
    var clearCacheClosure: (() -> Void)?

    func clearCache() {
        clearCacheCallsCountLock.withLock { clearCacheUnderlyingCallsCount += 1 }
        clearCacheClosure?()
    }
}
class VoiceMessageMediaManagerMock: VoiceMessageMediaManagerProtocol, @unchecked Sendable {

    //MARK: - loadVoiceMessageFromSource

    var loadVoiceMessageFromSourceBodyThrowableError: Error?
    private let loadVoiceMessageFromSourceBodyCallsCountLock = NSLock()
    private var loadVoiceMessageFromSourceBodyUnderlyingCallsCount = 0
    var loadVoiceMessageFromSourceBodyCallsCount: Int {
        get { loadVoiceMessageFromSourceBodyCallsCountLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingCallsCount } }
        set { loadVoiceMessageFromSourceBodyCallsCountLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingCallsCount = newValue } }
    }
    var loadVoiceMessageFromSourceBodyCalled: Bool {
        return loadVoiceMessageFromSourceBodyCallsCount > 0
    }
    private let loadVoiceMessageFromSourceBodyReceivedArgumentsLock = NSLock()
    private var loadVoiceMessageFromSourceBodyUnderlyingReceivedArguments: (source: MediaSourceProxy, body: String?)?
    var loadVoiceMessageFromSourceBodyReceivedArguments: (source: MediaSourceProxy, body: String?)? {
        get { loadVoiceMessageFromSourceBodyReceivedArgumentsLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReceivedArguments } }
        set { loadVoiceMessageFromSourceBodyReceivedArgumentsLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReceivedArguments = newValue } }
    }
    private let loadVoiceMessageFromSourceBodyReceivedInvocationsLock = NSLock()
    private var loadVoiceMessageFromSourceBodyUnderlyingReceivedInvocations: [(source: MediaSourceProxy, body: String?)] = []
    var loadVoiceMessageFromSourceBodyReceivedInvocations: [(source: MediaSourceProxy, body: String?)] {
        get { loadVoiceMessageFromSourceBodyReceivedInvocationsLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReceivedInvocations } }
        set { loadVoiceMessageFromSourceBodyReceivedInvocationsLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReceivedInvocations = newValue } }
    }

    private let loadVoiceMessageFromSourceBodyReturnValueLock = NSLock()
    private var loadVoiceMessageFromSourceBodyUnderlyingReturnValue: URL!
    var loadVoiceMessageFromSourceBodyReturnValue: URL! {
        get { loadVoiceMessageFromSourceBodyReturnValueLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReturnValue } }
        set { loadVoiceMessageFromSourceBodyReturnValueLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReturnValue = newValue } }
    }
    var loadVoiceMessageFromSourceBodyClosure: ((MediaSourceProxy, String?) async throws -> URL)?

    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        if let error = loadVoiceMessageFromSourceBodyThrowableError {
            throw error
        }
        loadVoiceMessageFromSourceBodyCallsCountLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingCallsCount += 1 }
        loadVoiceMessageFromSourceBodyReceivedArguments = (source: source, body: body)
        loadVoiceMessageFromSourceBodyReceivedInvocationsLock.withLock { loadVoiceMessageFromSourceBodyUnderlyingReceivedInvocations.append((source: source, body: body)) }
        if let loadVoiceMessageFromSourceBodyClosure = loadVoiceMessageFromSourceBodyClosure {
            return try await loadVoiceMessageFromSourceBodyClosure(source, body)
        } else {
            return loadVoiceMessageFromSourceBodyReturnValue
        }
    }
}
class VoiceMessageRecorderMock: VoiceMessageRecorderProtocol, @unchecked Sendable {
    var previewAudioPlayerState: AudioPlayerState?
    var isRecording: Bool {
        get { return underlyingIsRecording }
        set(value) { underlyingIsRecording = value }
    }
    var underlyingIsRecording: Bool!
    var recordingURL: URL?
    var actions: AnyPublisher<VoiceMessageRecorderAction, Never> {
        get { return underlyingActions }
        set(value) { underlyingActions = value }
    }
    var underlyingActions: AnyPublisher<VoiceMessageRecorderAction, Never>!

    //MARK: - startRecording

    private let startRecordingCallsCountLock = NSLock()
    private var startRecordingUnderlyingCallsCount = 0
    var startRecordingCallsCount: Int {
        get { startRecordingCallsCountLock.withLock { startRecordingUnderlyingCallsCount } }
        set { startRecordingCallsCountLock.withLock { startRecordingUnderlyingCallsCount = newValue } }
    }
    var startRecordingCalled: Bool {
        return startRecordingCallsCount > 0
    }
    var startRecordingClosure: (() async -> Void)?

    func startRecording() async {
        startRecordingCallsCountLock.withLock { startRecordingUnderlyingCallsCount += 1 }
        await startRecordingClosure?()
    }
    //MARK: - stopRecording

    private let stopRecordingCallsCountLock = NSLock()
    private var stopRecordingUnderlyingCallsCount = 0
    var stopRecordingCallsCount: Int {
        get { stopRecordingCallsCountLock.withLock { stopRecordingUnderlyingCallsCount } }
        set { stopRecordingCallsCountLock.withLock { stopRecordingUnderlyingCallsCount = newValue } }
    }
    var stopRecordingCalled: Bool {
        return stopRecordingCallsCount > 0
    }
    var stopRecordingClosure: (() async -> Void)?

    func stopRecording() async {
        stopRecordingCallsCountLock.withLock { stopRecordingUnderlyingCallsCount += 1 }
        await stopRecordingClosure?()
    }
    //MARK: - cancelRecording

    private let cancelRecordingCallsCountLock = NSLock()
    private var cancelRecordingUnderlyingCallsCount = 0
    var cancelRecordingCallsCount: Int {
        get { cancelRecordingCallsCountLock.withLock { cancelRecordingUnderlyingCallsCount } }
        set { cancelRecordingCallsCountLock.withLock { cancelRecordingUnderlyingCallsCount = newValue } }
    }
    var cancelRecordingCalled: Bool {
        return cancelRecordingCallsCount > 0
    }
    var cancelRecordingClosure: (() async -> Void)?

    func cancelRecording() async {
        cancelRecordingCallsCountLock.withLock { cancelRecordingUnderlyingCallsCount += 1 }
        await cancelRecordingClosure?()
    }
    //MARK: - startPlayback

    private let startPlaybackCallsCountLock = NSLock()
    private var startPlaybackUnderlyingCallsCount = 0
    var startPlaybackCallsCount: Int {
        get { startPlaybackCallsCountLock.withLock { startPlaybackUnderlyingCallsCount } }
        set { startPlaybackCallsCountLock.withLock { startPlaybackUnderlyingCallsCount = newValue } }
    }
    var startPlaybackCalled: Bool {
        return startPlaybackCallsCount > 0
    }

    private let startPlaybackReturnValueLock = NSLock()
    private var startPlaybackUnderlyingReturnValue: Result<Void, VoiceMessageRecorderError>!
    var startPlaybackReturnValue: Result<Void, VoiceMessageRecorderError>! {
        get { startPlaybackReturnValueLock.withLock { startPlaybackUnderlyingReturnValue } }
        set { startPlaybackReturnValueLock.withLock { startPlaybackUnderlyingReturnValue = newValue } }
    }
    var startPlaybackClosure: (() async -> Result<Void, VoiceMessageRecorderError>)?

    func startPlayback() async -> Result<Void, VoiceMessageRecorderError> {
        startPlaybackCallsCountLock.withLock { startPlaybackUnderlyingCallsCount += 1 }
        if let startPlaybackClosure = startPlaybackClosure {
            return await startPlaybackClosure()
        } else {
            return startPlaybackReturnValue
        }
    }
    //MARK: - pausePlayback

    private let pausePlaybackCallsCountLock = NSLock()
    private var pausePlaybackUnderlyingCallsCount = 0
    var pausePlaybackCallsCount: Int {
        get { pausePlaybackCallsCountLock.withLock { pausePlaybackUnderlyingCallsCount } }
        set { pausePlaybackCallsCountLock.withLock { pausePlaybackUnderlyingCallsCount = newValue } }
    }
    var pausePlaybackCalled: Bool {
        return pausePlaybackCallsCount > 0
    }
    var pausePlaybackClosure: (() -> Void)?

    func pausePlayback() {
        pausePlaybackCallsCountLock.withLock { pausePlaybackUnderlyingCallsCount += 1 }
        pausePlaybackClosure?()
    }
    //MARK: - stopPlayback

    private let stopPlaybackCallsCountLock = NSLock()
    private var stopPlaybackUnderlyingCallsCount = 0
    var stopPlaybackCallsCount: Int {
        get { stopPlaybackCallsCountLock.withLock { stopPlaybackUnderlyingCallsCount } }
        set { stopPlaybackCallsCountLock.withLock { stopPlaybackUnderlyingCallsCount = newValue } }
    }
    var stopPlaybackCalled: Bool {
        return stopPlaybackCallsCount > 0
    }
    var stopPlaybackClosure: (() async -> Void)?

    func stopPlayback() async {
        stopPlaybackCallsCountLock.withLock { stopPlaybackUnderlyingCallsCount += 1 }
        await stopPlaybackClosure?()
    }
    //MARK: - seekPlayback

    private let seekPlaybackToCallsCountLock = NSLock()
    private var seekPlaybackToUnderlyingCallsCount = 0
    var seekPlaybackToCallsCount: Int {
        get { seekPlaybackToCallsCountLock.withLock { seekPlaybackToUnderlyingCallsCount } }
        set { seekPlaybackToCallsCountLock.withLock { seekPlaybackToUnderlyingCallsCount = newValue } }
    }
    var seekPlaybackToCalled: Bool {
        return seekPlaybackToCallsCount > 0
    }
    private let seekPlaybackToReceivedProgressLock = NSLock()
    private var seekPlaybackToUnderlyingReceivedProgress: Double?
    var seekPlaybackToReceivedProgress: Double? {
        get { seekPlaybackToReceivedProgressLock.withLock { seekPlaybackToUnderlyingReceivedProgress } }
        set { seekPlaybackToReceivedProgressLock.withLock { seekPlaybackToUnderlyingReceivedProgress = newValue } }
    }
    private let seekPlaybackToReceivedInvocationsLock = NSLock()
    private var seekPlaybackToUnderlyingReceivedInvocations: [Double] = []
    var seekPlaybackToReceivedInvocations: [Double] {
        get { seekPlaybackToReceivedInvocationsLock.withLock { seekPlaybackToUnderlyingReceivedInvocations } }
        set { seekPlaybackToReceivedInvocationsLock.withLock { seekPlaybackToUnderlyingReceivedInvocations = newValue } }
    }
    var seekPlaybackToClosure: ((Double) async -> Void)?

    func seekPlayback(to progress: Double) async {
        seekPlaybackToCallsCountLock.withLock { seekPlaybackToUnderlyingCallsCount += 1 }
        seekPlaybackToReceivedProgress = progress
        seekPlaybackToReceivedInvocationsLock.withLock { seekPlaybackToUnderlyingReceivedInvocations.append(progress) }
        await seekPlaybackToClosure?(progress)
    }
    //MARK: - deleteRecording

    private let deleteRecordingCallsCountLock = NSLock()
    private var deleteRecordingUnderlyingCallsCount = 0
    var deleteRecordingCallsCount: Int {
        get { deleteRecordingCallsCountLock.withLock { deleteRecordingUnderlyingCallsCount } }
        set { deleteRecordingCallsCountLock.withLock { deleteRecordingUnderlyingCallsCount = newValue } }
    }
    var deleteRecordingCalled: Bool {
        return deleteRecordingCallsCount > 0
    }
    var deleteRecordingClosure: (() async -> Void)?

    func deleteRecording() async {
        deleteRecordingCallsCountLock.withLock { deleteRecordingUnderlyingCallsCount += 1 }
        await deleteRecordingClosure?()
    }
    //MARK: - sendVoiceMessage

    private let sendVoiceMessageTimelineControllerAudioConverterCallsCountLock = NSLock()
    private var sendVoiceMessageTimelineControllerAudioConverterUnderlyingCallsCount = 0
    var sendVoiceMessageTimelineControllerAudioConverterCallsCount: Int {
        get { sendVoiceMessageTimelineControllerAudioConverterCallsCountLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingCallsCount } }
        set { sendVoiceMessageTimelineControllerAudioConverterCallsCountLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingCallsCount = newValue } }
    }
    var sendVoiceMessageTimelineControllerAudioConverterCalled: Bool {
        return sendVoiceMessageTimelineControllerAudioConverterCallsCount > 0
    }
    private let sendVoiceMessageTimelineControllerAudioConverterReceivedArgumentsLock = NSLock()
    private var sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedArguments: (timelineController: TimelineControllerProtocol, audioConverter: AudioConverterProtocol)?
    var sendVoiceMessageTimelineControllerAudioConverterReceivedArguments: (timelineController: TimelineControllerProtocol, audioConverter: AudioConverterProtocol)? {
        get { sendVoiceMessageTimelineControllerAudioConverterReceivedArgumentsLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedArguments } }
        set { sendVoiceMessageTimelineControllerAudioConverterReceivedArgumentsLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedArguments = newValue } }
    }
    private let sendVoiceMessageTimelineControllerAudioConverterReceivedInvocationsLock = NSLock()
    private var sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedInvocations: [(timelineController: TimelineControllerProtocol, audioConverter: AudioConverterProtocol)] = []
    var sendVoiceMessageTimelineControllerAudioConverterReceivedInvocations: [(timelineController: TimelineControllerProtocol, audioConverter: AudioConverterProtocol)] {
        get { sendVoiceMessageTimelineControllerAudioConverterReceivedInvocationsLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedInvocations } }
        set { sendVoiceMessageTimelineControllerAudioConverterReceivedInvocationsLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedInvocations = newValue } }
    }

    private let sendVoiceMessageTimelineControllerAudioConverterReturnValueLock = NSLock()
    private var sendVoiceMessageTimelineControllerAudioConverterUnderlyingReturnValue: Result<Void, VoiceMessageRecorderError>!
    var sendVoiceMessageTimelineControllerAudioConverterReturnValue: Result<Void, VoiceMessageRecorderError>! {
        get { sendVoiceMessageTimelineControllerAudioConverterReturnValueLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReturnValue } }
        set { sendVoiceMessageTimelineControllerAudioConverterReturnValueLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReturnValue = newValue } }
    }
    var sendVoiceMessageTimelineControllerAudioConverterClosure: ((TimelineControllerProtocol, AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError>)?

    func sendVoiceMessage(timelineController: TimelineControllerProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError> {
        sendVoiceMessageTimelineControllerAudioConverterCallsCountLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingCallsCount += 1 }
        sendVoiceMessageTimelineControllerAudioConverterReceivedArguments = (timelineController: timelineController, audioConverter: audioConverter)
        sendVoiceMessageTimelineControllerAudioConverterReceivedInvocationsLock.withLock { sendVoiceMessageTimelineControllerAudioConverterUnderlyingReceivedInvocations.append((timelineController: timelineController, audioConverter: audioConverter)) }
        if let sendVoiceMessageTimelineControllerAudioConverterClosure = sendVoiceMessageTimelineControllerAudioConverterClosure {
            return await sendVoiceMessageTimelineControllerAudioConverterClosure(timelineController, audioConverter)
        } else {
            return sendVoiceMessageTimelineControllerAudioConverterReturnValue
        }
    }
}
class WindowManagerMock: WindowManagerProtocol, @unchecked Sendable {
    var mainWindow: UIWindow!
    var overlayWindow: UIWindow!
    var globalSearchWindow: UIWindow!
    var alternateWindow: UIWindow!
    var windows: [UIWindow] = []
    var secondaryWindowsEnabled: Bool {
        get { return underlyingSecondaryWindowsEnabled }
        set(value) { underlyingSecondaryWindowsEnabled = value }
    }
    var underlyingSecondaryWindowsEnabled: Bool!

    //MARK: - showGlobalSearch

    private let showGlobalSearchCallsCountLock = NSLock()
    private var showGlobalSearchUnderlyingCallsCount = 0
    var showGlobalSearchCallsCount: Int {
        get { showGlobalSearchCallsCountLock.withLock { showGlobalSearchUnderlyingCallsCount } }
        set { showGlobalSearchCallsCountLock.withLock { showGlobalSearchUnderlyingCallsCount = newValue } }
    }
    var showGlobalSearchCalled: Bool {
        return showGlobalSearchCallsCount > 0
    }
    var showGlobalSearchClosure: (() -> Void)?

    func showGlobalSearch() {
        showGlobalSearchCallsCountLock.withLock { showGlobalSearchUnderlyingCallsCount += 1 }
        showGlobalSearchClosure?()
    }
    //MARK: - hideGlobalSearch

    private let hideGlobalSearchCallsCountLock = NSLock()
    private var hideGlobalSearchUnderlyingCallsCount = 0
    var hideGlobalSearchCallsCount: Int {
        get { hideGlobalSearchCallsCountLock.withLock { hideGlobalSearchUnderlyingCallsCount } }
        set { hideGlobalSearchCallsCountLock.withLock { hideGlobalSearchUnderlyingCallsCount = newValue } }
    }
    var hideGlobalSearchCalled: Bool {
        return hideGlobalSearchCallsCount > 0
    }
    var hideGlobalSearchClosure: (() -> Void)?

    func hideGlobalSearch() {
        hideGlobalSearchCallsCountLock.withLock { hideGlobalSearchUnderlyingCallsCount += 1 }
        hideGlobalSearchClosure?()
    }
    //MARK: - registerCoordinator

    private let registerCoordinatorFlowCoordinatorForWindowTypeCallsCountLock = NSLock()
    private var registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingCallsCount = 0
    var registerCoordinatorFlowCoordinatorForWindowTypeCallsCount: Int {
        get { registerCoordinatorFlowCoordinatorForWindowTypeCallsCountLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingCallsCount } }
        set { registerCoordinatorFlowCoordinatorForWindowTypeCallsCountLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingCallsCount = newValue } }
    }
    var registerCoordinatorFlowCoordinatorForWindowTypeCalled: Bool {
        return registerCoordinatorFlowCoordinatorForWindowTypeCallsCount > 0
    }
    private let registerCoordinatorFlowCoordinatorForWindowTypeReceivedArgumentsLock = NSLock()
    private var registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedArguments: (coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?, type: SecondaryWindowType)?
    var registerCoordinatorFlowCoordinatorForWindowTypeReceivedArguments: (coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?, type: SecondaryWindowType)? {
        get { registerCoordinatorFlowCoordinatorForWindowTypeReceivedArgumentsLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedArguments } }
        set { registerCoordinatorFlowCoordinatorForWindowTypeReceivedArgumentsLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedArguments = newValue } }
    }
    private let registerCoordinatorFlowCoordinatorForWindowTypeReceivedInvocationsLock = NSLock()
    private var registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedInvocations: [(coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?, type: SecondaryWindowType)] = []
    var registerCoordinatorFlowCoordinatorForWindowTypeReceivedInvocations: [(coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?, type: SecondaryWindowType)] {
        get { registerCoordinatorFlowCoordinatorForWindowTypeReceivedInvocationsLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedInvocations } }
        set { registerCoordinatorFlowCoordinatorForWindowTypeReceivedInvocationsLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedInvocations = newValue } }
    }
    var registerCoordinatorFlowCoordinatorForWindowTypeClosure: ((CoordinatorProtocol, FlowCoordinatorProtocol?, SecondaryWindowType) -> Void)?

    func registerCoordinator(_ coordinator: CoordinatorProtocol, flowCoordinator: FlowCoordinatorProtocol?, forWindowType type: SecondaryWindowType) {
        registerCoordinatorFlowCoordinatorForWindowTypeCallsCountLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingCallsCount += 1 }
        registerCoordinatorFlowCoordinatorForWindowTypeReceivedArguments = (coordinator: coordinator, flowCoordinator: flowCoordinator, type: type)
        registerCoordinatorFlowCoordinatorForWindowTypeReceivedInvocationsLock.withLock { registerCoordinatorFlowCoordinatorForWindowTypeUnderlyingReceivedInvocations.append((coordinator: coordinator, flowCoordinator: flowCoordinator, type: type)) }
        registerCoordinatorFlowCoordinatorForWindowTypeClosure?(coordinator, flowCoordinator, type)
    }
    //MARK: - closeAllSecondaryWindows

    private let closeAllSecondaryWindowsCallsCountLock = NSLock()
    private var closeAllSecondaryWindowsUnderlyingCallsCount = 0
    var closeAllSecondaryWindowsCallsCount: Int {
        get { closeAllSecondaryWindowsCallsCountLock.withLock { closeAllSecondaryWindowsUnderlyingCallsCount } }
        set { closeAllSecondaryWindowsCallsCountLock.withLock { closeAllSecondaryWindowsUnderlyingCallsCount = newValue } }
    }
    var closeAllSecondaryWindowsCalled: Bool {
        return closeAllSecondaryWindowsCallsCount > 0
    }
    var closeAllSecondaryWindowsClosure: (() -> Void)?

    func closeAllSecondaryWindows() {
        closeAllSecondaryWindowsCallsCountLock.withLock { closeAllSecondaryWindowsUnderlyingCallsCount += 1 }
        closeAllSecondaryWindowsClosure?()
    }
    //MARK: - closeSecondaryWindow

    private let closeSecondaryWindowForTypeCallsCountLock = NSLock()
    private var closeSecondaryWindowForTypeUnderlyingCallsCount = 0
    var closeSecondaryWindowForTypeCallsCount: Int {
        get { closeSecondaryWindowForTypeCallsCountLock.withLock { closeSecondaryWindowForTypeUnderlyingCallsCount } }
        set { closeSecondaryWindowForTypeCallsCountLock.withLock { closeSecondaryWindowForTypeUnderlyingCallsCount = newValue } }
    }
    var closeSecondaryWindowForTypeCalled: Bool {
        return closeSecondaryWindowForTypeCallsCount > 0
    }
    private let closeSecondaryWindowForTypeReceivedTypeLock = NSLock()
    private var closeSecondaryWindowForTypeUnderlyingReceivedType: SecondaryWindowType?
    var closeSecondaryWindowForTypeReceivedType: SecondaryWindowType? {
        get { closeSecondaryWindowForTypeReceivedTypeLock.withLock { closeSecondaryWindowForTypeUnderlyingReceivedType } }
        set { closeSecondaryWindowForTypeReceivedTypeLock.withLock { closeSecondaryWindowForTypeUnderlyingReceivedType = newValue } }
    }
    private let closeSecondaryWindowForTypeReceivedInvocationsLock = NSLock()
    private var closeSecondaryWindowForTypeUnderlyingReceivedInvocations: [SecondaryWindowType] = []
    var closeSecondaryWindowForTypeReceivedInvocations: [SecondaryWindowType] {
        get { closeSecondaryWindowForTypeReceivedInvocationsLock.withLock { closeSecondaryWindowForTypeUnderlyingReceivedInvocations } }
        set { closeSecondaryWindowForTypeReceivedInvocationsLock.withLock { closeSecondaryWindowForTypeUnderlyingReceivedInvocations = newValue } }
    }
    var closeSecondaryWindowForTypeClosure: ((SecondaryWindowType) -> Void)?

    func closeSecondaryWindow(forType type: SecondaryWindowType) {
        closeSecondaryWindowForTypeCallsCountLock.withLock { closeSecondaryWindowForTypeUnderlyingCallsCount += 1 }
        closeSecondaryWindowForTypeReceivedType = type
        closeSecondaryWindowForTypeReceivedInvocationsLock.withLock { closeSecondaryWindowForTypeUnderlyingReceivedInvocations.append(type) }
        closeSecondaryWindowForTypeClosure?(type)
    }
    //MARK: - setOrientation

    private let setOrientationCallsCountLock = NSLock()
    private var setOrientationUnderlyingCallsCount = 0
    var setOrientationCallsCount: Int {
        get { setOrientationCallsCountLock.withLock { setOrientationUnderlyingCallsCount } }
        set { setOrientationCallsCountLock.withLock { setOrientationUnderlyingCallsCount = newValue } }
    }
    var setOrientationCalled: Bool {
        return setOrientationCallsCount > 0
    }
    private let setOrientationReceivedOrientationLock = NSLock()
    private var setOrientationUnderlyingReceivedOrientation: UIInterfaceOrientationMask?
    var setOrientationReceivedOrientation: UIInterfaceOrientationMask? {
        get { setOrientationReceivedOrientationLock.withLock { setOrientationUnderlyingReceivedOrientation } }
        set { setOrientationReceivedOrientationLock.withLock { setOrientationUnderlyingReceivedOrientation = newValue } }
    }
    private let setOrientationReceivedInvocationsLock = NSLock()
    private var setOrientationUnderlyingReceivedInvocations: [UIInterfaceOrientationMask] = []
    var setOrientationReceivedInvocations: [UIInterfaceOrientationMask] {
        get { setOrientationReceivedInvocationsLock.withLock { setOrientationUnderlyingReceivedInvocations } }
        set { setOrientationReceivedInvocationsLock.withLock { setOrientationUnderlyingReceivedInvocations = newValue } }
    }
    var setOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        setOrientationCallsCountLock.withLock { setOrientationUnderlyingCallsCount += 1 }
        setOrientationReceivedOrientation = orientation
        setOrientationReceivedInvocationsLock.withLock { setOrientationUnderlyingReceivedInvocations.append(orientation) }
        setOrientationClosure?(orientation)
    }
    //MARK: - lockOrientation

    private let lockOrientationCallsCountLock = NSLock()
    private var lockOrientationUnderlyingCallsCount = 0
    var lockOrientationCallsCount: Int {
        get { lockOrientationCallsCountLock.withLock { lockOrientationUnderlyingCallsCount } }
        set { lockOrientationCallsCountLock.withLock { lockOrientationUnderlyingCallsCount = newValue } }
    }
    var lockOrientationCalled: Bool {
        return lockOrientationCallsCount > 0
    }
    private let lockOrientationReceivedOrientationLock = NSLock()
    private var lockOrientationUnderlyingReceivedOrientation: UIInterfaceOrientationMask?
    var lockOrientationReceivedOrientation: UIInterfaceOrientationMask? {
        get { lockOrientationReceivedOrientationLock.withLock { lockOrientationUnderlyingReceivedOrientation } }
        set { lockOrientationReceivedOrientationLock.withLock { lockOrientationUnderlyingReceivedOrientation = newValue } }
    }
    private let lockOrientationReceivedInvocationsLock = NSLock()
    private var lockOrientationUnderlyingReceivedInvocations: [UIInterfaceOrientationMask] = []
    var lockOrientationReceivedInvocations: [UIInterfaceOrientationMask] {
        get { lockOrientationReceivedInvocationsLock.withLock { lockOrientationUnderlyingReceivedInvocations } }
        set { lockOrientationReceivedInvocationsLock.withLock { lockOrientationUnderlyingReceivedInvocations = newValue } }
    }
    var lockOrientationClosure: ((UIInterfaceOrientationMask) -> Void)?

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        lockOrientationCallsCountLock.withLock { lockOrientationUnderlyingCallsCount += 1 }
        lockOrientationReceivedOrientation = orientation
        lockOrientationReceivedInvocationsLock.withLock { lockOrientationUnderlyingReceivedInvocations.append(orientation) }
        lockOrientationClosure?(orientation)
    }
}
// swiftlint:enable all
