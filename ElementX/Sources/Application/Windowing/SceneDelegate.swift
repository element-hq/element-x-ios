//
// Copyright 2023 New Vector Ltd
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

import SwiftUI

/// A basic window scene delegate used to configure the `WindowManager`.
///
/// We don't support multiple scenes right now, so the implementation is pretty basic.
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    weak static var windowManager: WindowManager!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene, !ProcessInfo.isRunningTests else { return }
        Self.windowManager.configure(with: windowScene)
    }
}
