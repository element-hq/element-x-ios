//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

struct CallScreenViewModelTests {
    private let service = ElementCallServiceMock(.init())
    private let widgetActions = PassthroughSubject<ElementCallWidgetDriverAction, Never>()
    
    @Test
    func theCallIsSetUpAsAWebViewCall() async {
        var viewModel: CallScreenViewModel?
        await waitForConfirmation { confirmation in
            service.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            viewModel = makeViewModel()
        }
        
        withExtendedLifetime(viewModel) {
            #expect(service.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.kind == .webView)
        }
    }
    
    @Test
    func theWidgetsMuteStaysOutOfCallKit() async {
        let viewModel = makeViewModel()
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(100)) { confirmation in
            service.setAudioEnabledRoomIDClosure = { _, _ in confirmation() }
            widgetActions.send(.mediaStateChanged(audioEnabled: false, videoEnabled: true))
        }
        
        withExtendedLifetime(viewModel) { }
    }
    
    // MARK: - Helpers
    
    private func makeViewModel() -> CallScreenViewModel {
        let clientProxy = ClientProxyMock(.init(deviceID: "call-device-id"))
        let roomProxy = JoinedRoomProxyMock(.init(id: "!room:example.com"))
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.widgetID = "widget"
        widgetDriver.messagePublisher = .init()
        widgetDriver.actions = widgetActions.eraseToAnyPublisher()
        widgetDriver.startBaseURLClientIDColorSchemeVoiceOnlyRageshakeURLAnalyticsConfigurationReturnValue = .success(.userDirectory)
        roomProxy.elementCallWidgetDriverDeviceIDReturnValue = widgetDriver
        
        return CallScreenViewModel(elementCallService: service,
                                   configuration: .init(roomProxy: roomProxy,
                                                        clientProxy: clientProxy,
                                                        clientID: "io.element.elementx",
                                                        elementCallBaseURL: "https://call.element.io",
                                                        elementCallBaseURLOverride: nil,
                                                        voiceOnly: false,
                                                        colorScheme: .light),
                                   allowPictureInPicture: false,
                                   userSettings: .mock(),
                                   analyticsService: AnalyticsServiceMock(.init()))
    }
}
