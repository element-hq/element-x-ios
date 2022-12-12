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

/// A CoordinatorProtocol wrapper and type erasing component that allows
/// dynamically presenting arbitrary screens
struct NavigationModule: Identifiable, Hashable {
    let id = UUID()
    let coordinator: any CoordinatorProtocol
    let dismissalCallback: (() -> Void)?
    
    init(_ coordinator: any CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        self.coordinator = coordinator
        self.dismissalCallback = dismissalCallback
    }
    
    static func == (lhs: NavigationModule, rhs: NavigationModule) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
