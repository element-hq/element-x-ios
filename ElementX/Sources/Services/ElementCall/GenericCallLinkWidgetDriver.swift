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
