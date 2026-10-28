//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import Combine
import SwiftUI

struct CallFlowCoordinatorParameters {
    let navigationRootCoordinator: NavigationRootCoordinator
    let userSessionManager: UserSessionManagerProtocol
    let elementCallService: ElementCallServiceProtocol
    let elementCallManager: ElementCallManagerProtocol
    let windowManager: WindowManagerProtocol
    let analytics: AnalyticsServiceProtocol
}

/// Presents the call screens of every account above the app's root, so they outlive the account's screens.
/// A native call on a Mac gets its own window instead.
final class CallFlowCoordinator {
    /// The web call on the overlay, with everything that belongs to that call alone.
    private struct WebCall {
        let userSession: UserSessionProtocol
        let roomID: String
        let coordinator: CallScreenCoordinator
        var pictureInPictureController: AVPictureInPictureController?
        var cancellables: Set<AnyCancellable>
    }
    
    /// A call by account, answered through CallKit or started from Recents, waiting for its account's session to be live.
    private struct PendingCall {
        let userID: String
        let roomID: String
        let isVoiceCall: Bool
        let isAnswered: Bool
    }
    
    /// An account that is leaving, remembered by the client it had when its calls ended.
    /// That client is nil when the account had no session yet.
    private struct BlockedAccount {
        weak var clientProxy: ClientProxyProtocol?
    }
    
    private let parameters: CallFlowCoordinatorParameters
    
    private var navigationRootCoordinator: NavigationRootCoordinator {
        parameters.navigationRootCoordinator
    }
    
    private var elementCallService: ElementCallServiceProtocol {
        parameters.elementCallService
    }
    
