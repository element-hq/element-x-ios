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

public extension ButtonStyle where Self == ElementGhostButtonStyle {
    /// The Ghost button style as defined in Compound.
    /// - Parameter size: The control size to use. Defaults to `regular`.
    /// - Parameter color: The color of the label and border. Defaults to the accent color.
    static func elementGhost(_ size: ElementControlSize = .regular,
                             color: Color = .compound.textActionAccent) -> ElementGhostButtonStyle {
        ElementGhostButtonStyle(size: size, color: color)
    }
}

public struct ElementGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    public var size: ElementControlSize
    public var color: Color
    
    private var verticalPadding: CGFloat { size == .xLarge ? 12 : 4 }
    private var maxWidth: CGFloat? { size == .xLarge ? .infinity : nil }
    
    public init(size: ElementControlSize = .regular, color: Color = .compound.textActionAccent) {
        self.size = size
        self.color = color
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: maxWidth)
            .foregroundColor(color)
            .font(.compound.bodySMSemibold)
            .background(border)
            .opacity(opacity(when: configuration.isPressed))
    }
    
    private var border: some View {
        Capsule()
            .strokeBorder()
            .foregroundColor(color)
    }
    
    private func opacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return 0.5 }
        return isPressed ? 0.6 : 1.0
    }
}

public struct ElementGhostButtonStyle_Previews: PreviewProvider {
    public static var previews: some View {
        VStack {
            Button("Enabled") { /* preview */ }
                .buttonStyle(ElementGhostButtonStyle())
            
            Button("Disabled") { /* preview */ }
                .buttonStyle(ElementGhostButtonStyle())
                .disabled(true)
            
            Button("Red BG") { /* preview */ }
                .buttonStyle(ElementGhostButtonStyle(color: .compound.textCriticalPrimary))
            
            Button { /* preview */ } label: {
                Text("Custom")
                    .foregroundColor(.compound.iconInfoPrimary)
            }
            .buttonStyle(ElementGhostButtonStyle(color: .compound.borderInfoSubtle))
        }
        .padding()
    }
}
