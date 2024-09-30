//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// A text field that enables secure entry of a numerical PIN code.
/// The view itself handles validation and the base text field type.
struct PINTextField: View {
    @Binding var pinCode: String
    var isSecure = false
    var maxLength = 4
    var size = PINDigitField.Size.medium
    
    var body: some View {
        textField
            .textFieldStyle(PINTextFieldStyle(pinCode: pinCode, isSecure: isSecure, maxLength: maxLength, size: size))
            .keyboardType(.numberPad)
            .accessibilityIdentifier(A11yIdentifiers.appLockSetupPINScreen.textField)
            .onChange(of: pinCode) { newValue in
                let sanitized = sanitize(newValue)
                if sanitized != newValue {
                    MXLog.warning("PIN code input sanitized.")
                    pinCode = sanitized
                }
            }
    }
    
    @ViewBuilder
    var textField: some View {
        if isSecure {
            SecureField("", text: $pinCode)
        } else {
            TextField("", text: $pinCode)
        }
    }
    
    func sanitize(_ pinCode: String) -> String {
        var sanitized = pinCode
        if sanitized.count > maxLength { sanitized = String(pinCode.prefix(maxLength)) }
        return sanitized.filter(\.isNumber)
    }
}

/// A text field style for displaying individual digits of a PIN code.
private struct PINTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocussed
    let pinCode: String
    let isSecure: Bool
    let maxLength: Int
    let size: PINDigitField.Size
    
    func _body(configuration: TextField<_Label>) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<maxLength, id: \.self) { index in
                PINDigitField(digit: digit(index), size: size)
            }
        }
        .overlay {
            configuration
                .focused($isFocussed)
                // Textfield isn't accessible for UI tests otherwise
                .opacity(0.01)
        }
        .onTapGesture { isFocussed = true }
    }
    
    func digit(_ index: Int) -> Character? {
        guard pinCode.count > index else { return nil }
        let stringIndex = pinCode.index(pinCode.startIndex, offsetBy: index)
        return isSecure ? "●" : pinCode[stringIndex]
    }
}

/// A single digit shown within the text field style.
struct PINDigitField: View {
    enum Size {
        case small
        case medium
    }
    
    let digit: Character?
    let size: Size
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 8
        }
    }
    
    private var edge: CGFloat {
        switch size {
        case .small: return 44
        case .medium: return 48
        }
    }
    
    var body: some View {
        ZStack {
            if let digit {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.compound.bgSubtlePrimary)
                Text(String(digit))
                    .font(.compound.headingMDBold)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: 0.5)
                    .stroke(Color.compound.iconPrimary, lineWidth: 1)
            }
        }
        .frame(width: edge, height: edge)
    }
}

struct PINTextField_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
            PreviewWrapper(pinCode: "", isSecure: false)
            PreviewWrapper(pinCode: "12", isSecure: false)
            PreviewWrapper(pinCode: "1234", isSecure: false)
                .padding(.bottom)
            
            PreviewWrapper(pinCode: "", isSecure: true)
            PreviewWrapper(pinCode: "12", isSecure: true)
            PreviewWrapper(pinCode: "1234", isSecure: true)
                .padding(.bottom)
            
            PreviewWrapper(pinCode: "123456", isSecure: false, maxLength: 6, size: .small)
            PreviewWrapper(pinCode: "12", isSecure: false, maxLength: 2, size: .small)
        }
    }
    
    struct PreviewWrapper: View {
        @State var pinCode = ""
        let isSecure: Bool
        var maxLength = 4
        var size: PINDigitField.Size = .medium
        
        var body: some View {
            PINTextField(pinCode: $pinCode, isSecure: isSecure, maxLength: maxLength, size: size)
        }
    }
}
