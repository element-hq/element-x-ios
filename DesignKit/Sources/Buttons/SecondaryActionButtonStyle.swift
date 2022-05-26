//
// Copyright 2021 New Vector Ltd
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
import DesignTokens

public struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    public var customColor: Color?
    
    public init(customColor: Color? = nil) {
        self.customColor = customColor
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(strokeColor(configuration.isPressed))
            .font(.element.body)
            .background(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder()
                            .foregroundColor(strokeColor(configuration.isPressed)))
            .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    private func strokeColor(_ isPressed: Bool) -> Color {
        if let customColor = customColor {
            return customColor
        }
        
        return isPressed ? .element.accent.opacity(0.6) : .element.accent
    }
}

public struct SecondaryActionButtonStyle_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            states
        }
        .preferredColorScheme(.light)
        Group {
            states
        }
        .preferredColorScheme(.dark)
    }
    
    public static var states: some View {
        VStack {
            Button("Enabled") { /* preview */ }
                .buttonStyle(SecondaryActionButtonStyle())
            
            Button("Disabled") { /* preview */ }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(true)
            
            Button { /* preview */ } label: {
                Text("Clear BG")
                    .foregroundColor(.element.alert)
            }
            .buttonStyle(SecondaryActionButtonStyle(customColor: .clear))
            
            Button("Red BG") { /* preview */ }
                .buttonStyle(SecondaryActionButtonStyle(customColor: .element.alert))
        }
        .padding()
    }
}
