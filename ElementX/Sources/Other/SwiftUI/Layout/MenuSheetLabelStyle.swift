//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension LabelStyle where Self == MenuSheetLabelStyle {
    /// A label style for labels that are within a menu that is being presented as a sheet.
    static var menuSheet: Self { MenuSheetLabelStyle() }
}

/// The style used for labels that are part of a menu that's presented as
/// a sheet as `TimelineItemMenu` and `RoomAttachmentPicker`.
struct MenuSheetLabelStyle: LabelStyle {
    var spacing: CGFloat = 16
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
    }
}
