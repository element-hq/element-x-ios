//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
