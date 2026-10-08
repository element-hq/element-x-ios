//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A capsule showing an unread notification count, capped at 99+.
struct NotificationCountBadge: View {
    enum Size {
        case small
        case medium
    }
    
    let count: Int
    var size: Size = .medium
    
    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(size == .small ? .compound.bodyXSSemibold : .compound.bodySMSemibold)
            .foregroundStyle(.compound.textOnSolidPrimary)
            .lineLimit(1)
            .padding(.horizontal, size == .small ? 4 : 6)
            .frame(minWidth: size == .small ? 16 : 20, minHeight: size == .small ? 16 : 20)
            .background(.compound.iconAccentPrimary, in: .capsule)
    }
}

// MARK: - Previews

struct NotificationCountBadge_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
            ForEach([Size.small, .medium], id: \.self) { size in
                HStack(spacing: 8) {
                    NotificationCountBadge(count: 1, size: size)
                    NotificationCountBadge(count: 42, size: size)
                    NotificationCountBadge(count: 100, size: size)
                }
            }
        }
    }
    
    private typealias Size = NotificationCountBadge.Size
}
