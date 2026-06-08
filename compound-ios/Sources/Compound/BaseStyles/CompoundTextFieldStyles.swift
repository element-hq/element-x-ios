//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import SwiftUIIntrospect

public extension Text {
    /// Styles a text with the Compound design tokens to be displayed as a text field placeholder.
    ///
    /// This is only necessary when manually styling a text field using the `prompt` parameter and isn't
    /// necessary when using any of the test field styles provided by Compound.
    func compoundTextFieldPlaceholder() -> Text {
        font(.compound.bodyLG)
            .foregroundColor(.compound.textSecondary)
    }
}

@MainActor
public extension TextFieldStyle where Self == CompoundTextFieldStyle {
    /// A text field style that applies Compound design tokens to a test field with various configuration options.
    /// - Parameters:
    ///   - kind: The kind of text field being shown such as plain or raised.
    ///   - labelText: The text shown in the label above the field.
    ///   - footerText: The text shown in the footer label below the field.
    ///   - state: Specifies if the text field is currently in a success/error state.
    ///   - accessibilityIdentifier: An accessibility identifier that will be applied directly to the base text field.
    static func compound(_ kind: CompoundTextFieldStyle.Kind = .plain,
                         labelText: String? = nil,
                         footerText: String? = nil,
                         state: CompoundTextFieldStyle.State = .default,
                         accessibilityIdentifier: String? = nil) -> CompoundTextFieldStyle {
        CompoundTextFieldStyle(kind: kind,
                               labelText: labelText.map(Text.init),
                               footerText: footerText.map(Text.init),
                               state: state,
                               accessibilityIdentifier: accessibilityIdentifier)
    }
    
    @_disfavoredOverload
    static func compound(_ kind: CompoundTextFieldStyle.Kind = .plain,
                         labelText: Text? = nil,
                         footerText: Text? = nil,
                         state: CompoundTextFieldStyle.State = .default,
                         accessibilityIdentifier: String? = nil) -> CompoundTextFieldStyle {
        CompoundTextFieldStyle(kind: kind,
                               labelText: labelText,
                               footerText: footerText,
                               state: state,
                               accessibilityIdentifier: accessibilityIdentifier)
    }
}

/// The default text field style for standalone text fields.
@MainActor
public struct CompoundTextFieldStyle: @MainActor TextFieldStyle {
    public enum Kind {
        /// The standard text field style for use on the default canvas.
        case plain
        /// A style that raises the text field above the background (typically `bgSubtleSecondaryLevel0`).
        case raised
    }
    
    public enum State {
        /// The text field's input has been validated successfully.
        case success
        /// The text field's input is invalid.
        case error
        /// The text field's input hasn't been validated or is always valid.
        case `default`
    }
    
    @Environment(\.isEnabled) private var isEnabled
    
    @FocusState private var isFocused: Bool
    let kind: Kind
    let labelText: Text?
    let footerText: Text?
    let state: State
    let accessibilityIdentifier: String?
    
    private var isError: Bool {
        state == .error
    }
    
    /// The color of the text field's border.
    private var borderColor: Color {
        guard !isError else { return .compound.textCriticalPrimary }
        return kind == .raised ? .compound.borderInteractiveSecondary : .clear
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
        if kind == .raised {
            isError ? .compound.bgCriticalSubtleHovered :
                .compound.bgCanvasDefaultLevel1
        } else {
            isError ? .compound.bgCriticalSubtleHovered :
                .compound.bgSubtleSecondary.opacity(isEnabled ? 1 : 0.5)
        }
    }
    
    /// The color of the placeholder text inside the text field.
    private var placeholderColor: UIColor {
        .compound.textSecondary
    }
    
    /// The color of the label above the text field.
    private var labelColor: Color {
        guard isEnabled else { return .compound.textDisabled }
        return Compound.supportsGlass ? .compound.textSecondary : .compound.textPrimary
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
    
    @MainActor
    public func _body(configuration: TextField<_Label>) -> some View {
        let shape = Compound.supportsGlass ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: 14.0))
        
        return VStack(alignment: .leading, spacing: 8) {
            labelText
                .font(Compound.supportsGlass ? .compound.bodyMDSemibold : .compound.bodySMSemibold)
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
                        shape.fill(backgroundColor)
                        shape.stroke(borderColor, lineWidth: borderWidth)
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
                .labelStyle(FooterLabelStyle())
                .padding(.horizontal, 16)
            }
        }
    }
    
    private struct FooterLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .top, spacing: 4) {
                configuration.icon
                configuration.title
            }
        }
    }
}

public struct CompoundTextFieldStyle_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        ScrollView {
            states
        }
        .previewLayout(.fixed(width: 390, height: 1250))
    }
    
    @ViewBuilder
    public static var states: some View {
        Section {
            textFields()
        } header: {
            Header(title: "Plain")
        }
        
        Section {
            textFields(.raised)
        } header: {
            Header(title: "Raised")
        }
        
        Section {
            textFields(labelText: "Label", footerText: "Footer")
            TextField("Placeholder", text: .constant("Good text"))
                .textFieldStyle(.compound(footerText: "Footer", state: .success))
                .padding(.horizontal)
        } header: {
            Header(title: "Labels")
        }
    }
    
    static func textFields(_ kind: CompoundTextFieldStyle.Kind = .plain,
                           labelText: String? = nil,
                           footerText: String? = nil) -> some View {
        VStack(spacing: 20) {
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.compound(kind, labelText: labelText, footerText: footerText))
            
            TextField("Placeholder", text: .constant("Text"))
                .textFieldStyle(.compound(kind, labelText: labelText, footerText: footerText))
            
            TextField("Placeholder", text: .constant("Disabled"))
                .textFieldStyle(.compound(kind, labelText: labelText, footerText: footerText))
                .disabled(true)
            
            TextField("Placeholder", text: .constant("Bad text"))
                .textFieldStyle(.compound(kind, labelText: labelText, footerText: footerText, state: .error))
        }
        .padding()
        .background(kind == .raised ? .compound.bgSubtleSecondaryLevel0 : .clear)
    }
    
    struct Header: View {
        let title: String
        
        var body: some View {
            Text(title)
                .foregroundStyle(.compound.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .top])
        }
    }
}
