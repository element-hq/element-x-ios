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

import Combine
import Foundation
import MatrixRustSDK

private struct ElementCallWidgetMessage: Codable {
    enum Direction: String, Codable {
        case fromWidget
        case toWidget
    }
    
    enum Action: String, Codable {
        case hangup = "im.vector.hangup"
    }
    
    let direction: Direction
    let action: Action
    
    enum CodingKeys: String, CodingKey {
        case direction = "api"
        case action
    }
}

class ElementCallWidgetDriver: WidgetCapabilitiesProvider, ElementCallWidgetDriverProtocol {
    private let room: RoomProtocol
    private var widgetDriver: WidgetDriverAndHandle?
    
    let messagePublisher = PassthroughSubject<String, Never>()
    
    private let actionsSubject: PassthroughSubject<ElementCallWidgetDriverAction, Never> = .init()
    var actions: AnyPublisher<ElementCallWidgetDriverAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(room: RoomProtocol) {
        self.room = room
    }
    
    func start(baseURL: URL, clientID: String) async -> Result<URL, ElementCallWidgetDriverError> {
        guard let room = room as? Room else {
            return .failure(.roomInvalid)
        }
        
        guard let widgetSettings = try? newVirtualElementCallWidget(props: .init(elementCallUrl: baseURL.absoluteString,
                                                                                 widgetId: UUID().uuidString,
                                                                                 parentUrl: nil,
                                                                                 hideHeader: nil,
                                                                                 preload: nil,
                                                                                 fontScale: nil,
                                                                                 appPrompt: false,
                                                                                 skipLobby: true,
                                                                                 confineToRoom: true,
                                                                                 font: nil,
                                                                                 analyticsId: nil)) else {
            return .failure(.failedBuildingWidgetSettings)
        }
        
        guard let urlString = try? await generateWebviewUrl(widgetSettings: widgetSettings, room: room,
                                                            props: .init(clientId: clientID,
                                                                         languageTag: nil,
                                                                         theme: nil)) else {
            return .failure(.failedBuildingCallURL)
        }
        
        guard let url = URL(string: urlString) else {
            return .failure(.failedParsingCallURL)
        }
        
        guard let widgetDriver = try? makeWidgetDriver(settings: widgetSettings) else {
            return .failure(.failedBuildingWidgetDriver)
        }
        
        self.widgetDriver = widgetDriver
        
        Task.detached { [weak self, widgetDriver, messagePublisher] in
            MXLog.debug("Started message receiving loop")
            
            defer {
                MXLog.debug("Stopped message receiving loop")
            }
            
            while true {
                guard let receivedMessage = await widgetDriver.handle.recv() else {
                    return
                }
                
                messagePublisher.send(receivedMessage)
                MXLog.debug("Received message: \(receivedMessage)")
                
                self?.handleMessageIfNeeded(receivedMessage)
            }
        }
        
        Task.detached { [widgetDriver] in
            MXLog.debug("Started widget driver")
            
            defer {
                MXLog.debug("Stopped widget driver")
            }
            
            await widgetDriver.driver.run(room: room, capabilitiesProvider: self)
        }
        
        return .success(url)
    }
    
    func sendMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError> {
        guard let widgetDriver else {
            return .failure(.driverNotSetup)
        }
        
        let result = await widgetDriver.handle.send(msg: message)
        MXLog.debug("Sent message: \(message) with result: \(result)")
        
        handleMessageIfNeeded(message)
        
        return .success(result)
    }
    
    // MARK: - WidgetCapabilitiesProvider
    
    func acquireCapabilities(capabilities: WidgetCapabilities) -> WidgetCapabilities {
        capabilities
    }
    
    // MARK: - Private
    
    func handleMessageIfNeeded(_ message: String) {
        guard let data = message.data(using: .utf8),
              let widgetMessage = try? JSONDecoder().decode(ElementCallWidgetMessage.self, from: data) else {
            return
        }
        
        if widgetMessage.direction == .fromWidget {
            switch widgetMessage.action {
            case .hangup:
                actionsSubject.send(.callEnded)
            }
        }
    }
}
