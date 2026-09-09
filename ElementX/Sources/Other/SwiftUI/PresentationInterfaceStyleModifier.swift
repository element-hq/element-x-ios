//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Forces the interface style of the sheet or popover containing this view without touching the
    /// rest of the app. Does nothing when the view isn't presented modally.
    ///
    /// Prefer this over `preferredColorScheme` for modals: SwiftUI applies that modifier to the whole
    /// window and can leave it applied when the presentation is torn down abnormally (#6093).
    func presentationInterfaceStyle(_ style: UIUserInterfaceStyle) -> some View {
        background(PresentationInterfaceStyleView(style: style))
    }
}

private struct PresentationInterfaceStyleView: UIViewRepresentable {
    let style: UIUserInterfaceStyle
    
    func makeUIView(context: Context) -> InterfaceStyleView {
        InterfaceStyleView(style: style)
    }
    
    func updateUIView(_ uiView: InterfaceStyleView, context: Context) {
        uiView.style = style
    }
    
    class InterfaceStyleView: UIView {
        var style: UIUserInterfaceStyle {
            didSet { applyStyle() }
        }
        
        init(style: UIUserInterfaceStyle) {
            self.style = style
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyStyle()
        }
        
        private func applyStyle() {
            guard window != nil else { return }
            targetViewController?.overrideUserInterfaceStyle = style
        }
        
        /// The view controller that was actually presented, so the override covers its navigation bar too.
        private var targetViewController: UIViewController? {
            var responder = next
            while let current = responder {
                // Children of a presented controller also report a presentingViewController, so check the parent.
                if let viewController = current as? UIViewController,
                   viewController.presentingViewController != nil, viewController.parent == nil {
                    return viewController
                }
                responder = current.next
            }
            return nil
        }
    }
}
