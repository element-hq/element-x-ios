//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct JoinCallButton: View {
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26, *) {
            glassButton
        } else {
            customButton
        }
    }
    
    var glassButton: some View {
        Button(action: action) {
            Text(L10n.a11yJoinCall)
                .font(.compound.bodyLG.weight(.medium))
                .foregroundStyle(.compound.textOnSolidPrimary)
        }
        .tint(.compound.bgAccentRest)
        .backportButtonStyleGlassProminent()
    }
    
    var customButton: some View {
        Button(action: action) {
            Label(L10n.actionJoin, icon: \.videoCallSolid)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(CustomStyle())
        .accessibilityLabel(L10n.a11yJoinCall)
    }
    
    struct CustomStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.horizontal, 16.0)
                .padding(.vertical, 4.0)
                .foregroundColor(.compound.bgCanvasDefault)
                .background(Color.compound.iconAccentTertiary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Previews

struct JoinCallButton_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Color.clear
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        JoinCallButton { }
                    }
                }
        }
    }
}
