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
import Introspect
import SwiftUI

public extension TextFieldStyle where Self == ElementTextFieldStyle {
    static func elementInput(labelText: String? = nil,
                             footerText: String? = nil,
                             isError: Bool = false,
                             accessibilityIdentifier: String? = nil) -> ElementTextFieldStyle {
        ElementTextFieldStyle(labelText: labelText.map(Text.init),
                              footerText: footerText.map(Text.init),
                              isError: isError,
                              accessibilityIdentifier: accessibilityIdentifier)
    }
    
    @_disfavoredOverload
    static func elementInput(labelText: Text? = nil,
                             footerText: Text? = nil,
                             isError: Bool = false,
                             accessibilityIdentifier: String? = nil) -> ElementTextFieldStyle {
        ElementTextFieldStyle(labelText: labelText,
                              footerText: footerText,
                              isError: isError,
                              accessibilityIdentifier: accessibilityIdentifier)
    }
}

/// A bordered style of text input with a label and a footer
///
/// As defined in:
/// https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=2039%3A26415
public struct ElementTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var isFocused: Bool
    public let labelText: Text?
    public let footerText: Text?
    public let isError: Bool
    public let accessibilityIdentifier: String?
    
    /// The color of the text field's border.
    private var borderColor: Color {
        guard !isError else { return .element.alert }
        return isFocused ? .element.tertiaryContent : .element.quinaryContent
    }
    
    /// The width of the text field's border.
    private var borderWidth: CGFloat {
        isFocused || isError ? 1.0 : 0
    }
    
    private var accentColor: Color {
        isError ? .element.alert : .element.brand
    }
    
    /// The color of the text inside the text field.
    private var textColor: Color {
        if colorScheme == .dark {
            return isEnabled ? .element.primaryContent : .element.tertiaryContent
        } else {
            return isEnabled ? .element.primaryContent : .element.quaternaryContent
        }
    }
    
    /// The color of the text field's background.
    private var backgroundColor: Color {
        if !isEnabled, colorScheme == .dark {
            return .element.quinaryContent
        }
        return .element.system
    }
    
    /// The color of the placeholder text inside the text field.
    private var placeholderColor: Color {
        .element.tertiaryContent
    }
    
    /// The color of the label above the text field.
    private var labelColor: Color {
        isEnabled ? .element.primaryContent : .element.quaternaryContent
    }
    
    /// The color of the footer label below the text field.
    private var footerColor: Color {
        isError ? .element.alert : .element.tertiaryContent
    }
    
    /// Creates the text field style configured as required.
    /// - Parameters:
    ///   - labelText: The text shown in the label above the field.
    ///   - footerText: The text shown in the footer label below the field.
    ///   - isError: Whether or not the text field is currently in the error state.
    public init(labelText: Text? = nil, footerText: Text? = nil, isError: Bool = false, accessibilityIdentifier: String? = nil) {
        self.labelText = labelText
        self.footerText = footerText
        self.isError = isError
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    public func _body(configuration: TextField<_Label>) -> some View {
        let rectangle = RoundedRectangle(cornerRadius: 14.0)
        
        return VStack(alignment: .leading, spacing: 8) {
            labelText
                .font(.compound.bodySM)
                .foregroundColor(labelColor)
                .padding(.horizontal, 16)
            
            configuration
                .focused($isFocused)
                .font(.compound.bodyLG)
                .foregroundColor(textColor)
                .accentColor(accentColor)
                .padding(.leading, 16.0)
                .padding([.vertical, .trailing], 11.0)
                .background {
                    ZStack {
                        backgroundColor
                            .clipShape(rectangle)
                        rectangle
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                    .onTapGesture { isFocused = true } // Set focus with taps outside of the text field
                }
                .introspectTextField { textField in
                    textField.clearButtonMode = .whileEditing
                    textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "",
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor(placeholderColor)])
                    textField.accessibilityIdentifier = accessibilityIdentifier
                }
 
            footerText
                .tint(.element.links)
                .font(.compound.bodyXS)
                .foregroundColor(footerColor)
                .padding(.horizontal, 16)
        }
    }
}

struct ElementTextFieldStyle_Previews: PreviewProvider {
    public static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Plain text field.
                TextField("Placeholder", text: .constant(""))
                    .textFieldStyle(.elementInput())
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(.elementInput())
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(.elementInput())
                    .disabled(true)
                TextField("Placeholder", text: .constant("Web"))
                    .textFieldStyle(.elementInput(isError: true))
                
                // Text field with labels
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
}
