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
    
    private var incomingCallID: CallID?
    private var endUnansweredCallTask: Task<Void, Never>?
    
    private var ongoingCallID: CallID?
    
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
        
        do { // Setup the audio session even if setting up CallKit failed, ElementCall **is** running at this point
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            MXLog.error("Failed setting up audio session with error: \(error)")
        }
    }
    
    func tearDownCallSession() {
        tearDownCallSession(sendEndCallAction: true)
    }

    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) { }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard let roomID = payload.dictionaryPayload[ElementCallServiceNotificationKey.roomID.rawValue] as? String else {
            MXLog.error("Something went wrong, missing room identifier for incoming voip call: \(payload)")
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
    
    func providerDidReset(_ provider: CXProvider) {
        MXLog.info("Call provider did reset: \(provider)")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        if let ongoingCallID {
            provider.reportOutgoingCall(with: ongoingCallID.callKitID, connectedAt: nil)
        } else {
            MXLog.error("Failed starting call, missing ongoingCallID")
        }

        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if let incomingCallID {
            actionsSubject.send(.startCall(roomID: incomingCallID.roomID))
            endUnansweredCallTask?.cancel()
        } else {
            MXLog.error("Failed answering incoming call, missing incomingCallID")
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        // Forward this to the widget somehow
        // webView.evaluateJavaScript("groupCall.setLocalVideoMuted(!groupCall.isLocalVideoMuted())")
        // webView.evaluateJavaScript("groupCall.setMicrophoneMuted(!groupCall.isMicrophoneMuted())"
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if let ongoingCallID {
            actionsSubject.send(.endCall(roomID: ongoingCallID.roomID))
        }
        
        tearDownCallSession(sendEndCallAction: false)
        
        action.fulfill()
    }
    
    // MARK: - Private
    
    func tearDownCallSession(sendEndCallAction: Bool = true) {
        try? AVAudioSession.sharedInstance().setActive(false)
        
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
}
