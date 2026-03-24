//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct VoiceMessageTrashButton: View {
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .destructive, action: action) {
                CompoundIcon(\.delete, size: .medium, relativeTo: .compound.headingLG)
                    .modifier(GlassStyle())
                    .compositingGroup()
            }
        } else {
            Button(role: .destructive, action: action) {
                CompoundIcon(\.delete)
                    .scaledToFit()
                    .scaledFrame(size: 30, relativeTo: .compound.headingLG)
            }
            .buttonStyle(.compound(.textLink))
        }
    }
    
    @available(iOS 26, *)
    private struct GlassStyle: ViewModifier {
        @Environment(\.isEnabled) private var isEnabled
        
        func body(content: Content) -> some View {
            if isEnabled {
                label(content: content)
                    .snapshotableGlassEffect(.regular.tint(.compound.bgCriticalPrimary).interactive(),
                                             snapshotBackground: .compound.bgCriticalPrimary,
                                             in: .circle)
            } else {
                label(content: content)
                    .background(.compound.bgSubtlePrimary, in: .circle)
            }
        }
        
        private func label(content: Content) -> some View {
            content
                .foregroundStyle(isEnabled ? .compound.iconOnSolidPrimary : .compound.iconDisabled)
                .scaledPadding(10, relativeTo: .compound.headingLG)
        }
    }
}

// MARK: - Previews

struct VoiceMessageTrashButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 12) {
            VoiceMessageTrashButton { }
                .disabled(true)
            VoiceMessageTrashButton { }
        }
    }
}
