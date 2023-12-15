//
// Copyright 2022 New Vector Ltd
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
import SwiftUI

typealias CallScreenViewModelType = StateStoreViewModel<CallScreenViewState, CallScreenViewAction>

class CallScreenViewModel: CallScreenViewModelType, CallScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    
    private let widgetDriver: ElementCallWidgetDriverProtocol
    
    private let callController = CXCallController()
    // periphery: ignore - call kit magic do not remove
    private let callProvider = CXProvider(configuration: .init())
    
    private let callID = UUID()
    
    private let actionsSubject: PassthroughSubject<CallScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CallScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    deinit {
        tearDownVoIPSession(callID: callID)
    }
    
    /// Designated initialiser
    /// - Parameters:
    ///   - roomProxy: The room in which the call should be created
    ///   - callBaseURL: Which Element Call instance should be used
    ///   - clientID: Something to identify the current client on the Element Call side
    init(roomProxy: RoomProxyProtocol,
         callBaseURL: URL,
         clientID: String,
         useEncryption: Bool) {
        self.roomProxy = roomProxy
        
        widgetDriver = roomProxy.elementCallWidgetDriver()
        
        super.init(initialViewState: CallScreenViewState(messageHandler: Self.eventHandlerName,
                                                         script: Self.eventHandlerInjectionScript))
        
        state.bindings.javaScriptMessageHandler = { [weak self] message in
            guard let self,
                  let message = message as? String else {
                return
            }
            
            Task {
                await self.widgetDriver.sendMessage(message)
            }
        }
        
        widgetDriver.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedMessage in
                guard let self else { return }
                
                Task {
                    do {
                        let message = "postMessage(\(receivedMessage), '*')"
                        let result = try await self.state.bindings.javaScriptEvaluator?(message)
                        MXLog.debug("Evaluated javascript: \(message) with result: \(String(describing: result))")
                    } catch {
                        MXLog.error("Received javascript evaluation error: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
        
        widgetDriver.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .callEnded:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
        
        Task {
            switch await widgetDriver.start(baseURL: callBaseURL, clientID: clientID, useEncryption: useEncryption) {
            case .success(let url):
                state.url = url
            case .failure(let error):
                MXLog.error("Failed starting ElementCall Widget Driver with error: \(error)")
                state.bindings.alertInfo = .init(id: UUID(), title: L10n.errorUnknown, primaryButton: .init(title: L10n.actionOk, action: { [weak self] in
                    self?.actionsSubject.send(.dismiss)
                }))
                
                return
            }
            
            do {
                try await setupVoIPSession(callID: callID)
            } catch {
                MXLog.error("Failed setting up VoIP session with error: \(error)")
            }
        }
    }
    
    override func process(viewAction: CallScreenViewAction) {
        switch viewAction {
        case .urlChanged(let url):
            guard let url else { return }
            MXLog.info("URL changed to: \(url)")
        }
    }
    
    // MARK: - CXCallObserverDelegate
    
    // periphery: ignore - call kit magic do not remove
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        MXLog.info("Call changed: \(call)")
    }
    
    // MARK: - CXProviderDelegate
    
    // periphery: ignore - call kit magic do not remove
    func providerDidReset(_ provider: CXProvider) {
        MXLog.info("Call provider did reset: \(provider)")
    }
    
    // MARK: - Private

    private static let eventHandlerName = "elementx"
    
    private static var eventHandlerInjectionScript: String {
        """
        window.addEventListener(
            "message",
            (event) => {
                let message = {data: event.data, origin: event.origin}
                if (message.data.response && message.data.api == "toWidget"
                || !message.data.response && message.data.api == "fromWidget") {
                  window.webkit.messageHandlers.\(eventHandlerName).postMessage(JSON.stringify(message.data));
                }else{
                  console.log("-- skipped event handling by the client because it is send from the client itself.");
                }
            },
            false,
          );
        """
    }
    
    private func evaluateJavaScript(_ script: String) async -> String? {
        guard let evaluator = state.bindings.javaScriptEvaluator else {
            fatalError("Invalid javaScriptEvaluator")
        }
        
        do {
            return try await evaluator(script) as? String
        } catch {
            MXLog.error("Failed evaluating javaScript with error: \(error)")
            return nil
        }
    }
    
    private func setupVoIPSession(callID: UUID) async throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: [])
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        
        let handle = CXHandle(type: .generic, value: roomProxy.roomTitle)
        let startCallAction = CXStartCallAction(call: callID, handle: handle)
        startCallAction.isVideo = true
        
        let transaction = CXTransaction(action: startCallAction)
        
        try await callController.request(transaction)
    }
    
    private nonisolated func tearDownVoIPSession(callID: UUID?) {
        guard let callID else {
            return
        }
        
        try? AVAudioSession.sharedInstance().setActive(false)
            
        let endCallAction = CXEndCallAction(call: callID)
        let transaction = CXTransaction(action: endCallAction)
        
        callController.request(transaction) { error in
            if let error {
                MXLog.error("Failed transaction with error: \(error)")
            }
        }
    }
}
