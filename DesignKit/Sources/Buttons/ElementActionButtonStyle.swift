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

import Compound
import DesignTokens
import SwiftUI

public extension ButtonStyle where Self == ElementActionButtonStyle {
    /// The CTA button style as defined in Compound.
    /// - Parameter size: The control size to use. Defaults to regular.
    /// - Parameter color: The color of the button's background. Defaults to the accent color.
    static func elementAction(_ size: ElementControlSize = .regular,
                              color: Color = .compound.textActionPrimary) -> ElementActionButtonStyle {
        ElementActionButtonStyle(size: size, color: color)
    }
}

public struct ElementActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    public var size: ElementControlSize
    public var color: Color
    
    private var cornerRadius: CGFloat { size == .xLarge ? 14 : 8 }
    private var verticalPadding: CGFloat { size == .xLarge ? 14 : 4 }
    private var maxWidth: CGFloat? { size == .xLarge ? .infinity : nil }
    
    private var fontColor: Color {
        Color.compound.textOnSolidPrimary
            .opacity(colorScheme == .dark && !isEnabled ? 0.3 : 1.0)
    }
    
    public init(size: ElementControlSize = .regular, color: Color = .compound.textActionPrimary) {
        self.size = size
        self.color = color
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: maxWidth)
            .foregroundColor(fontColor)
            .font(.compound.bodyLGSemibold)
            .background(Capsule()
                .fill(color)
                .opacity(backgroundOpacity(when: configuration.isPressed)))
    }
    
    private func backgroundOpacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return colorScheme == .dark ? 0.2 : 0.1 }
        return isPressed ? 0.3 : 1.0
    }
}

public struct ElementActionButtonStyle_Previews: PreviewProvider {
    public static var previews: some View {
        VStack {
            Button("Enabled") { /* preview */ }
                .buttonStyle(ElementActionButtonStyle())
            
            Button("Disabled") { /* preview */ }
                .buttonStyle(ElementActionButtonStyle())
                .disabled(true)
            
            Button { /* preview */ } label: {
                Text("Clear BG")
                    .foregroundColor(.compound.textCriticalPrimary)
            }
            .buttonStyle(ElementActionButtonStyle(color: .clear))
            
            Button("Red BG") { /* preview */ }
                .buttonStyle(ElementActionButtonStyle(color: .compound.textCriticalPrimary))
        }
        .padding()
    }
}
