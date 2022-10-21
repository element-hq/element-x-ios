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

struct URLInteractionModifier: ViewModifier {
    @State private var didTapUrl: Bool = false
    private let normalTintColor: Color?
    private let selectedTintColor: Color?
    private let animationDuration: Double
    
    init(normalTintColor: Color?, selectedTintColor: Color?, animationDuration: Double = 0.03) {
        self.normalTintColor = normalTintColor
        self.selectedTintColor = selectedTintColor
        self.animationDuration = animationDuration
    }
    
    func body(content: Content) -> some View {
        content
            .tint(didTapUrl ? selectedTintColor : normalTintColor)
            .environment(\.openURL, OpenURLAction(handler: { url in
                withAnimation(.linear(duration: animationDuration)) {
                    didTapUrl = true
                }
                withAnimation(.linear.delay(animationDuration)) {
                    didTapUrl = false
                }
                return .systemAction
            }))
    }
}

extension View {
    func tintColorURLInteraction(_ tintColor: Color?, selectedOpacity opacity: Double) -> some View {
        modifier(URLInteractionModifier(normalTintColor: tintColor, selectedTintColor: tintColor?.opacity(opacity)))
    }
    
    func tintColorURLInteraction(_ normalTintColor: Color?, selectedTintColor: Color?) -> some View {
        modifier(URLInteractionModifier(normalTintColor: normalTintColor, selectedTintColor: selectedTintColor))
    }
}
