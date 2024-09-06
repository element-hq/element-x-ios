//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

class GenericCallLinkWidgetDriver: ElementCallWidgetDriverProtocol {
    private let url: URL
    
    let widgetID = UUID().uuidString
    let messagePublisher = PassthroughSubject<String, Never>()
    
    private let actionsSubject: PassthroughSubject<ElementCallWidgetDriverAction, Never> = .init()
    var actions: AnyPublisher<ElementCallWidgetDriverAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(url: URL) {
        self.url = url
    }
    
    func start(baseURL: URL, clientID: String, colorScheme: ColorScheme) async -> Result<URL, ElementCallWidgetDriverError> {
        MXLog.error("Nothing to start, use the configuration's URL directly instead.")
        return .success(url)
    }
    
    func handleMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError> {
        // The web view doesn't send us messages through the Widget API, so nothing to implement (yet?).
        .failure(.driverNotSetup)
    }
}
