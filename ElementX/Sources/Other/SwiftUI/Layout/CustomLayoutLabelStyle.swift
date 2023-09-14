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

extension LabelStyle where Self == CustomLayoutLabelStyle {
    /// A label style that uses an `HStack` with parameters to customise the label's layout.
    static func custom(spacing: CGFloat, alignment: VerticalAlignment = .center, iconLayout: Self.IconLayout = .leading) -> Self {
        CustomLayoutLabelStyle(spacing: spacing, alignment: alignment, iconLayout: iconLayout)
    }
}

struct CustomLayoutLabelStyle: LabelStyle {
    let spacing: CGFloat
    var alignment: VerticalAlignment
    
    enum IconLayout { case leading, trailing }
    var iconLayout: IconLayout
    
    fileprivate init(spacing: CGFloat, alignment: VerticalAlignment, iconLayout: IconLayout) {
        self.spacing = spacing
        self.alignment = alignment
        self.iconLayout = iconLayout
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: alignment, spacing: spacing) {
            if iconLayout == .leading {
                configuration.icon
                configuration.title
            } else {
                configuration.title
                configuration.icon
            }
        }
    }
}
