//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

extension UIResponder {
    private weak static var capturedResponder: UIResponder?
    
    /// The current first responder, found by bouncing an action off the responder chain.
    @MainActor
    static var current: UIResponder? {
        capturedResponder = nil
        UIApplication.shared.sendAction(#selector(captureResponder), to: nil, from: nil, for: nil)
        return capturedResponder
    }
    
    @objc private func captureResponder() {
        UIResponder.capturedResponder = self
    }
}
