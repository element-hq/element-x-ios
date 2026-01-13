//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
    func overlayRemoveItemButton(action: @escaping () -> Void) -> some View {
        modifier(RemoveItemButtonViewModifier(action: action))
    }
}

private struct RemoveItemButtonViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .mask {
                Rectangle()
                    .fill(.white)
                    .overlay(alignment: .topTrailing) {
                        closeButtonLabel
                            .hidden()
                            .padding(2)
                            .overlay { Circle().fill(.black) }
                            .offset(x: 2, y: -2)
                    }
                    .compositingGroup()
                    .luminanceToAlpha()
            }
            .overlay(alignment: .topTrailing) {
                Button(action: action) {
                    closeButtonLabel
                }
            }
    }
    
    var closeButtonLabel: some View {
        CompoundIcon(\.close, size: .custom(12), relativeTo: .compound.bodySM)
            .foregroundStyle(.compound.iconOnSolidPrimary)
            .padding(2)
            .background(.compound.iconPrimary, in: Circle())
    }
}
