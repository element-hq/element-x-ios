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

import Compound
import SwiftUI

struct BadgeView: View {
    let size: Double
    
    var body: some View {
        Circle()
            .fill(.compound.iconCriticalPrimary)
            .frame(width: size, height: size)
    }
}

struct BadgeViewModifier: ViewModifier {
    let size: Double
    
    func body(content: Content) -> some View {
        content.mask {
            Rectangle()
                .fill(.white)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.black)
                        .frame(width: maskSize, height: maskSize)
                        .offset(maskOffset)
                }
                .compositingGroup()
                .luminanceToAlpha()
        }
        .overlay(alignment: .topTrailing) {
            BadgeView(size: size)
        }
    }
    
    private var maskSize: Double {
        size * 1.25
    }
    
    private var maskOffset: CGSize {
        .init(width: (maskSize - size) / 2, height: -(maskSize - size) / 2)
    }
}

extension View {
    @ViewBuilder
    func overlayBadge(_ size: Double, isBadged: Bool = true) -> some View {
        if isBadged {
            modifier(BadgeViewModifier(size: size))
        } else {
            self
        }
    }
}

struct BadgeView_Previews: PreviewProvider {
    static let circleGradient = LinearGradient(colors: [.green, .orange],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
    static let screenGradient = LinearGradient(colors: [.pink, .blue],
                                               startPoint: .top,
                                               endPoint: .bottom)
    static var previews: some View {
        Circle()
            .fill(circleGradient)
            .saturation(2.0)
            .frame(width: 100, height: 100)
            .overlayBadge(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { screenGradient.opacity(0.3).ignoresSafeArea() }
    }
}
