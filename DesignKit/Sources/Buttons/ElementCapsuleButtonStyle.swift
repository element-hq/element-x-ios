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

public extension ButtonStyle where Self == ElementCapsuleButtonStyle {
    /// A button style that uses a capsule shape with a regular appearance.
    static var elementCapsule: ElementCapsuleButtonStyle {
        ElementCapsuleButtonStyle(isProminent: false)
    }
    
    /// A button style that uses a capsule shape with a prominent appearance.
    static var elementCapsuleProminent: ElementCapsuleButtonStyle {
        ElementCapsuleButtonStyle(isProminent: true)
    }
}

public struct ElementCapsuleButtonStyle: ButtonStyle {
    let isProminent: Bool
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(7)
            .frame(maxWidth: .infinity)
            .font(.compound.bodyLGSemibold)
            .foregroundColor(fontColor)
            .multilineTextAlignment(.center)
            .background(background)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Capsule())
    }
    
    @ViewBuilder
    var background: some View {
        if isProminent {
            Capsule()
                .foregroundColor(Color.compound.textActionPrimary)
        } else {
            Capsule()
                .stroke(Color.compound.textActionPrimary)
        }
    }
    
    var fontColor: Color {
        isProminent ? .compound.textOnSolidPrimary : .compound.textPrimary
    }
}

struct ElementCapsuleButtonStyle_Previews: PreviewProvider {
    public static var previews: some View {
        VStack {
            Button("Enabled") { /* preview */ }
                .buttonStyle(.elementCapsuleProminent)
            
            Button("Disabled") { /* preview */ }
                .buttonStyle(.elementCapsuleProminent)
                .disabled(true)
            
            Button("Enabled") { /* preview */ }
                .buttonStyle(.elementCapsule)
            
            Button("Disabled") { /* preview */ }
                .buttonStyle(.elementCapsule)
                .disabled(true)
        }
        .padding()
    }
}
