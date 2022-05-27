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

public extension ButtonStyle where Self == SecondaryActionButtonStyle {
    static func secondaryAction(customColor: Color? = nil) -> SecondaryActionButtonStyle {
        SecondaryActionButtonStyle(customColor: customColor)
    }
}

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
            .foregroundColor(customColor ?? .element.accent)
            .font(.element.body)
            .background(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder()
                            .foregroundColor(customColor ?? .element.accent))
            .opacity(opacity(when: configuration.isPressed))
    }
    
    private func opacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return 0.6 }
        return isPressed ? 0.6 : 1.0
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
            
            Button("Red BG") { /* preview */ }
                .buttonStyle(SecondaryActionButtonStyle(customColor: .element.alert))
            
            Button { /* preview */ } label: {
                Text("Custom")
                    .foregroundColor(.element.primaryContent)
            }
            .buttonStyle(SecondaryActionButtonStyle(customColor: .element.quaternaryContent))
        }
        .padding()
    }
}
