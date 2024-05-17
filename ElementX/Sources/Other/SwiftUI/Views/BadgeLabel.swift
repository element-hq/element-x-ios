//
// Copyright 2024 New Vector Ltd
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

import Compound
import SwiftUI

struct BadgeLabel: View {
    let title: String
    let icon: KeyPath<CompoundIcons, Image>
    let isHighlighted: Bool
    
    var body: some View {
        Label(title,
              icon: icon,
              iconSize: .xSmall,
              relativeTo: .compound.bodySM)
            .labelStyle(BadgeLabelStyle(isHighlighted: isHighlighted))
    }
}

private struct BadgeLabelStyle: LabelStyle {
    let isHighlighted: Bool
    
    var titleColor: Color {
        isHighlighted ? .compound._badgeTextSuccess : .compound._badgeTextSubtle
    }
    
    var iconColor: Color {
        isHighlighted ? .compound.iconSuccessPrimary : .compound.iconSecondary
    }
    
    var backgroundColor: Color {
        isHighlighted ? .compound._bgBadgeSuccess : .compound.bgSubtlePrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .foregroundStyle(iconColor)
            configuration.title
                .foregroundStyle(titleColor)
        }
        .font(.compound.bodySM)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Capsule().fill(backgroundColor))
    }
}

struct BadgeLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 10) {
            BadgeLabel(title: "Encrypted",
                       icon: \.lockSolid,
                       isHighlighted: true)
            BadgeLabel(title: "Not encrypted",
                       icon: \.lockSolid,
                       isHighlighted: false)
        }
    }
}
