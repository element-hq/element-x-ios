//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import SwiftUIIntrospect

extension TextFieldStyle where Self == ElementTextFieldStyle {
    static func element(labelText: String? = nil,
                        footerText: String? = nil,
                        state: ElementTextFieldStyle.State = .default,
                        accessibilityIdentifier: String? = nil) -> ElementTextFieldStyle {
        ElementTextFieldStyle(labelText: labelText.map(Text.init),
                              footerText: footerText.map(Text.init),
                              state: state,
                              accessibilityIdentifier: accessibilityIdentifier)
    }
    
    @_disfavoredOverload
    static func element(labelText: Text? = nil,
                        footerText: Text? = nil,
                        state: ElementTextFieldStyle.State = .default,
                        accessibilityIdentifier: String? = nil) -> ElementTextFieldStyle {
        ElementTextFieldStyle(labelText: labelText,
                              footerText: footerText,
                              state: state,
                              accessibilityIdentifier: accessibilityIdentifier)
    }
}

/// The text field style used in authentication screens.
struct ElementTextFieldStyle: @MainActor TextFieldStyle {
    enum State {
        case success
        case error
        case `default`
    }
    
    @Environment(\.isEnabled) private var isEnabled
    
    @FocusState private var isFocused: Bool
    let labelText: Text?
    let footerText: Text?
    let state: State
    let accessibilityIdentifier: String?
    
    private var isError: Bool {
        state == .error
    }
    
    /// The color of the text field's border.
    private var borderColor: Color {
        isError ? .compound.textCriticalPrimary : .compound._borderTextFieldFocused
    }
    
    /// The width of the text field's border.
    private var borderWidth: CGFloat {
        isFocused || isError ? 1.0 : 0
    }
    
    private var accentColor: Color {
        isError ? .compound.textCriticalPrimary : .compound.iconAccentTertiary
    }
    
    /// The color of the text inside the text field.
    private var textColor: Color {
        isEnabled ? .compound.textPrimary : .compound.textDisabled
    }
    
    /// The color of the text field's background.
    private var backgroundColor: Color {
        isError ? .compound.bgCriticalSubtleHovered :
            .compound.bgSubtleSecondary.opacity(isEnabled ? 1 : 0.5)
    }
    
    /// The color of the placeholder text inside the text field.
    private var placeholderColor: UIColor {
        .compound.textSecondary
    }
    
    /// The color of the label above the text field.
    private var labelColor: Color {
        isEnabled ? .compound.textPrimary : .compound.textDisabled
    }
    
    /// The color of the footer label below the text field.
    private var footerTextColor: Color {
        switch state {
        case .default:
            .compound.textSecondary
        case .error:
            .compound.textCriticalPrimary
        case .success:
            .compound.textSuccessPrimary
        }
    }
    
    private var footerIconColor: Color {
        switch state {
        // Doesn't matter we don't render it
        case .default:
            .clear
        case .error:
            .compound.iconCriticalPrimary
        case .success:
            .compound.iconSuccessPrimary
        }
    }
    
    /// Creates the text field style configured as required.
    /// - Parameters:
    ///   - labelText: The text shown in the label above the field.
    ///   - footerText: The text shown in the footer label below the field.
    ///   - isError: Whether or not the text field is currently in the error state.
    init(labelText: Text? = nil, footerText: Text? = nil, state: State = .default, accessibilityIdentifier: String? = nil) {
        self.labelText = labelText
        self.footerText = footerText
        self.state = state
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    @MainActor
    func _body(configuration: TextField<_Label>) -> some View {
        let rectangle = RoundedRectangle(cornerRadius: 14.0)
        
        return VStack(alignment: .leading, spacing: 8) {
            labelText
                .font(.compound.bodySMSemibold)
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
                .introspect(.textField, on: .supportedVersions) { textField in
                    textField.clearButtonMode = .whileEditing
                    textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "",
                                                                         attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
                    textField.accessibilityIdentifier = accessibilityIdentifier
                }
            
            if let footerText {
                Label {
                    footerText
                        .tint(.compound.textLinkExternal)
                        .font(.compound.bodySM)
                        .foregroundColor(footerTextColor)
                } icon: {
                    switch state {
                    case .success:
                        CompoundIcon(\.checkCircleSolid, size: .xSmall, relativeTo: .compound.bodySM)
                            .foregroundStyle(.compound.iconSuccessPrimary)
                    case .error:
                        CompoundIcon(\.errorSolid, size: .xSmall, relativeTo: .compound.bodySM)
                            .foregroundStyle(.compound.iconCriticalPrimary)
                    case .default:
                        EmptyView()
                    }
                }
                .labelStyle(.custom(spacing: 4, alignment: .top))
                .padding(.horizontal, 16)
            }
        }
    }
}

struct ElementTextFieldStyle_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 20) {
            // Plain text field.
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.element())
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(.element())
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(.element())
                .disabled(true)
            TextField("Placeholder", text: .constant("Web"))
                .textFieldStyle(.element(state: .error))
            
            // Text field with labels
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.element(labelText: "Label", footerText: "Footer"))
            TextField("Placeholder", text: .constant("Input text"))
                .textFieldStyle(.element(labelText: "Title", footerText: "Footer"))
            TextField("Placeholder", text: .constant("Bad text"))
                .textFieldStyle(.element(labelText: "Title", footerText: "Footer", state: .error))
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.element(labelText: "Title", footerText: "Footer"))
                .disabled(true)
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.element(labelText: "Title", footerText: "Footer", state: .success))
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
