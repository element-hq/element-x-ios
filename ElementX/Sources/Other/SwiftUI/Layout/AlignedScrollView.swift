//
// Copyright 2022 New Vector Ltd
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

/// A horizontal `ScrollView` that will pad the start of it's content
/// when the alignment is set to `.trailing`.
struct AlignedScrollView<Content: View>: View {
    let alignment: HorizontalAlignment
    var showsIndicators = true
    
    @ViewBuilder let content: () -> Content
    
    @State private var scrollViewFrame: CGRect = .zero
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: showsIndicators) {
            content()
                .frame(minWidth: scrollViewFrame.width,
                       alignment: Alignment(horizontal: alignment, vertical: .center))
        }
        .background(ViewFrameReader(frame: $scrollViewFrame))
    }
}
