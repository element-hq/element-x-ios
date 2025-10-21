//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum ElementCallWidgetDriverError: Error {
    case roomInvalid
    case failedBuildingCallURL
    case failedBuildingWidgetSettings
    case failedBuildingWidgetDriver
    case failedParsingCallURL
    case driverNotSetup
}

enum ElementCallWidgetDriverAction {
    case callEnded
    case mediaStateChanged(audioEnabled: Bool, videoEnabled: Bool)
}

// sourcery: AutoMockable
protocol ElementCallWidgetDriverProtocol {
    var widgetID: String { get }
    
    var messagePublisher: PassthroughSubject<String, Never> { get }
    var actions: AnyPublisher<ElementCallWidgetDriverAction, Never> { get }
    
    func start(baseURL: URL,
               clientID: String,
               colorScheme: ColorScheme,
               rageshakeURL: String?,
               analyticsConfiguration: ElementCallAnalyticsConfiguration?) async -> Result<URL, ElementCallWidgetDriverError>
    
    /// Passes a message from the Widget to the SDK to handle, returning a Bool that represents whether or not the widget driver is still running.
    @discardableResult
    func handleMessage(_ message: String) async -> Result<Bool, ElementCallWidgetDriverError>
}

struct ElementCallAnalyticsConfiguration {
    let posthogAPIHost: String
    let posthogAPIKey: String
    let sentryDSN: String
}
