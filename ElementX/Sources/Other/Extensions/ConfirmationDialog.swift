//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

    // periphery: ignore - not used yet but might be useful
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
