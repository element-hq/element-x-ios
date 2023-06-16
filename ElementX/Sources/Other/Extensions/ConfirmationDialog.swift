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

protocol ConfirmationDialogProtocol {
    var title: String { get }
}

extension View {
    func confirmationDialog<Item, Actions>(item: Binding<Item?>,
                                           titleVisibility: Visibility = .automatic,
                                           @ViewBuilder actions: (Item) -> Actions) -> some View where Item: ConfirmationDialogProtocol, Actions: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return confirmationDialog(item.wrappedValue?.title ?? "", isPresented: binding, titleVisibility: titleVisibility, presenting: item.wrappedValue, actions: actions)
    }

    func confirmationDialog<Item, Actions, Message>(item: Binding<Item?>,
                                                    titleVisibility: Visibility = .automatic,
                                                    @ViewBuilder actions: (Item) -> Actions,
                                                    @ViewBuilder message: (Item) -> Message) -> some View where Item: ConfirmationDialogProtocol, Actions: View, Message: View {
        let binding = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })
        return confirmationDialog(item.wrappedValue?.title ?? "", isPresented: binding, titleVisibility: titleVisibility, presenting: item.wrappedValue, actions: actions, message: message)
    }
}
