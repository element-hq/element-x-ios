//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public extension ToggleStyle where Self == CompoundToggleStyle {
    /// A toggle style that applies Compound design tokens to display a Switch row within a `Form`.
    static var compound: CompoundToggleStyle {
        CompoundToggleStyle()
    }
}

/// Default toggle styling for form rows.
///
/// The toggle is given the form row label style and is tinted correctly.
public struct CompoundToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
                .foregroundColor(.compound.textPrimary)
        }
        .tint(.compound.iconAccentTertiary)
    }
}

public struct CompoundToggleStyle_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        VStack(spacing: 16) {
            states
        }
        .padding(32)
    }
    
    @ViewBuilder
    public static var states: some View {
        VStack(spacing: 16) {
            Toggle("Title", isOn: .constant(false))
                .toggleStyle(.compound)
                .labelsHidden()
            
            Toggle("Title", isOn: .constant(true))
                .toggleStyle(.compound)
                .labelsHidden()
        }
        .padding(.bottom, 32)
        
        VStack(spacing: 16) {
            Toggle("Title", isOn: .constant(true))
                .toggleStyle(.compound)
            Toggle("Title", isOn: .constant(false))
                .toggleStyle(.compound)
            
            Toggle(isOn: .constant(true)) {
                Label("Title", systemImage: "square.dashed")
            }
            .toggleStyle(.compound)
            Toggle(isOn: .constant(false)) {
                Label("Title", systemImage: "square.dashed")
            }
            .toggleStyle(.compound)
        }
    }
}