    private var webCall: WebCall?
    private var pendingCall: PendingCall?
    private var blockedUserIDs: [String: BlockedAccount] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: CallFlowCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func start() {
        elementCallService.nativeCallPresentationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] presentation in
                self?.handleNativeCall(presentation)
            }
            .store(in: &cancellables)
        
        // Not received on the main queue, so that a change of sessions is seen in the same step that makes it.
        parameters.userSessionManager.sessionsPublisher
            .sink { [weak self] userSessions in
                self?.unblockAccounts(whoseSessionChangedIn: userSessions)
                self?.openPendingCall(ifSessionIsLiveIn: userSessions)
            }
            .store(in: &cancellables)
    }
    
    /// Opens a call that comes in by account, answered through CallKit or started from Recents.
    ///
    /// An account with no live session yet has its call held until it has one, one call at a time.
    /// A call that can't open, or whose account is leaving, is dropped.
    func presentCall(userID: String, roomID: String, isVoiceCall: Bool, isAnswered: Bool) {
        guard parameters.userSessionManager.userIDs.contains(userID) else {
            drop(roomID: roomID, isAnswered: isAnswered, because: "\(userID) isn't signed in")
            return
        }
        
        guard blockedUserIDs[userID] == nil else {
            drop(roomID: roomID, isAnswered: isAnswered, because: "\(userID) is leaving")
            return
        }
        
        guard let userSession = parameters.userSessionManager.session(for: userID) else {
            hold(PendingCall(userID: userID, roomID: roomID, isVoiceCall: isVoiceCall, isAnswered: isAnswered))
            return
        }
        
        Task {
            guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
                drop(roomID: roomID, isAnswered: isAnswered, because: "it isn't a joined room")
                return
            }
            
            presentCall(roomProxy: roomProxy, isVoiceCall: isVoiceCall, userSession: userSession)
        }
    }
    
    /// Opens the room's call as the session's account, returning to it when it's already open.
    /// Any other call is replaced.
    func presentCall(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool, userSession: UserSessionProtocol) {
        // The service runs native calls and drives their screen through its presentation publisher.
        if elementCallService.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: isVoiceCall) {
            return
        }
        
        if let webCall,
           webCall.userSession.clientProxy.userID == userSession.clientProxy.userID,
           webCall.roomID == roomProxy.id {
            MXLog.info("Returning to the ongoing call.")
            webCall.pictureInPictureController?.stopPictureInPicture()
            return
        }
        
        presentWebCall(roomProxy: roomProxy, isVoiceCall: isVoiceCall, userSession: userSession)
    }
    
    /// Hides the call screen: a native call minimizes, a web call moves to picture in picture or ends without it.
    func minimizeCall() {
        if navigationRootCoordinator.overlayCoordinator is NativeCallScreenCoordinator {
            elementCallService.minimizeNativeCall()
            return
        }
        
        guard let webCall else { return }
        
        guard let pictureInPictureController = webCall.pictureInPictureController else {
            MXLog.warning("Picture in picture isn't available, dismissing the call screen.")
            navigationRootCoordinator.setOverlayCoordinator(nil)
            return
        }
        
        MXLog.info("Starting picture in picture to hide the call screen.")
        pictureInPictureController.startPictureInPicture()
        navigationRootCoordinator.setOverlayPresentationMode(.minimized)
    }
    
    /// Ends the account's calls ahead of its session going away, and drops its new calls until its session changes.
    func endCalls(userID: String) async {
        blockedUserIDs[userID] = BlockedAccount(clientProxy: parameters.userSessionManager.session(for: userID)?.clientProxy)
        
        if let call = pendingCall, call.userID == userID {
            pendingCall = nil
            drop(roomID: call.roomID, isAnswered: call.isAnswered, because: "\(userID) is leaving")
        }
        
        if let webCall, webCall.userSession.clientProxy.userID == userID {
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
    
    // MARK: - Calls by account
    
    /// An account that's re-added, replaced or removed no longer has the client it had when it was blocked.
    private func unblockAccounts(whoseSessionChangedIn userSessions: [UserSessionProtocol]) {
        blockedUserIDs = blockedUserIDs.filter { userID, blockedAccount in
            let clientProxy = userSessions.first { $0.clientProxy.userID == userID }?.clientProxy
            return clientProxy === blockedAccount.clientProxy
        }
    }
    
    private func openPendingCall(ifSessionIsLiveIn userSessions: [UserSessionProtocol]) {
        guard let call = pendingCall,
              userSessions.contains(where: { $0.clientProxy.userID == call.userID }) else {
            return
        }
        
        pendingCall = nil
        
        // The app builds the session's native call stack right after adding it,
        // and a call that opens before then falls back to the web view.
        Task {
            presentCall(userID: call.userID, roomID: call.roomID, isVoiceCall: call.isVoiceCall, isAnswered: call.isAnswered)
        }
    }
    
    private func hold(_ call: PendingCall) {
        if let replacedCall = pendingCall {
            drop(roomID: replacedCall.roomID, isAnswered: replacedCall.isAnswered, because: "a newer call replaced it")
        }
        
        MXLog.info("Holding the call in \(call.roomID) until \(call.userID) has a live session")
        pendingCall = call
    }
    
    private func drop(roomID: String, isAnswered: Bool, because reason: String) {
        MXLog.warning("Dropping the call in \(roomID): \(reason)")
        
        if isAnswered {
            parameters.elementCallManager.dropAnsweredCall(roomID: roomID)
        }
    }
    
    // MARK: - Web calls
    
    private func presentWebCall(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool, userSession: UserSessionProtocol) {
        let colorScheme: ColorScheme = parameters.windowManager.mainWindow.traitCollection.userInterfaceStyle == .light ? .light : .dark
        let configuration = ElementCallConfiguration(roomProxy: roomProxy,
                                                     clientProxy: userSession.clientProxy,
                                                     clientID: InfoPlistReader.main.bundleIdentifier,
                                                     elementCallBaseURL: userSession.userSettings.app.elementCallBaseURL,
                                                     elementCallBaseURLOverride: userSession.userSettings.app.elementCallBaseURLOverride,
                                                     voiceOnly: isVoiceCall,
                                                     colorScheme: colorScheme)
        
        let coordinator = CallScreenCoordinator(parameters: .init(elementCallService: elementCallService,
                                                                  configuration: configuration,
                                                                  allowPictureInPicture: true,
                                                                  userSettings: userSession.userSettings,
                                                                  analytics: parameters.analytics))
        
        var callCancellables = Set<AnyCancellable>()
        coordinator.actions
            .sink { [weak self, weak coordinator] action in
                guard let self, let coordinator else { return }
                handleWebCallAction(action, coordinator: coordinator)
            }
            .store(in: &callCancellables)
        
        // Replacing the screen runs its `stop()`, ending the call, and then this callback.
        // It must only ever clear this call's record, never the one replacing it.
        navigationRootCoordinator.setOverlayCoordinator(coordinator) { [weak self, weak coordinator] in
            guard let self, webCall?.coordinator === coordinator else { return }
            webCall = nil
        }
        
        webCall = WebCall(userSession: userSession,
                          roomID: roomProxy.id,
                          coordinator: coordinator,
                          pictureInPictureController: nil,
                          cancellables: callCancellables)
        
        parameters.analytics.track(screen: .RoomCall)
    }
    
    private func handleWebCallAction(_ action: CallScreenCoordinatorAction, coordinator: CallScreenCoordinator) {
        // A replaced call's late actions must leave the call that replaced it alone.
        guard navigationRootCoordinator.overlayCoordinator === coordinator else { return }
        
        switch action {
        case .pictureInPictureIsAvailable(let controller):
            webCall?.pictureInPictureController = controller
        case .pictureInPictureStarted:
            MXLog.info("Hiding the call for picture in picture.")
            navigationRootCoordinator.setOverlayPresentationMode(.minimized)
        case .pictureInPictureStopped:
            MXLog.info("Restoring the call after picture in picture.")
            navigationRootCoordinator.setOverlayPresentationMode(.fullScreen)
        case .dismiss:
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
    
    // MARK: - Native calls
    
    private func handleNativeCall(_ presentation: NativeCallPresentation) {
        switch presentation {
        case .present:
            presentNativeCall()
        case .restore:
            restoreNativeCall()
        case .minimize:
            navigationRootCoordinator.setOverlayPresentationMode(.minimized)
        case .dismiss:
            dismissNativeCall()
        }
    }
    
    private func presentNativeCall() {
        guard let controller = elementCallService.nativeCallController else {
            MXLog.error("Cannot present a native call without a call stack")
            return
        }
        
        guard !(navigationRootCoordinator.overlayCoordinator is NativeCallScreenCoordinator) else {
            restoreNativeCall()
            return
        }
        
        let coordinator = NativeCallScreenCoordinator(parameters: .init(controller: controller))
        
        if ProcessInfo.processInfo.isiOSAppOnMac {
            parameters.windowManager.closeSecondaryWindow(forType: .call)
            parameters.windowManager.registerCoordinator(coordinator, flowCoordinator: nil, forWindowType: .call)
        } else {
            navigationRootCoordinator.setOverlayCoordinator(coordinator)
            parameters.analytics.track(screen: .RoomCall)
        }
    }
    
    private func restoreNativeCall() {
        elementCallService.restoreNativeCall()
        navigationRootCoordinator.setOverlayPresentationMode(.fullScreen)
    }
    
    private func dismissNativeCall() {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            parameters.windowManager.closeSecondaryWindow(forType: .call)
        } else if navigationRootCoordinator.overlayCoordinator is NativeCallScreenCoordinator {
            navigationRootCoordinator.setOverlayCoordinator(nil)
        }
    }
}
