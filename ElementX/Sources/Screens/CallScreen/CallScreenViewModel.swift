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

import AVKit
import CallKit
import Combine
import SwiftUI

typealias CallScreenViewModelType = StateStoreViewModel<CallScreenViewState, CallScreenViewAction>

class CallScreenViewModel: CallScreenViewModelType, CallScreenViewModelProtocol {
    private let elementCallService: ElementCallServiceProtocol
    private let configuration: ElementCallConfiguration
    private let isPictureInPictureEnabled: Bool
    
    private let widgetDriver: ElementCallWidgetDriverProtocol
    
    private let actionsSubject: PassthroughSubject<CallScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CallScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var syncUpdateCancellable: AnyCancellable?
    
    /// Designated initialiser
    /// - Parameters:
    ///   - elementCallService: service responsible for setting up CallKit
    ///   - roomProxy: The room in which the call should be created
    ///   - callBaseURL: Which Element Call instance should be used
    ///   - clientID: Something to identify the current client on the Element Call side
    init(elementCallService: ElementCallServiceProtocol,
         configuration: ElementCallConfiguration,
         elementCallPictureInPictureEnabled: Bool,
         appHooks: AppHooks) {
        self.elementCallService = elementCallService
        self.configuration = configuration
        isPictureInPictureEnabled = elementCallPictureInPictureEnabled
        
        switch configuration.kind {
        case .genericCallLink(let url):
            widgetDriver = GenericCallLinkWidgetDriver(url: url)
        case .roomCall(let roomProxy, let clientProxy, _, _, _, _):
            guard let deviceID = clientProxy.deviceID else { fatalError("Missing device ID for the call.") }
            widgetDriver = roomProxy.elementCallWidgetDriver(deviceID: deviceID)
        }
        
        super.init(initialViewState: CallScreenViewState(messageHandler: Self.eventHandlerName,
                                                         script: Self.eventHandlerInjectionScript,
                                                         certificateValidator: appHooks.certificateValidatorHook))
        
        state.bindings.javaScriptMessageHandler = { [weak self] message in
            guard let self, let message = message as? String else { return }
            Task { await self.widgetDriver.handleMessage(message) }
        }
        
        elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case let .setAudioEnabled(enabled, roomID):
                    guard roomID == configuration.callRoomID else {
                        MXLog.error("Received mute request for a different room: \(roomID) != \(configuration.callRoomID)")
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
                    elementCallService.setAudioEnabled(audioEnabled, roomID: configuration.callRoomID)
                }
            }
            .store(in: &cancellables)
        
        setupCall()
    }
    
    override func process(viewAction: CallScreenViewAction) {
        switch viewAction {
        case .urlChanged(let url):
            guard let url else { return }
            MXLog.info("URL changed to: \(url)")
        case .navigateBack:
            Task { await handleBackwardsNavigation() }
        case .pictureInPictureWillStop:
            actionsSubject.send(.pictureInPictureStopped)
        case .endCall:
            actionsSubject.send(.dismiss)
        }
    }
    
    func stop() {
        Task {
            await hangup()
        }
        
        elementCallService.tearDownCallSession()
    }
    
    // MARK: - Private
    
    private func setupCall() {
        switch configuration.kind {
        case .genericCallLink(let url):
            state.url = url
            // We need widget messaging to work before enabling CallKit, otherwise mute, hangup etc do nothing.
        
        case .roomCall(let roomProxy, let clientProxy, let clientID, let elementCallBaseURL, let elementCallBaseURLOverride, let colorScheme):
            // Wait for room states to be up to date before starting the call and notifying others
            syncUpdateCancellable = clientProxy.actionsPublisher
                .filter(\.isSyncUpdate)
                .timeout(.seconds(5), scheduler: DispatchQueue.main)
                .first() // Timeout will make the publisher complete, use first to handle both branches in the same place
                .sink(receiveCompletion: { [weak self] _ in
                    Task { [weak self] in
                        guard let self else { return }
                        
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
                            state.bindings.alertInfo = .init(id: UUID(),
                                                             title: L10n.errorUnknown,
                                                             primaryButton: .init(title: L10n.actionOk) {
                                                                 self.actionsSubject.send(.dismiss)
                                                             })
                            
                            return
                        }
                        
                        await elementCallService.setupCallSession(roomID: roomProxy.id, roomDisplayName: roomProxy.roomTitle)
                        
                        _ = await roomProxy.sendCallNotificationIfNeeded()
                        
                        syncUpdateCancellable = nil
                    }
                }, receiveValue: { _ in })
        }
    }
    
    private func handleBackwardsNavigation() async {
        guard state.url != nil,
              isPictureInPictureEnabled,
              let requestPictureInPictureHandler = state.bindings.requestPictureInPictureHandler else {
            actionsSubject.send(.dismiss)
            return
        }
        
        switch await requestPictureInPictureHandler() {
        case .success(let controller):
            actionsSubject.send(.pictureInPictureStarted(controller))
        case .failure:
            actionsSubject.send(.dismiss)
        }
    }
    
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
