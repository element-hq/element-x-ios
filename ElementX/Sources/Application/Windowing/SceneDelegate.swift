//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// A basic window scene delegate used to configure the `WindowManager`.
///
/// We don't support multiple scenes right now, so the implementation is pretty basic.
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    weak static var windowManager: SecureWindowManagerProtocol!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Self.windowManager.configure(with: windowScene)
    }
}
