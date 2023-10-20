//
// Copyright 2023 New Vector Ltd
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

/// A text field that enables secure entry of a numerical PIN code.
/// The view itself handles validation and the base text field type.
struct PINTextField: View {
    @Binding var pinCode: String
    var isSecure = false
    
    var body: some View {
        textField
            .textFieldStyle(PINTextFieldStyle(pinCode: pinCode, isSecure: isSecure))
            .keyboardType(.numberPad)
            .onChange(of: pinCode) { newValue in
                // add some tests.
                let sanitized = sanitize(newValue)
                if sanitized != newValue { pinCode = sanitized }
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
        if sanitized.count > 4 { sanitized = String(pinCode.prefix(4)) }
        return sanitized.filter(\.isNumber)
    }
}

/// A text field style for displaying individual digits of a PIN code.
private struct PINTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocussed
    
    let pinCode: String
    let isSecure: Bool
    
    public func _body(configuration: TextField<_Label>) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                PINTextFieldDigit(pinCode: pinCode, index: index, isSecure: isSecure)
            }
        }
        .overlay {
            configuration
                .focused($isFocussed)
                .opacity(0.0)
        }
        .onTapGesture { isFocussed = true }
    }
}

/// A single digit shown within the text field style.
private struct PINTextFieldDigit: View {
    let pinCode: String
    let index: Int
    let isSecure: Bool
    
    var isEntered: Bool { pinCode.count > index }
    
    var stringIndex: String.Index { pinCode.index(pinCode.startIndex, offsetBy: index) }
    var character: Character { isSecure ? "●" : pinCode[stringIndex] }
    var digit: String { isEntered ? String(character) : "" }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.compound.bgSubtlePrimary)
                .opacity(isEntered ? 1 : 0)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.compound.iconPrimary, lineWidth: 1)
                .opacity(isEntered ? 0 : 1)
            Text(digit)
                .font(.compound.headingMDBold)
        }
        .frame(width: 48, height: 48)
    }
}

struct PINTextField_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack {
            PreviewWrapper(pinCode: "", isSecure: false)
            PreviewWrapper(pinCode: "12", isSecure: false)
            PreviewWrapper(pinCode: "1234", isSecure: false)
                .padding(.bottom)
            
            PreviewWrapper(pinCode: "", isSecure: true)
            PreviewWrapper(pinCode: "12", isSecure: true)
            PreviewWrapper(pinCode: "1234", isSecure: true)
        }
    }
    
    struct PreviewWrapper: View {
        @State var pinCode = ""
        let isSecure: Bool
        
        var body: some View {
            PINTextField(pinCode: $pinCode, isSecure: isSecure)
        }
    }
}
