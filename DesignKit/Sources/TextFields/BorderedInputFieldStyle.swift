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
import Introspect

/// A bordered style of text input
///
/// As defined in:
/// https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=2039%3A26415
public struct BorderedInputFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    public var isEditing: Bool
    public var isError: Bool
    
    private var borderColor: Color {
        if !isEnabled {
            return .element.quinaryContent
        } else if isError {
            return .element.alert
        } else if isEditing {
            return .element.accent
        } else {
            return .element.quaternaryContent
        }
    }
    
    private var accentColor: Color {
        if isError {
            return .element.alert
        }
        return .element.accent
    }
    
    private var textColor: Color {
        if colorScheme == .dark {
            return isEnabled ? .element.primaryContent : .element.tertiaryContent
        } else {
            return isEnabled ? .element.primaryContent : .element.quaternaryContent
        }
    }
    
    private var backgroundColor: Color {
        if !isEnabled && colorScheme == .dark {
            return .element.quinaryContent
        }
        return .element.background
    }
    
    private var placeholderColor: Color {
        return .element.tertiaryContent
    }
        
    private var borderWidth: CGFloat {
        return isEditing || isError ? 2.0 : 1.5
    }
    
    public init(isEditing: Bool = false, isError: Bool = false) {
        self.isEditing = isEditing
        self.isError = isError
    }
    
    public func _body(configuration: TextField<_Label>) -> some View {
        let rect = RoundedRectangle(cornerRadius: 8.0)
        return configuration
            .font(.element.callout)
            .foregroundColor(textColor)
            .accentColor(accentColor)
            .frame(height: 48.0)
            .padding(.horizontal, 8.0)
            .background(backgroundColor)
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: borderWidth))
            .introspectTextField { textField in
                textField.returnKeyType = .done
                textField.clearButtonMode = .whileEditing
                textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "",
                                                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor(placeholderColor)])
            }
    }
}

public struct BorderedInputFieldStyle_Previews: PreviewProvider {
    public static var states: some View {
        VStack {
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(BorderedInputFieldStyle())
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(BorderedInputFieldStyle(isEditing: true))
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(BorderedInputFieldStyle())
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(BorderedInputFieldStyle(isEditing: true))
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(BorderedInputFieldStyle())
                .disabled(true)
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(BorderedInputFieldStyle(isEditing: true, isError: true))
        }
        .padding()
    }
    
    public static var previews: some View {
        Group {
            states
                .preferredColorScheme(.light)
            states
                .preferredColorScheme(.dark)
        }
    }
}
