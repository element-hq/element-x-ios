//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import SwiftUIIntrospect

public extension View {
    /// Styles a search bar text field using the Compound design tokens.
    /// This modifier is to be used in combination with `.searchable`.
    @MainActor
    @ViewBuilder
    func compoundSearchField() -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            introspect(.navigationStack, on: .supportedVersions, scope: .ancestor) { navigationController in
                // Uses the navigation stack as .searchField is unreliable when pushing the second search bar, during the create rooms flow.
                guard let searchController = navigationController.navigationBar.topItem?.searchController else { return }
                
                // Ported from Riot iOS as this is the only reliable way to get the exact look we want.
                // However this is fragile and tied to gutwrenching the current UISearchBar internals.
                let textColor = UIColor.compound.textPrimary
                let placeholderColor = UIColor.compound.textSecondary
                let textFieldTintColor = UIColor.compound.iconAccentTertiary
                let textFieldBackgroundColor = UIColor.compound._bgSubtleSecondaryAlpha
                
                let searchTextField = searchController.searchBar.searchTextField
                
                // Magnifying glass icon.
                let leftImageView = searchTextField.leftView as? UIImageView
                leftImageView?.tintColor = placeholderColor
                // Placeholder text.
                let placeholderLabel = searchTextField.value(forKey: "placeholderLabel") as? UILabel
                placeholderLabel?.textColor = placeholderColor
                // Clear button.
                let clearButton = searchTextField.value(forKey: "clearButton") as? UIButton
                let buttonImage = clearButton?.image(for: .normal)?.withRenderingMode(.alwaysTemplate)
                clearButton?.setImage(buttonImage, for: .normal)
                clearButton?.tintColor = placeholderColor
                
                // Text field.
                searchTextField.textColor = textColor
                searchTextField.backgroundColor = textFieldBackgroundColor
                searchTextField.tintColor = textFieldTintColor
                
                // Hide the effect views so we can use the rounded rect style without any materials.
                let effectBackgroundTop = searchTextField.value(forKey: "_effectBackgroundTop") as? UIView
                effectBackgroundTop?.isHidden = true
                let effectBackgroundBottom = searchTextField.value(forKey: "_effectBackgroundBottom") as? UIView
                effectBackgroundBottom?.isHidden = false
            }
        }
    }
}

// MARK: - Previews

struct SearchStyle_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            List {
                ForEach(0..<10, id: \.self) { index in
                    Text("Item \(index)")
                }
            }
            .listStyle(.plain)
            .searchable(text: .constant(""))
            .compoundSearchField()
        }
        .tint(.compound.textActionPrimary)
        .previewDisplayName("List")
        
        NavigationStack {
            Form {
                Section {
                    ListRow(label: .plain(title: "Some row"),
                            kind: .button { })
                } header: {
                    Text("Settings")
                        .compoundListSectionHeader()
                }

                Section {
                    ListRow(label: .plain(title: "Some setting"),
                            kind: .toggle(.constant(true)))
                } header: {
                    Text("More Settings")
                        .compoundListSectionHeader()
                }
            }
            .compoundList()
            .searchable(text: .constant(""))
            .compoundSearchField()
        }
        .tint(.compound.textActionPrimary)
        .previewDisplayName("Form")
    }
}
