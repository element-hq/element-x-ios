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

protocol AlertProtocol {
    var title: String { get }
}

extension View {
    func alert<Item, Actions, Message>(item: Binding<Item?>, @ViewBuilder actions: (Item) -> Actions, @ViewBuilder message: (Item) -> Message) -> some View where Item: AlertProtocol, Actions: View, Message: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return alert(item.wrappedValue?.title ?? "", isPresented: binding, presenting: item.wrappedValue, actions: actions, message: message)
    }
}

/// A type that describes an alert to be shown to the user.
///
/// The alert info can be added to the view state bindings and used as an alert's `item`:
/// ```
/// view
///     .alert(item: $context.alertInfo)
/// ```
struct AlertInfo<T: Hashable>: Identifiable, AlertProtocol {
    struct AlertButton: Identifiable {
        let id = UUID()
        let title: String
        var role: ButtonRole?
        let action: (() -> Void)?
    }

    struct AlertTextField: Identifiable {
        let id = UUID()
        let placeholder: String
        let text: Binding<String>
        let autoCapitalization: TextInputAutocapitalization
        let autoCorrectionDisabled: Bool
    }

    /// An identifier that can be used to distinguish one error from another.
    let id: T
    /// The alert's title.
    let title: String
    /// The alert's message (optional).
    var message: String?
    /// The alert's primary button title and action. Defaults to an Ok button with no action.
    var primaryButton = AlertButton(title: L10n.actionOk, action: nil)
    /// The alert's secondary button title and action.
    var secondaryButton: AlertButton?
    /// The alert's displayed text fields.
    var textFields: [AlertTextField]?
    /// The alert's additional buttons displayed vertically above the primary button.
    var verticalButtons: [AlertButton]?
}

extension AlertInfo {
    /// Initialises the type with a generic title and message for an unknown error along with the default Ok button.
    /// - Parameters:
    ///   - id: An ID that identifies the error.
    ///   - error: The Error that occurred.
    init(id: T) {
        self.id = id
        title = L10n.commonError
        message = L10n.errorUnknown
    }
}

extension View {
    func alert<T: Hashable>(item: Binding<AlertInfo<T>?>) -> some View {
        alert(item: item) { item in
            if let verticalButtons = item.verticalButtons {
                ForEach(verticalButtons) { button in
                    Button(button.title, role: button.role) {
                        button.action?()
                    }
                }
            }

            if let textFields = item.textFields {
                VStack(spacing: 24) {
                    ForEach(textFields) { textField in
                        TextField(textField.placeholder, text: textField.text)
                            .textInputAutocapitalization(textField.autoCapitalization)
                            .autocorrectionDisabled(textField.autoCorrectionDisabled)
                    }
                }
            }

            Button(item.primaryButton.title, role: item.primaryButton.role) {
                item.primaryButton.action?()
            }
            .accessibilityIdentifier(A11yIdentifiers.alertInfo.primaryButton)

            if let secondaryButton = item.secondaryButton {
                Button(secondaryButton.title, role: secondaryButton.role) {
                    secondaryButton.action?()
                }
                .accessibilityIdentifier(A11yIdentifiers.alertInfo.secondaryButton)
            }
        } message: { item in
            if let message = item.message {
                Text(message)
            }
        }
    }
}
