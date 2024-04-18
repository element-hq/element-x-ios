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

import Foundation
import UIKit

// sourcery: AutoMockable
protocol AppMediatorProtocol {
    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
    
    func open(_ url: URL)
    
    func openAppSettings()

    var backgroundTimeRemaining: TimeInterval { get }

    var appState: UIApplication.State { get }
}

extension UIApplication.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}

extension UIUserInterfaceActiveAppearance: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }
}