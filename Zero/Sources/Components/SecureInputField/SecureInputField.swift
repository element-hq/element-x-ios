//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

public struct SecureInputField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var placeHolder: String
    var accessibilityIdentifier: String
    var submitLabel: SubmitLabel
    var onSubmit: () -> Void
    
    @State private var isSecured = true
    
    public var body: some View {
        HStack {
            ZStack(alignment: .trailing) {
                if isSecured {
                    SecureField(text: $text) {
                        Text(placeHolder).foregroundColor(.compound.textSecondary)
                    }
                    .focused(isFocused)
                    .textFieldStyle(.authentication(accessibilityIdentifier: accessibilityIdentifier))
                    .textContentType(.password)
                    .submitLabel(submitLabel)
                    .onSubmit(onSubmit)
                } else {
                    TextField(text: $text) {
                        Text(placeHolder).foregroundColor(.compound.textSecondary)
                    }
                    .focused(isFocused)
                    .textFieldStyle(.authentication(accessibilityIdentifier: accessibilityIdentifier))
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .submitLabel(submitLabel)
                    .onSubmit(onSubmit)
                }
                
                if !text.isEmpty {
                    Button(action: {
                        isSecured.toggle()
                    }, label: {
                        Image(systemName: isSecured ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 16, weight: .regular))
                            .padding()
                    })
                }
            }
        }
    }
}
