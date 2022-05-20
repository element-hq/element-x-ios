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

public struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    public var customColor: Color?
    
    private var fontColor: Color {
        // Always white unless disabled with a dark theme.
        .white.opacity(colorScheme == .dark && !isEnabled ? 0.3 : 1.0)
    }
    
    private var backgroundColor: Color {
        customColor ?? .element.accent
    }
    
    public init(customColor: Color? = nil) {
        self.customColor = customColor
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .foregroundColor(fontColor)
            .font(.element.body)
            .background(backgroundColor.opacity(backgroundOpacity(when: configuration.isPressed)))
            .cornerRadius(8.0)
    }
    
    private func backgroundOpacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return 0.3 }
        return isPressed ? 0.6 : 1.0
    }
}

public struct PrimaryActionButtonStyle_Previews: PreviewProvider {
    public static var states: some View {
        VStack {
            Button("Enabled") { }
                .buttonStyle(PrimaryActionButtonStyle())
            
            Button("Disabled") { }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(true)
            
            Button { } label: {
                Text("Clear BG")
                    .foregroundColor(.red)
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: .clear))
            
            Button("Red BG") { }
                .buttonStyle(PrimaryActionButtonStyle(customColor: .red))
        }
        .padding()
    }
    
    public static var previews: some View {
        states
            .preferredColorScheme(.light)
        states
            .preferredColorScheme(.dark)
    }
}
