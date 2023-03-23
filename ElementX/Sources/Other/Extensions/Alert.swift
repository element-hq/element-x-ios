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

protocol AlertItem {
    var title: String { get }
}

extension View {
    func alert<Item, Actions, Message>(item: Binding<Item?>, actions: (Item) -> Actions, message: (Item) -> Message) -> some View where Item: AlertItem, Actions: View, Message: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return alert(item.wrappedValue?.title ?? "", isPresented: binding, presenting: item.wrappedValue, actions: actions, message: message)
    }

    func alert<Item, Actions>(item: Binding<Item?>, actions: (Item) -> Actions) -> some View where Item: AlertItem, Actions: View {
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

// Only for Alerts that display a simple error message with a single button
struct ErrorAlertItem: AlertItem {
    let title: String
    let message: String
}

extension View {
    func errorAlert(item: Binding<ErrorAlertItem?>) -> some View {
        alert(item: item, actions: { _ in
            Button(ElementL10n.ok) { }
        }, message: { item in
            Text(item.message)
        })
    }
}
