//
// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The button component for sending messages and media.
///
/// The button's size is 44pt x 44pt on iOS 26 and later, and 36pt x 36pt on iOS 18 and earlier.
public struct SendButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    public enum Mode { case send, edit }
    /// Whether the button is for sending a new message or editing an existing one.
    private let mode: Mode
    /// The action to perform when the user triggers the button.
    private let action: () -> Void
    
    private var icon: KeyPath<CompoundIcons, Image> {
        switch mode {
        case .send: \.sendSolid
        case .edit: \.check
        }
    }
    
    private var iconColor: Color {
        guard isEnabled else { return .compound.iconQuaternary }
        return colorScheme == .light ? .compound.iconOnSolidPrimary : .compound.iconPrimary
    }
    
    private var backgroundColor: Color {
        isEnabled ? .compound.bgAccentRest : .clear
    }
    
    /// Creates a send button that performs the provided action.
    public init(mode: Mode = .send, action: @escaping () -> Void) {
        self.mode = mode
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            label
                .compositingGroup()
        }
    }
    
    @ViewBuilder
    public var label: some View {
        if #available(iOS 26, *), isEnabled, !ProcessInfo.processInfo.isRunningTests {
            baseIcon
                .glassEffect(.regular.tint(backgroundColor).interactive(), in: .circle)
        } else {
            baseIcon
                .background(backgroundColor, in: .circle)
        }
    }
    
    var baseIcon: some View {
        CompoundIcon(icon, size: .medium, relativeTo: .compound.headingLG)
            .foregroundStyle(iconColor)
            .scaledPadding(Compound.supportsGlass ? 10 : 6, relativeTo: .compound.headingLG)
    }
}

// MARK: - Previews

public struct SendButton_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        VStack(spacing: 0) {
            states
                .padding(20)
                .background(.compound.bgCanvasDefault)
            states
                .padding(20)
                .background(.compound.bgCanvasDefault)
                .environment(\.colorScheme, .dark)
        }
        .cornerRadius(20)
    }
    
    public static var states: some View {
        HStack(spacing: 30) {
            SendButton { }
                .disabled(true)
            SendButton { }
            
            SendButton(mode: .edit) { }
        }
    }
}
