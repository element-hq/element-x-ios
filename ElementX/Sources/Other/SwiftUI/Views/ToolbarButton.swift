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
        case cancel
        case done
        
        var title: String {
            switch self {
            case .cancel:
                L10n.actionCancel
            case .done:
                L10n.actionDone
            }
        }
        
        var icon: CompoundIcon {
            switch self {
            case .cancel:
                CompoundIcon(\.close)
            case .done:
                CompoundIcon(\.check)
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
        } else {
            Button(role.title, action: action)
        }
    }
}
