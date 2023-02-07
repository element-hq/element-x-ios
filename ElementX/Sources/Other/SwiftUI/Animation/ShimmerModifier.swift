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

/// A view modifier that applies a shimmering effect to the view.
struct ShimmerModifier: ViewModifier {
    /// Whether the gradient is positioned at the end of the animation.
    @State private var endPosition = false
    
    /// The position of the start of the gradient at the start of the animation.
    private let startStart = UnitPoint(x: -5, y: 0)
    /// The position of the end of the gradient at the start of the animation.
    private let endStart = UnitPoint(x: 0, y: 0)
    /// The position of the start of the gradient at the end of the animation.
    private let startEnd = UnitPoint(x: 1, y: 0)
    /// The position of the end of the gradient at the end of the animation.
    private let endEnd = UnitPoint(x: 5, y: 0)
    
    /// The colour that causes a highlight to be shown.
    private let highlightColor = Color.white.opacity(0.5)
    /// The colour that causes the view to remain unchanged.
    private let regularColor = Color.white
    
    func body(content: Content) -> some View {
        content
            .mask { gradient }
            .onAppear {
                withAnimation(.linear(duration: 1.75).delay(0.5).repeatForever(autoreverses: false)) {
                    endPosition.toggle()
                }
            }
    }
    
    /// The gradient used to create the shimmer.
    var gradient: LinearGradient {
        LinearGradient(stops: [.init(color: regularColor, location: 0),
                               .init(color: regularColor, location: 0.3),
                               .init(color: highlightColor, location: 0.45),
                               .init(color: highlightColor, location: 0.55),
                               .init(color: regularColor, location: 0.7),
                               .init(color: regularColor, location: 1)],
                       startPoint: endPosition ? startEnd : startStart,
                       endPoint: endPosition ? endEnd : endStart)
    }
}

extension View {
    /// Applies a shimmering effect to the view.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerOverlay_Previews: PreviewProvider {
    static let viewModel = HomeScreenViewModel(userSession: MockUserSession(clientProxy: MockClientProxy(userID: ""),
                                                                            mediaProvider: MockMediaProvider()),
                                               attributedStringBuilder: AttributedStringBuilder())
    
    static var previews: some View {
        VStack {
            ForEach(0...8, id: \.self) { _ in
                HomeScreenRoomCell(room: .placeholder(), context: viewModel.context)
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }
}
