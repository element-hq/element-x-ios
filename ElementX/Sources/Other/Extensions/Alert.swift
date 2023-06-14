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

    func alert<Item, Actions>(item: Binding<Item?>, @ViewBuilder actions: (Item) -> Actions) -> some View where Item: AlertProtocol, Actions: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return alert(item.wrappedValue?.title ?? "", isPresented: binding, presenting: item.wrappedValue, actions: actions)
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
    struct AlertButton {
        let title: String
        var role: ButtonRole?
        let action: (() -> Void)?
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

    /// Initialises the type with the title from an `Error`'s localised description along with the default Ok button.
    ///
    /// Currently this initialiser creates an alert for every error, however in the future it may be updated to filter
    /// out some specific errors such as cancellation and networking issues that create too much noise or are
    /// indicated to the user using other mechanisms.
    init(error: Error) where T == String {
        self.init(id: error.localizedDescription,
                  title: error.localizedDescription)
    }
}

extension View {
    func alert<T: Hashable>(item: Binding<AlertInfo<T>?>) -> some View {
        alert(item: item) { item in
            Button(item.primaryButton.title, role: item.primaryButton.role) {
                item.primaryButton.action?()
            }
            if let secondaryButton = item.secondaryButton {
                Button(secondaryButton.title, role: secondaryButton.role) {
                    secondaryButton.action?()
                }
            }
        } message: { item in
            if let message = item.message {
                Text(message)
            }
        }
    }
}
