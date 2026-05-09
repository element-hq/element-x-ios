//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A basic window scene delegate used to configure the `WindowManager`.
///
/// We don't support multiple scenes right now, so the implementation is pretty basic.
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    weak static var windowManager: SecureWindowManagerProtocol!
    
    /// The app's main window scene identifier.
    static let mainSceneID = "Main"
    /// The user info key used by SwiftUI for a `WindowGroup`s `id` parameter.
    static let sceneIDKey = "com.apple.SwiftUI.sceneID"
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Self.windowManager.configure(withScene: windowScene, session: session)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        Self.windowManager.handleSceneDisconnection(windowScene)
    }
}
