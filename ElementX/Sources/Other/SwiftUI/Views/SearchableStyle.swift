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

/// The presentation that the search field should be styled to work with.
enum SearchableStyle {
    /// The search field is styled for presentation inside of a `List` with the `.plain` style.
    case list
    /// The search field is styled for presentation inside of a `Form`.
    case form
    
    /// The colour of the search field's placeholder text and icon.
    var placeholderColor: UIColor { .element.tertiaryContent }
    /// The tint colour of the search text field which is applied to the caret and text selection.
    var textFieldTintColor: UIColor { UIColor(.element.brand) }
    /// The background colour of the search text field.
    var textFieldBackgroundColor: UIColor {
        switch self {
        case .list:
            return .element.system
        case .form:
            return UIColor(.element.formRowBackground)
        }
    }
}

extension View {
    /// Styles the search bar text field added to the view with the `searchable` modifier.
    /// - Parameter style: The presentation of the search bar to match the style to.
    func searchableStyle(_ style: SearchableStyle) -> some View {
        // Ported from Riot iOS as this is the only reliable way to get the exact look we want.
        // However this is fragile and tied to gutwrenching the current UISearchBar internals.
        introspectSearchController { searchController in
            let searchTextField = searchController.searchBar.searchTextField
            
            // Magnifying glass icon.
            let leftImageView = searchTextField.leftView as? UIImageView
            leftImageView?.tintColor = style.placeholderColor
            // Placeholder text.
            let placeholderLabel = searchTextField.value(forKey: "placeholderLabel") as? UILabel
            placeholderLabel?.textColor = style.placeholderColor
            // Text field.
            searchTextField.backgroundColor = style.textFieldBackgroundColor
            searchTextField.tintColor = style.textFieldTintColor

            // Hide the effect views so we can the rounded rect style without any materials.
            let effectBackgroundTop = searchTextField.value(forKey: "_effectBackgroundTop") as? UIView
            effectBackgroundTop?.isHidden = true
            let effectBackgroundBottom = searchTextField.value(forKey: "_effectBackgroundBottom") as? UIView
            effectBackgroundBottom?.isHidden = false
        }
    }
}

struct SearchableStyle_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            List {
                ForEach(0..<10, id: \.self) { index in
                    Text("Item \(index)")
                }
            }
            .listStyle(.plain)
            .searchable(text: .constant(""))
            .searchableStyle(.list)
        }
        .tint(.element.accent)
        
        NavigationStack {
            Form {
                Section("Settings") {
                    Button("Some Row") { }
                        .labelStyle(FormRowLabelStyle())
                }
                .formSectionStyle()
                
                Section("More Settings") {
                    Toggle("Some Setting", isOn: .constant(true))
                        .tint(.element.brand)
                        .labelStyle(FormRowLabelStyle())
                }
                .formSectionStyle()
            }
            .background(Color.element.formBackground.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .searchable(text: .constant(""))
            .searchableStyle(.form)
        }
        .tint(.element.accent)
    }
}
