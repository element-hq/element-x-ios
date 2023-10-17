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

extension View {
    func progressMask(progress: CGFloat) -> some View {
        modifier(ProgressMaskModifier(progress: progress))
    }
}

#warning("ag: add parameters for colors")
private struct ProgressMaskModifier: ViewModifier {
    private let progress: CGFloat

    init(progress: CGFloat) {
        self.progress = progress
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.compound.iconQuaternary)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                Rectangle()
                    .fill(Color.compound.iconSecondary)
                    .frame(width: max(0.0, geometry.size.width * progress), height: geometry.size.height)
            }
            .mask {
                content
            }
        }
    }
}
