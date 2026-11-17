//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ToolbarButton: View {
    @Environment(\.isEnabled) private var isEnabled
    
    enum Role {
        static let cancel = Role.cancel(title: L10n.actionCancel)
        static let done = Role.confirm(title: L10n.actionDone)
        static let save = Role.confirm(title: L10n.actionSave)
        static let close = Role.cancel(title: L10n.actionClose)
        
        case cancel(title: String)
        case confirm(title: String)
        case destructive(title: String)
        
        var title: String {
            switch self {
            case .cancel(let title), .confirm(let title), .destructive(let title):
                title
            }
        }
        
        @ViewBuilder
        func icon(isEnabled: Bool) -> some View {
            switch self {
            case .cancel:
                CompoundIcon(\.close)
                    .foregroundStyle(.compound.iconPrimary)
            case .confirm:
                CompoundIcon(\.check)
                    // Doesn't agree with the Figma but Apple no longer tints disabled buttons (iOS 27.2).
                    .foregroundStyle(isEnabled ? .compound.iconOnSolidPrimary : .compound.iconDisabled)
            case .destructive:
                CompoundIcon(\.delete)
                    // Doesn't agree with the Figma but Apple no longer tints disabled buttons (iOS 27.2).
                    .foregroundStyle(isEnabled ? .compound.iconOnSolidPrimary : .compound.iconDisabled)
            }
        }
        
        var tint: Color? {
            switch self {
            case .cancel:
                nil
            case .confirm:
                .compound.bgAccentRest
            case .destructive:
                .compound.bgCriticalPrimary
            }
        }
    }
    
    let role: Role
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26, *) {
            if let tint = role.tint {
                glassButton
                    .tint(tint)
                    .backportButtonStyleGlassProminent()
            } else {
                glassButton
            }
        } else {
            flatButton
        }
    }
    
    private var glassButton: some View {
        Button(action: action) {
            role.icon(isEnabled: isEnabled)
                .accessibilityLabel(role.title)
        }
    }
    
    private var flatButton: some View {
        Button(role.title, action: action)
    }
}

struct ToolbarButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 0) {
            ElementNavigationStack {
                Color.clear
                    .toolbar { toolbarButtons }
            }
            
            ElementNavigationStack {
                Color.clear
                    .toolbar { toolbarButtons }
                    .disabled(true)
            }
            
            ElementNavigationStack {
                Color.clear
                    .toolbar { toolbarButtons }
            }
            .colorScheme(.dark)
            
            ElementNavigationStack {
                Color.clear
                    .toolbar { toolbarButtons }
                    .disabled(true)
            }
            .colorScheme(.dark)
        }
    }
    
    @ToolbarContentBuilder
    static var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .done) { }
        }
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .cancel) { }
        }
        ToolbarItem(placement: .primaryAction) {
            ToolbarButton(role: .destructive(title: L10n.actionRemove)) { }
        }
    }
}
