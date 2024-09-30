//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

struct ElementCallWidgetMessage: Codable {
    enum Direction: String, Codable {
        case fromWidget
        case toWidget
    }
    
    enum Action: String, Codable {
        case hangup = "im.vector.hangup"
        case mediaState = "io.element.device_mute"
    }
    
    struct Data: Codable {
        var audioEnabled: Bool?
        var videoEnabled: Bool?
        
        enum CodingKeys: String, CodingKey {
            case audioEnabled = "audio_enabled"
            case videoEnabled = "video_enabled"
        }
    }
    
    let direction: Direction
    let action: Action
    var data: Data = .init()
    
    let widgetId: String
    var requestId = "widgetapi-\(UUID())"
    
    enum CodingKeys: String, CodingKey {
        case direction = "api"
        case action
        case data
        case widgetId
        case requestId
    }
}

class ElementCallWidgetDriver: WidgetCapabilitiesProvider, ElementCallWidgetDriverProtocol {
    private let room: RoomProtocol
    private let deviceID: String
    private var widgetDriver: WidgetDriverAndHandle?
    
    let widgetID = UUID().uuidString
    let messagePublisher = PassthroughSubject<String, Never>()
    
    private let actionsSubject: PassthroughSubject<ElementCallWidgetDriverAction, Never> = .init()
    var actions: AnyPublisher<ElementCallWidgetDriverAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(room: RoomProtocol, deviceID: String) {
        self.room = room
        self.deviceID = deviceID
    }
    
    func start(baseURL: URL, clientID: String, colorScheme: ColorScheme) async -> Result<URL, ElementCallWidgetDriverError> {
        guard let room = room as? Room else {
            return .failure(.roomInvalid)
        }
        
        let useEncryption = (try? room.isEncrypted()) ?? false
        
        guard let widgetSettings = try? newVirtualElementCallWidget(props: .init(elementCallUrl: baseURL.absoluteString,
                                                                                 widgetId: widgetID,
                                                                                 parentUrl: nil,
                                                                                 hideHeader: nil,
                                                                                 preload: nil,
                                                                                 fontScale: nil,
                                                                                 appPrompt: false,
                                                                                 skipLobby: true,
                                                                                 confineToRoom: true,
                                                                                 font: nil,
                                                                                 analyticsId: nil,
                                                                                 encryption: useEncryption ? .perParticipantKeys : .unencrypted)) else {
            return .failure(.failedBuildingWidgetSettings)
        }
        
        let languageTag = "\(Locale.current.language.languageCode ?? "en")-\(Locale.current.language.region ?? "US")"
        let theme = colorScheme == .light ? "light" : "dark"
        
        guard let urlString = try? await generateWebviewUrl(widgetSettings: widgetSettings, room: room,
                                                            props: .init(clientId: clientID,
                                                                         languageTag: languageTag,
                                                                         theme: theme)) else {
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
    
    func handleMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError> {
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
        getElementCallRequiredPermissions(ownUserId: room.ownUserId(), ownDeviceId: deviceID)
    }
    
    // MARK: - Private
    
    func handleMessageIfNeeded(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            return
        }
        
        do {
            let widgetMessage = try JSONDecoder().decode(ElementCallWidgetMessage.self, from: data)
            if widgetMessage.direction == .fromWidget {
                switch widgetMessage.action {
                case .hangup:
                    actionsSubject.send(.callEnded)
                case .mediaState:
                    guard let audioEnabled = widgetMessage.data.audioEnabled,
                          let videoEnabled = widgetMessage.data.videoEnabled else {
                        MXLog.error("Media state change messages should contain info data")
                        return
                    }
                    
                    actionsSubject.send(.mediaStateChanged(audioEnabled: audioEnabled, videoEnabled: videoEnabled))
                }
            }
        } catch {
            // Not all actions are supported
            MXLog.verbose("Failed processing widget message with error: \(error)")
        }
    }
}
