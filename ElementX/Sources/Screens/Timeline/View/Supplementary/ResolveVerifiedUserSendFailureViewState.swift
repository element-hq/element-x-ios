//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@MainActor
class ResolveVerifiedUserSendFailureViewState: ObservableObject {
    private let iterator: VerifiedUserSendFailureIterator
    private let info: TimelineItemSendFailureInfo
    private let context: TimelineViewModel.Context
    
    private var currentFailure: TimelineItemSendFailure.VerifiedUser
    @Published private var currentMemberDisplayName: String
    
    init(info: TimelineItemSendFailureInfo, context: TimelineViewModel.Context) {
        iterator = switch info.failure {
        case .hasUnsignedDevice(let devices): UnsignedDeviceFailureIterator(devices: devices)
        case .changedIdentity(let users): ChangedIdentityFailureIterator(users: users)
        }
        
        self.info = info
        self.context = context
        
        guard let (userID, failure) = iterator.next() else { fatalError() }
        currentMemberDisplayName = context.viewState.members[userID]?.displayName ?? userID
        currentFailure = failure
    }
    
    var title: String {
        switch info.failure {
        case .hasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolveTitle(currentMemberDisplayName)
        case .changedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolveTitle(currentMemberDisplayName)
        }
    }
    
    var subtitle: String {
        switch info.failure {
        case .hasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolveSubtitle(currentMemberDisplayName,
                                                                                                     currentMemberDisplayName)
        case .changedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolveSubtitle(currentMemberDisplayName)
        }
    }
    
    var primaryButtonTitle: String {
        switch info.failure {
        case .hasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolvePrimaryButtonTitle
        case .changedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolvePrimaryButtonTitle
        }
    }
    
    func resolveAndSend() {
        send(.resolveAndSend(failure: currentFailure, itemID: info.id), dismiss: false)
        
        if let (userID, failure) = iterator.next() {
            currentMemberDisplayName = context.viewState.members[userID]?.displayName ?? userID
            currentFailure = failure
        } else {
            context.sendFailureInfo = nil
        }
    }
    
    func retry() {
        send(.retrySending(itemID: info.id))
    }
    
    func cancel() {
        send(.cancel)
    }
    
    private func send(_ action: TimelineSendFailureAction, dismiss: Bool = true) {
        context.send(viewAction: .handleTimelineSendFailureAction(action))
        
        if dismiss {
            context.sendFailureInfo = nil
        }
    }
}

@MainActor
protocol VerifiedUserSendFailureIterator {
    func next() -> (userID: String, failure: TimelineItemSendFailure.VerifiedUser)?
}

class UnsignedDeviceFailureIterator: VerifiedUserSendFailureIterator {
    private var iterator: [String: [String]].Iterator
    
    init(devices: [String: [String]]) {
        iterator = devices.makeIterator()
    }
    
    func next() -> (userID: String, failure: TimelineItemSendFailure.VerifiedUser)? {
        guard let nextUserDevices = iterator.next() else { return nil }
        return (nextUserDevices.key, .hasUnsignedDevice(devices: [nextUserDevices.key: nextUserDevices.value]))
    }
}

class ChangedIdentityFailureIterator: VerifiedUserSendFailureIterator {
    private var iterator: [String].Iterator
    
    init(users: [String]) {
        iterator = users.makeIterator()
    }
    
    func next() -> (userID: String, failure: TimelineItemSendFailure.VerifiedUser)? {
        guard let nextUserID = iterator.next() else { return nil }
        return (nextUserID, .changedIdentity(users: [nextUserID]))
    }
}
