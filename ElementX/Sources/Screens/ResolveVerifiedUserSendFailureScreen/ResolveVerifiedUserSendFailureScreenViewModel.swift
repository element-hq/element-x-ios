//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ResolveVerifiedUserSendFailureScreenViewModelType = StateStoreViewModelV2<ResolveVerifiedUserSendFailureScreenViewState, ResolveVerifiedUserSendFailureScreenViewAction>

class ResolveVerifiedUserSendFailureScreenViewModel: ResolveVerifiedUserSendFailureScreenViewModelType, ResolveVerifiedUserSendFailureScreenViewModelProtocol {
    private let iterator: VerifiedUserSendFailureIterator
    private let failure: TimelineItemSendFailure.VerifiedUser
    private let sendHandle: SendHandleProxy
    private let roomProxy: JoinedRoomProxyProtocol
    private var members: [String: RoomMemberProxyProtocol]
    
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<ResolveVerifiedUserSendFailureScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ResolveVerifiedUserSendFailureScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(failure: TimelineItemSendFailure.VerifiedUser,
         sendHandle: SendHandleProxy,
         roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        iterator = switch failure {
        case .hasUnsignedDevice(let devices): UnsignedDeviceFailureIterator(devices: devices)
        case .changedIdentity(let users): ChangedIdentityFailureIterator(users: users)
        }
        
        self.failure = failure
        self.sendHandle = sendHandle
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        
        members = Dictionary(uniqueKeysWithValues: roomProxy.membersPublisher.value.map { ($0.userID, $0) })
        
        guard let (userID, failure) = iterator.next() else {
            MXLog.error("There aren't any known users/devices to resolve the failure with.")
            fatalError("There aren't any known users/devices to resolve the failure with.")
        }
        
        super.init(initialViewState: ResolveVerifiedUserSendFailureScreenViewState(currentFailure: failure,
                                                                                   currentMemberDisplayName: members[userID]?.displayName ?? userID,
                                                                                   isYou: userID == roomProxy.ownUserID))
    }
    
    // MARK: Public
    
    override func process(viewAction: ResolveVerifiedUserSendFailureScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .resolveAndResend:
            Task { await resolveAndResend() }
        case .resend:
            Task { await resend() }
        case .cancel:
            actionsSubject.send(.dismiss)
        }
    }
    
    private func resolveAndResend() async {
        let result = switch failure {
        case .hasUnsignedDevice(let devices):
            await roomProxy.ignoreDeviceTrustAndResend(devices: devices, sendHandle: sendHandle)
        case .changedIdentity(let users):
            await roomProxy.withdrawVerificationAndResend(userIDs: users, sendHandle: sendHandle)
        }
        
        if case let .failure(error) = result {
            MXLog.error("Failed to resolve send failure: \(error)")
            showFailureIndicator()
            return
        }
        
        if let (userID, failure) = iterator.next() {
            state.currentMemberDisplayName = members[userID]?.displayName ?? userID
            state.currentFailure = failure
            state.isYou = userID == roomProxy.ownUserID
        } else {
            actionsSubject.send(.dismiss)
        }
    }
    
    private func resend() async {
        switch await sendHandle.resend() {
        case .success:
            actionsSubject.send(.dismiss)
        case .failure(let error):
            MXLog.error("Failed to resend message: \(error)")
            showFailureIndicator()
        }
    }
    
    private static let failureIndicatorIdentifier = "\(ResolveVerifiedUserSendFailureScreenViewModel.self)-Failure"
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorIdentifier,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}

// MARK: - Iterators

@MainActor
private protocol VerifiedUserSendFailureIterator {
    func next() -> (userID: String, failure: TimelineItemSendFailure.VerifiedUser)?
}

private class UnsignedDeviceFailureIterator: VerifiedUserSendFailureIterator {
    private var iterator: [String: [String]].Iterator
    
    init(devices: [String: [String]]) {
        iterator = devices.makeIterator()
    }
    
    func next() -> (userID: String, failure: TimelineItemSendFailure.VerifiedUser)? {
        guard let nextUserDevices = iterator.next() else { return nil }
        return (nextUserDevices.key, .hasUnsignedDevice(devices: [nextUserDevices.key: nextUserDevices.value]))
    }
}

private class ChangedIdentityFailureIterator: VerifiedUserSendFailureIterator {
    private var iterator: [String].Iterator
    
    init(users: [String]) {
        iterator = users.makeIterator()
    }
    
    func next() -> (userID: String, failure: TimelineItemSendFailure.VerifiedUser)? {
        guard let nextUserID = iterator.next() else { return nil }
        return (nextUserID, .changedIdentity(users: [nextUserID]))
    }
}
