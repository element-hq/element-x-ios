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

enum DeveloperOptionsScreenViewModelAction {
    case clearCache
}

struct DeveloperOptionsScreenViewState: BindableState {
    var bindings: DeveloperOptionsScreenViewStateBindings
}

// periphery: ignore - subscripts are seen as false positive
@dynamicMemberLookup
struct DeveloperOptionsScreenViewStateBindings {
    private let developerOptions: DeveloperOptionsProtocol

    init(developerOptions: DeveloperOptionsProtocol) {
        self.developerOptions = developerOptions
    }

    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<DeveloperOptionsProtocol, Setting>) -> Setting {
        get { developerOptions[keyPath: keyPath] }
        set { developerOptions[keyPath: keyPath] = newValue }
    }
}

enum DeveloperOptionsScreenViewAction {
    case clearCache
}

protocol DeveloperOptionsProtocol: AnyObject {
    var logLevel: TracingConfiguration.LogLevel { get set }
    var shouldCollapseRoomStateEvents: Bool { get set }
    var hideUnreadMessagesBadge: Bool { get set }
    var elementCallBaseURL: URL { get set }
    var publicSearchEnabled: Bool { get set }
    var qrCodeLoginEnabled: Bool { get set }
    var roomListInvitesEnabled: Bool { get set }
}

extension AppSettings: DeveloperOptionsProtocol { }
