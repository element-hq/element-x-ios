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

import DesignTokens
import SwiftUI

@available(iOS 15.0, *)
public extension TextFieldStyle where Self == ElementTextFieldStyle {
    static func elementInput(labelText: String? = nil,
                             footerText: String? = nil,
                             isError: Bool = false) -> ElementTextFieldStyle {
        ElementTextFieldStyle(labelText: labelText, footerText: footerText, isError: isError)
    }
}

@available(iOS 15.0, *)
public struct ElementTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var isFocused: Bool
    public let labelText: String?
    public let footerText: String?
    public let isError: Bool
    
    private var labelColor: Color {
        guard colorScheme == .light else { return .element.tertiaryContent }
        return isEnabled ? .element.primaryContent : .element.quaternaryContent
    }
    
    private var footerColor: Color {
        isError ? .element.alert : .element.tertiaryContent
    }
    
    public init(labelText: String? = nil, footerText: String? = nil, isError: Bool = false) {
        self.labelText = labelText
        self.footerText = footerText
        self.isError = isError
    }
    
    public func _body(configuration: TextField<_Label>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let labelText {
                Text(labelText)
                    .font(.element.subheadline)
                    .foregroundColor(labelColor)
            }
            
            configuration
                .textFieldStyle(BorderedInputFieldStyle(isEditing: isFocused, isError: isError, returnKey: nil))
                .focused($isFocused)
                .onTapGesture { isFocused = true } // Set focus with taps in the space between the border and text field.
            
            if let footerText {
                Text(footerText)
                    .font(.element.footnote)
                    .foregroundColor(footerColor)
            }
        }
    }
}

@available(iOS 15.0, *)
struct ElementTextFieldStyle_Previews: PreviewProvider {
    public static var previews: some View {
        VStack(spacing: 12) {
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.elementInput(labelText: "Label", footerText: "Footer"))
            TextField("Placeholder", text: .constant("Input text"))
                .textFieldStyle(.elementInput(labelText: "Title", footerText: "Footer"))
            TextField("Placeholder", text: .constant("Bad text"))
                .textFieldStyle(.elementInput(labelText: "Title", footerText: "Footer", isError: true))
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.elementInput(labelText: "Title", footerText: "Footer"))
                .disabled(true)
        }
        .padding()
    }
}
