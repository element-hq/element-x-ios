//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ListInlinePicker<SelectedValue: Hashable>: View {
    let title: String?
    @Binding var selection: SelectedValue
    let items: [(title: String, tag: SelectedValue)]
    let isWaiting: Bool
    
    var body: some View {
        ForEach(items, id: \.tag) { item in
            ListRow(label: .plain(title: item.title),
                    details: isWaiting ? .isWaiting(selection == item.tag) : nil,
                    kind: .selection(isSelected: !isWaiting ? selection == item.tag : false) {
                var transaction = Transaction()
                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    selection = item.tag
                }
            })
        }
    }
}

// MARK: - Previews

struct ListInlinePicker_Previews: PreviewProvider, TestablePreview {
    static var previews: some View { Preview() }
    
    struct Preview: View {
        @State var selection = "Item 1"
        
        let items = ["Item 1", "Item 2", "Item 3"]
        var body: some View {
            Form {
                Section("Compound") {
                    ListInlinePicker(title: "Title",
                                     selection: $selection,
                                     items: items.map { (title: $0, tag: $0) },
                                     isWaiting: false)
                }
                
                Section("Compound with loader") {
                    ListInlinePicker(title: "Title",
                                     selection: $selection,
                                     items: items.map { (title: $0, tag: $0) },
                                     isWaiting: true)
                }
                
                Section("Native") {
                    Picker("", selection: $selection) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
        }
    }
}
