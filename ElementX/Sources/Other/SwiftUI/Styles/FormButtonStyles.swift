//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Small squared action button style for settings screens
struct FormActionButtonStyle: ButtonStyle {
    let title: String
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 4) {
            configuration.label
                .buttonStyle(.plain)
                .foregroundColor(.compound.iconSecondary)
                .scaledFrame(size: 24)
            
            Text(title)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodyLG)
                .textCase(.none)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(configuration.isPressed ? Color.compound.bgSubtlePrimary : .compound.bgCanvasDefaultLevel1)
        }
    }
}

struct FormButtonStyles_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            Section { } header: {
                Button { } label: {
                    CompoundIcon(\.shareIos)
                }
                .buttonStyle(FormActionButtonStyle(title: "Share"))
            }
        }
        .compoundList()
    }
}
