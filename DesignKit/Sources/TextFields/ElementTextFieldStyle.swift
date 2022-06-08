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

@available(iOS 15.0, *)
public extension TextFieldStyle where Self == ElementTextFieldStyle {
    static func elementInput(isError: Bool = false, labelText: String? = nil, footerText: String? = nil) -> ElementTextFieldStyle {
        ElementTextFieldStyle(isError: isError, labelText: labelText, footerText: footerText)
    }
}

@available(iOS 15.0, *)
public struct ElementTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var isFocused: Bool
    public let isError: Bool
    public let labelText: String?
    public let footerText: String?
    
    private var labelColor: Color {
        guard colorScheme == .light else { return .element.tertiaryContent }
        return isEnabled ? .element.primaryContent : .element.quaternaryContent
    }
    
    private var footerColor: Color {
        isError ? .element.alert : .element.tertiaryContent
    }
    
    public init(isError: Bool = false, labelText: String? = nil, footerText: String? = nil) {
        self.isError = isError
        self.labelText = labelText
        self.footerText = footerText
    }
    
    public func _body(configuration: TextField<_Label>) -> some View {
        VStack(spacing: 8) {
            if let labelText = labelText {
                Text(labelText)
                    .font(.element.subheadline)
                    .foregroundColor(labelColor)
            }
            
            configuration
                .textFieldStyle(BorderedInputFieldStyle(isEditing: isFocused, isError: isError, returnKey: nil))
                .focused($isFocused)
            
            if let footerText = footerText {
                Text(footerText)
                    .font(.element.footnote)
                    .foregroundColor(footerColor)
            }
        }
    }
}
