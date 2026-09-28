//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Forces the colour scheme of the sheet or popover containing this view without touching the
    /// rest of the app. Does nothing when the view isn't presented modally or the scheme is `nil`.
    ///
    /// Prefer this over `preferredColorScheme` for modals: SwiftUI applies that modifier to the whole
    /// window and can leave it applied when the presentation is torn down abnormally (#6093).
    func presentationColorScheme(_ colorScheme: ColorScheme?) -> some View {
        background(PresentationColorSchemeView(colorScheme: colorScheme))
    }
}

private struct PresentationColorSchemeView: UIViewRepresentable {
    let colorScheme: ColorScheme?
    
    func makeUIView(context: Context) -> InterfaceStyleView {
        InterfaceStyleView(style: UIUserInterfaceStyle(colorScheme))
    }
    
    func updateUIView(_ uiView: InterfaceStyleView, context: Context) {
        uiView.style = UIUserInterfaceStyle(colorScheme)
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
            guard let next else { return nil }
            return sequence(first: next) { $0.next }
                .lazy
                .compactMap { $0 as? UIViewController }
                // Children of a presented controller also report a presentingViewController, so check the parent.
                .first { $0.presentingViewController != nil && $0.parent == nil }
        }
    }
}

private extension UIUserInterfaceStyle {
    init(_ colorScheme: ColorScheme?) {
        self = switch colorScheme {
        case .light: .light
        case .dark: .dark
        case .none: .unspecified
        @unknown default: .unspecified
        }
    }
}
