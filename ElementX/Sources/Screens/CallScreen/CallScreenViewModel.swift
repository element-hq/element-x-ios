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

import CallKit
import Combine
import SwiftUI

typealias CallScreenViewModelType = StateStoreViewModel<CallScreenViewState, CallScreenViewAction>

class CallScreenViewModel: CallScreenViewModelType, CallScreenViewModelProtocol {
    private let elementCallService: ElementCallServiceProtocol
    private let roomProxy: RoomProxyProtocol
    
    private let widgetDriver: ElementCallWidgetDriverProtocol
    
    private let actionsSubject: PassthroughSubject<CallScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CallScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// Designated initialiser
    /// - Parameters:
    ///   - elementCallService: service responsible for setting up CallKit
    ///   - roomProxy: The room in which the call should be created
    ///   - callBaseURL: Which Element Call instance should be used
    ///   - clientID: Something to identify the current client on the Element Call side
    init(elementCallService: ElementCallServiceProtocol,
         clientProxy: ClientProxyProtocol,
         roomProxy: RoomProxyProtocol,
         clientID: String,
         elementCallBaseURL: URL,
         elementCallBaseURLOverride: URL?,
         colorScheme: ColorScheme,
         appHooks: AppHooks) {
        guard let deviceID = clientProxy.deviceID else { fatalError("Missing device ID for the call.") }
        
        self.elementCallService = elementCallService
        self.roomProxy = roomProxy
        
        widgetDriver = roomProxy.elementCallWidgetDriver(deviceID: deviceID)
        
        super.init(initialViewState: CallScreenViewState(messageHandler: Self.eventHandlerName,
                                                         script: Self.eventHandlerInjectionScript,
                                                         certificateValidator: appHooks.certificateValidatorHook))
        
        state.bindings.javaScriptMessageHandler = { [weak self] message in
            guard let self,
                  let message = message as? String else {
                return
            }
            
            Task {
                await self.widgetDriver.sendMessage(message)
            }
        }
        
        elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case let .setAudioEnabled(enabled, roomID):
                    guard roomID == roomProxy.id else {
                        MXLog.error("Received mute request for a different room: \(roomID) != \(roomProxy.id)")
                        return
                    }
                    
                    Task {
                        await self.setAudioEnabled(enabled)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        widgetDriver.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedMessage in
                guard let self else { return }
                
                Task {
                    await self.postJSONToWidget(receivedMessage)
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
                case .mediaStateChanged(let audioEnabled, _):
                    elementCallService.setAudioEnabled(audioEnabled, roomID: roomProxy.id)
                }
            }
            .store(in: &cancellables)
        
        Task {
            let baseURL = if let elementCallBaseURLOverride {
                elementCallBaseURLOverride
            } else if case .success(let wellKnown) = await clientProxy.getElementWellKnown(), let wellKnownCall = wellKnown?.call {
                wellKnownCall.widgetURL
            } else {
                elementCallBaseURL
            }
            
            switch await widgetDriver.start(baseURL: baseURL, clientID: clientID, colorScheme: colorScheme) {
            case .success(let url):
                state.url = url
            case .failure(let error):
                MXLog.error("Failed starting ElementCall Widget Driver with error: \(error)")
                state.bindings.alertInfo = .init(id: UUID(), title: L10n.errorUnknown, primaryButton: .init(title: L10n.actionOk, action: { [weak self] in
                    self?.actionsSubject.send(.dismiss)
                }))
                
                return
            }
            
            await elementCallService.setupCallSession(roomID: roomProxy.id, roomDisplayName: roomProxy.roomTitle)
            
            let _ = await roomProxy.sendCallNotificationIfNeeeded()
        }
    }
    
    override func process(viewAction: CallScreenViewAction) {
        switch viewAction {
        case .urlChanged(let url):
            guard let url else { return }
            MXLog.info("URL changed to: \(url)")
        }
    }
    
    func stop() {
        Task {
            await hangup()
        }
        
        elementCallService.tearDownCallSession()
    }
    
    // MARK: - Private
    
    private func setAudioEnabled(_ enabled: Bool) async {
        let message = ElementCallWidgetMessage(direction: .toWidget,
                                               action: .mediaState,
                                               data: .init(audioEnabled: enabled),
                                               widgetId: widgetDriver.widgetID)
        await postMessageToWidget(message)
    }
    
    func hangup() async {
        let message = ElementCallWidgetMessage(direction: .fromWidget,
                                               action: .hangup,
                                               widgetId: widgetDriver.widgetID)
        
        await postMessageToWidget(message)
    }
    
    private func postMessageToWidget(_ message: ElementCallWidgetMessage) async {
        do {
            let data = try JSONEncoder().encode(message)
            let json = String(decoding: data, as: UTF8.self)
            _ = await widgetDriver.sendMessage(json)
            
            await postJSONToWidget(json)
        } catch {
            MXLog.error("Failed encoding widget message with error: \(error)")
        }
    }
    
    private func postJSONToWidget(_ json: String) async {
        do {
            let message = "postMessage(\(json), '*')"
            let result = try await state.bindings.javaScriptEvaluator?(message)
            MXLog.debug("Evaluated javascript: \(json) with result: \(String(describing: result))")
        } catch {
            MXLog.error("Received javascript evaluation error: \(error)")
        }
    }
    
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
}
