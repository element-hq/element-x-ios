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
import SwiftUIIntrospect

extension View {
    /// Disable the interactive dismiss while the search is on.
    /// - Note: the modifier needs to be called before the `searchable` modifier to work properly
    func disableInteractiveDismissOnSearch() -> some View {
        modifier(InteractiveDismissSearchModifier())
    }
    
    /// Dismiss search when the view is disappearing. It helps to restore correct state on pop into a NavigationStack
    /// - Note: the modifier needs to be called before the `searchable` modifier to work properly
    func dismissSearchOnDisappear() -> some View {
        modifier(DismissSearchOnDisappear())
    }
    
    /// A custom replacement for searchable that allows more precise configuration of the underlying search controller.
    ///
    /// Whilst we originally used introspect to configure parameters such as preventing the navigation bar from hiding
    /// during a search, this proved unreliable from iOS 17.1 onwards. This implementation avoids all of those shenanigans.
    ///
    /// - Parameters:
    ///   - query: The current or starting search text.
    ///   - placeholder: The string to display when there’s no other text in the text field.
    ///   - hidesNavigationBarDuringPresentation: A Boolean indicating whether to hide the navigation bar when searching.
    ///   - automaticallyShowsCancelButton: A Boolean indicating whether the search controller manages the visibility of the search bar’s cancel button.
    func searchController(query: Binding<String>,
                          placeholder: String? = nil,
                          hidesNavigationBarDuringPresentation: Bool = false,
                          automaticallyShowsCancelButton: Bool = true) -> some View {
        background {
            SearchController(searchQuery: query,
                             placeholder: placeholder,
                             hidesNavigationBarDuringPresentation: hidesNavigationBarDuringPresentation,
                             automaticallyShowsCancelButton: automaticallyShowsCancelButton)
        }
    }
}

private struct InteractiveDismissSearchModifier: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    
    func body(content: Content) -> some View {
        content
            .interactiveDismissDisabled(isSearching)
    }
}

private struct DismissSearchOnDisappear: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismissSearch) private var dismissSearch
    
    func body(content: Content) -> some View {
        content
            .onDisappear {
                if isSearching {
                    dismissSearch()
                }
            }
    }
}

private struct SearchController: UIViewControllerRepresentable {
    @Binding var searchQuery: String
    
    var placeholder: String?
    var hidesNavigationBarDuringPresentation = false
    var automaticallyShowsCancelButton = true
    var hidesSearchBarWhenScrolling = false
    
    func makeUIViewController(context: Context) -> SearchInjectionViewController {
        SearchInjectionViewController(searchController: context.coordinator.searchController,
                                      hidesSearchBarWhenScrolling: hidesSearchBarWhenScrolling)
    }
    
    func updateUIViewController(_ viewController: SearchInjectionViewController, context: Context) {
        let searchController = viewController.searchController
        searchController.searchBar.text = searchQuery
        searchController.hidesNavigationBarDuringPresentation = hidesNavigationBarDuringPresentation
        searchController.automaticallyShowsCancelButton = automaticallyShowsCancelButton
        
        if let placeholder { // Blindly setting nil clears the default placeholder.
            searchController.searchBar.placeholder = placeholder
        }
        
        viewController.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(searchQuery: $searchQuery)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate, UISearchControllerDelegate {
        let searchController = UISearchController()
        private let searchQuery: Binding<String>
        
        init(searchQuery: Binding<String>) {
            self.searchQuery = searchQuery
            
            super.init()
            
            searchController.delegate = self
            searchController.searchBar.delegate = self
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            searchQuery.wrappedValue = searchText
        }
        
        func willDismissSearchController(_ searchController: UISearchController) {
            // Clear any search results when the user taps cancel.
            searchQuery.wrappedValue = ""
        }
    }
    
    class SearchInjectionViewController: UIViewController {
        let searchController: UISearchController
        var hidesSearchBarWhenScrolling: Bool
        
        init(searchController: UISearchController, hidesSearchBarWhenScrolling: Bool) {
            self.searchController = searchController
            self.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
            super.init(nibName: nil, bundle: nil)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        override func willMove(toParent parent: UIViewController?) {
            parent?.navigationItem.searchController = searchController
            parent?.navigationItem.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
        }
    }
}
