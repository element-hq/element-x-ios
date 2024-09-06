//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVFoundation
import CallKit
import Combine
import Foundation
import PushKit
import UIKit

class ElementCallService: NSObject, ElementCallServiceProtocol, PKPushRegistryDelegate, CXProviderDelegate {
    private struct CallID: Equatable {
        let callKitID: UUID
        let roomID: String
    }
    
    private let pushRegistry: PKPushRegistry
    private let callController = CXCallController()
    private let callProvider: CXProvider = {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.includesCallsInRecents = true
        
        if let callKitIcon = UIImage(named: "images/app-logo") {
            configuration.iconTemplateImageData = callKitIcon.pngData()
        }
        
        // https://stackoverflow.com/a/46077628/730924
        configuration.supportedHandleTypes = [.generic]
        
        return CXProvider(configuration: configuration)
    }()
    
    private weak var clientProxy: ClientProxyProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var incomingCallID: CallID? {
        didSet {
            Task {
                await observeIncomingCallRoomStateUpdates()
            }
        }
    }
    
    private var endUnansweredCallTask: Task<Void, Never>?
    
    private var ongoingCallID: CallID? {
        didSet { ongoingCallRoomIDSubject.send(ongoingCallID?.roomID) }
    }
    
    let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(nil)
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        ongoingCallRoomIDSubject.asCurrentValuePublisher()
    }
    
    private let actionsSubject: PassthroughSubject<ElementCallServiceAction, Never> = .init()
    var actions: AnyPublisher<ElementCallServiceAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    override init() {
        pushRegistry = PKPushRegistry(queue: nil)
        
        super.init()
        
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        
        callProvider.setDelegate(self, queue: nil)
    }
    
    func setClientProxy(_ clientProxy: any ClientProxyProtocol) {
        self.clientProxy = clientProxy
    }
    
    func setupCallSession(roomID: String, roomDisplayName: String) async {
        // Drop any ongoing calls when starting a new one
        if ongoingCallID != nil {
            tearDownCallSession()
        }
        
        // If this starting from a ring reuse those identifiers
        // Make sure the roomID matches
        let callID = if let incomingCallID, incomingCallID.roomID == roomID {
            incomingCallID
        } else {
            CallID(callKitID: UUID(), roomID: roomID)
        }
        
        incomingCallID = nil
        ongoingCallID = callID
        
        let handle = CXHandle(type: .generic, value: roomDisplayName)
        let startCallAction = CXStartCallAction(call: callID.callKitID, handle: handle)
        startCallAction.isVideo = true
        
        do {
            try await callController.request(CXTransaction(action: startCallAction))
        } catch {
            MXLog.error("Failed requesting start call action with error: \(error)")
        }
    }
    
    func tearDownCallSession() {
        tearDownCallSession(sendEndCallAction: true)
    }
    
    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        guard let ongoingCallID else {
            MXLog.error("Failed toggling call microphone, no calls running")
            return
        }
        
        guard ongoingCallID.roomID == roomID else {
            MXLog.error("Failed toggling call microphone, rooms don't match: \(ongoingCallID.roomID) != \(roomID)")
            return
        }
        
        let transaction = CXTransaction(action: CXSetMutedCallAction(call: ongoingCallID.callKitID, muted: !enabled))
        callController.request(transaction) { error in
            if let error {
                MXLog.error("Failed toggling call microphone with error: \(error)")
            }
        }
    }

    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) { }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard let roomID = payload.dictionaryPayload[ElementCallServiceNotificationKey.roomID.rawValue] as? String else {
            MXLog.error("Something went wrong, missing room identifier for incoming voip call: \(payload)")
            return
        }
        
        guard ongoingCallID?.roomID != roomID else {
            MXLog.warning("Call already ongoing for room \(roomID), ignoring incoming push")
            return
        }
        
        let callID = CallID(callKitID: UUID(), roomID: roomID)
        incomingCallID = callID
        
        let roomDisplayName = payload.dictionaryPayload[ElementCallServiceNotificationKey.roomDisplayName.rawValue] as? String
        
        let update = CXCallUpdate()
        update.hasVideo = true
        update.localizedCallerName = roomDisplayName
        // https://stackoverflow.com/a/41230020/730924
        update.remoteHandle = .init(type: .generic, value: roomID)
        
        callProvider.reportNewIncomingCall(with: callID.callKitID, update: update) { error in
            if let error {
                MXLog.error("Failed reporting new incoming call with error: \(error)")
            }
            
            completion()
        }
        
        endUnansweredCallTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            
            guard let self, !Task.isCancelled else {
                return
            }
            
            if let incomingCallID, incomingCallID.callKitID == callID.callKitID {
                callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .unanswered)
            }
        }
    }
    
    // MARK: - CXProviderDelegate
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did activate audio session")
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did deactivate audio session")
    }
    
    func providerDidReset(_ provider: CXProvider) {
        MXLog.info("Call provider did reset: \(provider)")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let incomingCallID else {
            MXLog.error("Failed answering incoming call, missing incomingCallID")
            return
        }
        
        // Fixes broken videos on EC web when a CallKit session is established.
        //
        // Reporting an ongoing call through `reportNewIncomingCall` + `CXAnswerCallAction`
        // or `reportOutgoingCall:connectedAt:` will give exclusive access for media to the
        // ongoing process, which is different than the WKWebKit is running on, making EC
        // unable to aquire media streams.
        // Reporting the call as ended imediately after answering it works around that
        // as EC gets access to media again and EX builds the right UI in `setupCallSession`
        //
        // https://github.com/element-hq/element-x-ios/issues/3041
        // https://forums.developer.apple.com/forums/thread/685268
        // https://stackoverflow.com/questions/71483732/webrtc-running-from-wkwebview-avaudiosession-development-roadblock
        
        // First fullfill the action
        action.fulfill()
        
        // And delay ending the call so that the app has enough time
        // to get deeplinked into
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then end the and call rely on `setupCallSession` to create a new one
            provider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .remoteEnded)
            
            self.actionsSubject.send(.startCall(roomID: incomingCallID.roomID))
            self.endUnansweredCallTask?.cancel()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if let ongoingCallID {
            actionsSubject.send(.setAudioEnabled(!action.isMuted, roomID: ongoingCallID.roomID))
        } else {
            MXLog.error("Failed muting/unmuting call, missing ongoingCallID")
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        #if targetEnvironment(simulator)
        // This gets called for no reason on simulators, where CallKit
        // isn't even supported. Ignore
        return
        #endif
        
        if let ongoingCallID {
            actionsSubject.send(.endCall(roomID: ongoingCallID.roomID))
        }
        
        tearDownCallSession(sendEndCallAction: false)
        
        action.fulfill()
    }
    
    // MARK: - Private
    
    func tearDownCallSession(sendEndCallAction: Bool = true) {
        if sendEndCallAction, let ongoingCallID {
            let transaction = CXTransaction(action: CXEndCallAction(call: ongoingCallID.callKitID))
            callController.request(transaction) { error in
                if let error {
                    MXLog.error("Failed transaction with error: \(error)")
                }
            }
        }
        
        ongoingCallID = nil
    }
    
    func observeIncomingCallRoomStateUpdates() async {
        cancellables.removeAll()
        
        guard let clientProxy, let incomingCallID else {
            return
        }
        
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(incomingCallID.roomID) else {
            return
        }
        
        roomProxy.subscribeToRoomInfoUpdates()
        
        // There's no incoming event for call cancellations so try to infer
        // it from what we have. If the call is running before subscribing then wait
        // for it to change to `false` otherwise wait for it to turn `true` before
        // changing to `false`
        let isCallOngoing = roomProxy.hasOngoingCall
        
        roomProxy
            .actionsPublisher
            .map { action -> (Bool, [String]) in
                switch action {
                case .roomInfoUpdate:
                    return (roomProxy.hasOngoingCall, roomProxy.activeRoomCallParticipants)
                }
            }
            .removeDuplicates { $0 == $1 }
            .dropFirst(isCallOngoing ? 0 : 1)
            .sink { [weak self] hasOngoingCall, activeRoomCallParticipants in
                guard let self else { return }
                
                let participants: [String] = activeRoomCallParticipants
                
                if !hasOngoingCall {
                    MXLog.info("Call cancelled by remote")
                    
                    cancellables.removeAll()
                    endUnansweredCallTask?.cancel()
                    callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .remoteEnded)
                } else if participants.contains(roomProxy.ownUserID) {
                    MXLog.info("Call anwered elsewhere")
                    
                    cancellables.removeAll()
                    endUnansweredCallTask?.cancel()
                    callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .answeredElsewhere)
                }
            }
            .store(in: &cancellables)
    }
}
