//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

import Compound

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
