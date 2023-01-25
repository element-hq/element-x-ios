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

import DesignKit
import SwiftUI

/// A glossy animated background view designed for the onboarding screen
struct OnboardingBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var factor = 0.0
    @State private var isReversed = false
    
    private let step = 0.001
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(asset: Asset.Images.onboardingBackgroundPart1)
                    .position(x: geometry.size.width * 0.125 - factor * geometry.size.width * 0.25, y: (1.0 - factor) * geometry.size.height * 0.55)
                Image(asset: Asset.Images.onboardingBackgroundPart2)
                    .position(x: geometry.size.width * 1.05, y: factor * geometry.size.height * 0.45)
                Image(asset: Asset.Images.onboardingBackgroundPart3)
                    .position(x: factor * geometry.size.width, y: geometry.size.height * 1.05 - factor * geometry.size.height * 0.08)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onReceive(timer) { _ in
                if isReversed {
                    guard factor > 0 else {
                        isReversed = false
                        factor = step
                        return
                    }
                    
                    factor -= step
                } else {
                    guard factor < 1 else {
                        isReversed = true
                        factor = 1 - step
                        return
                    }
                    
                    factor += 0.001
                }
            }
        }
    }
}

struct OnboardingBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingBackgroundView()
    }
}
