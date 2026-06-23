// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all
// Generated using Sourcery. DO NOT EDIT.

import Combine
import Foundation

// Exposes each `_foo: UserPreference<T>` backing as a `foo` value accessor (and, when annotated
// `// sourcery: publisher`, a `fooPublisher`). Generated rather than hand-written because the
// declarations can't use the `@UserPreference` property wrapper without emitting a spurious
// "nonisolated(unsafe) has no effect" warning – see UserPreference.swift.
nonisolated extension AppSettings {
    var lastVersionLaunched: String? {
        get { _lastVersionLaunched.wrappedValue }
        set { _lastVersionLaunched.wrappedValue = newValue }
    }
    var seenInvites: Set<String> {
        get { _seenInvites.wrappedValue }
        set { _seenInvites.wrappedValue = newValue }
    }
    var seenInvitesPublisher: AnyPublisher<Set<String>, Never> {
        _seenInvites.projectedValue
    }
    var hasSeenNewSoundBanner: Bool {
        get { _hasSeenNewSoundBanner.wrappedValue }
        set { _hasSeenNewSoundBanner.wrappedValue = newValue }
    }
    var hasSeenNewSoundBannerPublisher: AnyPublisher<Bool, Never> {
        _hasSeenNewSoundBanner.projectedValue
    }
    var appAppearance: AppAppearance {
        get { _appAppearance.wrappedValue }
        set { _appAppearance.wrappedValue = newValue }
    }
    var appAppearancePublisher: AnyPublisher<AppAppearance, Never> {
        _appAppearance.projectedValue
    }
    var appLockNumberOfPINAttempts: Int {
        get { _appLockNumberOfPINAttempts.wrappedValue }
        set { _appLockNumberOfPINAttempts.wrappedValue = newValue }
    }
    var appLockNumberOfPINAttemptsPublisher: AnyPublisher<Int, Never> {
        _appLockNumberOfPINAttempts.projectedValue
    }
    var enableNotifications: Bool {
        get { _enableNotifications.wrappedValue }
        set { _enableNotifications.wrappedValue = newValue }
    }
    var enableNotificationsPublisher: AnyPublisher<Bool, Never> {
        _enableNotifications.projectedValue
    }
    var enableInAppNotifications: Bool {
        get { _enableInAppNotifications.wrappedValue }
        set { _enableInAppNotifications.wrappedValue = newValue }
    }
    var hideQuietNotificationAlerts: Bool {
        get { _hideQuietNotificationAlerts.wrappedValue }
        set { _hideQuietNotificationAlerts.wrappedValue = newValue }
    }
    var pusherProfileTag: String? {
        get { _pusherProfileTag.wrappedValue }
        set { _pusherProfileTag.wrappedValue = newValue }
    }
    var lastNotificationBootTime: TimeInterval? {
        get { _lastNotificationBootTime.wrappedValue }
        set { _lastNotificationBootTime.wrappedValue = newValue }
    }
    var selectedNotificationTone: NotificationTone? {
        get { _selectedNotificationTone.wrappedValue }
        set { _selectedNotificationTone.wrappedValue = newValue }
    }
    var selectedNotificationTonePublisher: AnyPublisher<NotificationTone?, Never> {
        _selectedNotificationTone.projectedValue
    }
    var logLevel: LogLevel {
        get { _logLevel.wrappedValue }
        set { _logLevel.wrappedValue = newValue }
    }
    var traceLogPacks: Set<TraceLogPack> {
        get { _traceLogPacks.wrappedValue }
        set { _traceLogPacks.wrappedValue = newValue }
    }
    var analyticsConsentState: AnalyticsConsentState {
        get { _analyticsConsentState.wrappedValue }
        set { _analyticsConsentState.wrappedValue = newValue }
    }
    var analyticsConsentStatePublisher: AnyPublisher<AnalyticsConsentState, Never> {
        _analyticsConsentState.projectedValue
    }
    var hasRunNotificationPermissionsOnboarding: Bool {
        get { _hasRunNotificationPermissionsOnboarding.wrappedValue }
        set { _hasRunNotificationPermissionsOnboarding.wrappedValue = newValue }
    }
    var hasRunIdentityConfirmationOnboarding: Bool {
        get { _hasRunIdentityConfirmationOnboarding.wrappedValue }
        set { _hasRunIdentityConfirmationOnboarding.wrappedValue = newValue }
    }
    var hasRequestedLocationAlwaysLocationAuthorization: Bool {
        get { _hasRequestedLocationAlwaysLocationAuthorization.wrappedValue }
        set { _hasRequestedLocationAlwaysLocationAuthorization.wrappedValue = newValue }
    }
    var frequentlyUsedSystemEmojis: [FrequentlyUsedEmoji] {
        get { _frequentlyUsedSystemEmojis.wrappedValue }
        set { _frequentlyUsedSystemEmojis.wrappedValue = newValue }
    }
    var liveLocationSharingSessionsByRoomID: [String: LiveLocationSession] {
        get { _liveLocationSharingSessionsByRoomID.wrappedValue }
        set { _liveLocationSharingSessionsByRoomID.wrappedValue = newValue }
    }
    var liveLocationSharingSessionsByRoomIDPublisher: AnyPublisher<[String: LiveLocationSession], Never> {
        _liveLocationSharingSessionsByRoomID.projectedValue
    }
    var liveLocationMinimumDistanceUpdate: Int {
        get { _liveLocationMinimumDistanceUpdate.wrappedValue }
        set { _liveLocationMinimumDistanceUpdate.wrappedValue = newValue }
    }
    var liveLocationMinimumDistanceUpdatePublisher: AnyPublisher<Int, Never> {
        _liveLocationMinimumDistanceUpdate.projectedValue
    }
    var liveLocationDisclaimerDisplayed: Bool {
        get { _liveLocationDisclaimerDisplayed.wrappedValue }
        set { _liveLocationDisclaimerDisplayed.wrappedValue = newValue }
    }
    var roomListActivityVisibility: RoomListActivityVisibility {
        get { _roomListActivityVisibility.wrappedValue }
        set { _roomListActivityVisibility.wrappedValue = newValue }
    }
    var roomListActivityVisibilityPublisher: AnyPublisher<RoomListActivityVisibility, Never> {
        _roomListActivityVisibility.projectedValue
    }
    var viewSourceEnabled: Bool {
        get { _viewSourceEnabled.wrappedValue }
        set { _viewSourceEnabled.wrappedValue = newValue }
    }
    var viewSourceEnabledPublisher: AnyPublisher<Bool, Never> {
        _viewSourceEnabled.projectedValue
    }
    var optimizeMediaUploads: Bool {
        get { _optimizeMediaUploads.wrappedValue }
        set { _optimizeMediaUploads.wrappedValue = newValue }
    }
    var voiceMessagePlaybackSpeed: AudioPlaybackSpeed {
        get { _voiceMessagePlaybackSpeed.wrappedValue }
        set { _voiceMessagePlaybackSpeed.wrappedValue = newValue }
    }
    var voiceMessagePlaybackSpeedPublisher: AnyPublisher<AudioPlaybackSpeed, Never> {
        _voiceMessagePlaybackSpeed.projectedValue
    }
    var elementCallBaseURLOverride: URL? {
        get { _elementCallBaseURLOverride.wrappedValue }
        set { _elementCallBaseURLOverride.wrappedValue = newValue }
    }
    var sharePresence: Bool {
        get { _sharePresence.wrappedValue }
        set { _sharePresence.wrappedValue = newValue }
    }
    var sharePresencePublisher: AnyPublisher<Bool, Never> {
        _sharePresence.projectedValue
    }
    var fuzzyRoomListSearchEnabled: Bool {
        get { _fuzzyRoomListSearchEnabled.wrappedValue }
        set { _fuzzyRoomListSearchEnabled.wrappedValue = newValue }
    }
    var lowPriorityFilterEnabled: Bool {
        get { _lowPriorityFilterEnabled.wrappedValue }
        set { _lowPriorityFilterEnabled.wrappedValue = newValue }
    }
    var enableOnlySignedDeviceIsolationMode: Bool {
        get { _enableOnlySignedDeviceIsolationMode.wrappedValue }
        set { _enableOnlySignedDeviceIsolationMode.wrappedValue = newValue }
    }
    var knockingEnabled: Bool {
        get { _knockingEnabled.wrappedValue }
        set { _knockingEnabled.wrappedValue = newValue }
    }
    var knockingEnabledPublisher: AnyPublisher<Bool, Never> {
        _knockingEnabled.projectedValue
    }
    var threadsEnabled: Bool {
        get { _threadsEnabled.wrappedValue }
        set { _threadsEnabled.wrappedValue = newValue }
    }
    var threadsEnabledPublisher: AnyPublisher<Bool, Never> {
        _threadsEnabled.projectedValue
    }
    var roomThreadListEnabled: Bool {
        get { _roomThreadListEnabled.wrappedValue }
        set { _roomThreadListEnabled.wrappedValue = newValue }
    }
    var roomThreadListEnabledPublisher: AnyPublisher<Bool, Never> {
        _roomThreadListEnabled.projectedValue
    }
    var globalSearchEnabled: Bool {
        get { _globalSearchEnabled.wrappedValue }
        set { _globalSearchEnabled.wrappedValue = newValue }
    }
    var focusEventOnNotificationTap: Bool {
        get { _focusEventOnNotificationTap.wrappedValue }
        set { _focusEventOnNotificationTap.wrappedValue = newValue }
    }
    var linkPreviewsEnabled: Bool {
        get { _linkPreviewsEnabled.wrappedValue }
        set { _linkPreviewsEnabled.wrappedValue = newValue }
    }
    var jumpToReadMarkerEnabled: Bool {
        get { _jumpToReadMarkerEnabled.wrappedValue }
        set { _jumpToReadMarkerEnabled.wrappedValue = newValue }
    }
    var jumpToReadMarkerEnabledPublisher: AnyPublisher<Bool, Never> {
        _jumpToReadMarkerEnabled.projectedValue
    }
    var linkNewDeviceEnabled: Bool {
        get { _linkNewDeviceEnabled.wrappedValue }
        set { _linkNewDeviceEnabled.wrappedValue = newValue }
    }
    var linkNewDeviceEnabledPublisher: AnyPublisher<Bool, Never> {
        _linkNewDeviceEnabled.projectedValue
    }
    var automaticBackPaginationEnabled: Bool {
        get { _automaticBackPaginationEnabled.wrappedValue }
        set { _automaticBackPaginationEnabled.wrappedValue = newValue }
    }
    var clientPausingAndResumingEnabled: Bool {
        get { _clientPausingAndResumingEnabled.wrappedValue }
        set { _clientPausingAndResumingEnabled.wrappedValue = newValue }
    }
    var developerOptionsEnabled: Bool {
        get { _developerOptionsEnabled.wrappedValue }
        set { _developerOptionsEnabled.wrappedValue = newValue }
    }
    var developerOptionsEnabledPublisher: AnyPublisher<Bool, Never> {
        _developerOptionsEnabled.projectedValue
    }
}
