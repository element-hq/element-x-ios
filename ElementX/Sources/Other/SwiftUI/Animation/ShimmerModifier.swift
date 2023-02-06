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

struct ShimmerModifier: ViewModifier {
    @State private var toggle = false
    
    private let startStart = UnitPoint(x: -5, y: 0)
    private let endStart = UnitPoint(x: 0, y: 0)
    private let startEnd = UnitPoint(x: 1, y: 0)
    private let endEnd = UnitPoint(x: 5, y: 0)
    
    private var stops: [Gradient.Stop] {
        [
            .init(color: normal, location: 0),
            .init(color: highlight, location: 0.21),
            .init(color: highlight, location: 0.25),
            .init(color: normal, location: 0.39),
            .init(color: normal, location: 0.61),
            .init(color: highlight, location: 0.8),
            .init(color: highlight, location: 0.85),
            .init(color: normal, location: 1)
        ]
    }
    
    var highlight: Color { .white.opacity(0.5) }
    var normal: Color { .white }
    
    private var stops2: [Gradient.Stop] {
        [
            .init(color: normal, location: 0),
            .init(color: normal, location: 0.3),
            .init(color: highlight, location: 0.45),
            .init(color: highlight, location: 0.55),
            .init(color: normal, location: 0.7),
            .init(color: normal, location: 1)
        ]
    }
    
    func body(content: Content) -> some View {
        content
            .mask { gradient }
            .onAppear {
                withAnimation(.linear(duration: 1.2).delay(0.5).repeatForever(autoreverses: false)) {
                    toggle.toggle()
                }
            }
    }
    
    var gradient: LinearGradient {
        LinearGradient(stops: stops,
                       startPoint: toggle ? startEnd : startStart,
                       endPoint: toggle ? endEnd : endStart)
    }
}

extension View {
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
