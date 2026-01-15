//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ToolbarButton: View {
    enum Role {
        static let cancel = Role.cancel(title: L10n.actionCancel)
        static let done = Role.confirm(title: L10n.actionDone)
        static let save = Role.confirm(title: L10n.actionSave)

        case cancel(title: String)
        case confirm(title: String)
        
        var title: String {
            switch self {
            case .cancel(let title), .confirm(let title):
                title
            }
        }
        
        @ViewBuilder
        var icon: some View {
            switch self {
            case .cancel:
                CompoundIcon(\.close)
                    .foregroundStyle(.compound.iconPrimary)
            case .confirm:
                CompoundIcon(\.check)
                    .foregroundStyle(.compound.iconOnSolidPrimary)
            }
        }
        
        var tint: Color {
            switch self {
            case .cancel:
                .compound.bgCanvasDefault
            case .confirm:
                .compound.bgAccentRest
            }
        }
    }
    
    let role: Role
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26, *) {
            Button(action: action) {
                role.icon
                    .accessibilityLabel(role.title)
            }
            .tint(role.tint)
            .buttonStyleGlassProminent()
        } else {
            Button(role.title, action: action)
        }
    }
}

@available(iOS 26, *)
private extension View {
    @ViewBuilder
    func buttonStyleGlassProminent() -> some View {
        // `.glassProminent` breaks our preview tests so we need to disable it when running tests.
        // https://github.com/pointfreeco/swift-snapshot-testing/issues/1029#issuecomment-3366942138
        if ProcessInfo.isRunningTests {
            self
        } else {
            buttonStyle(.glassProminent)
        }
    }
}

struct ToolbarButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            Color.clear
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        ToolbarButton(role: .done) { }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        ToolbarButton(role: .cancel) { }
                    }
                }
        }
    }
}
