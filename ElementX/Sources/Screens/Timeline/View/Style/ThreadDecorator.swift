//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ThreadDecorator: View {
    var body: some View {
        Label {
            Text(L10n.commonThread)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodyXS)
        } icon: {
            CompoundIcon(\.threads, size: .xSmall, relativeTo: .compound.bodyXS)
                .foregroundColor(.compound.iconSecondary)
        }
        .labelStyle(.custom(spacing: 4))
    }
}

struct ThreadDecorator_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ThreadDecorator()
    }
}
