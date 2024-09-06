//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import SwiftUIIntrospect

// MARK: - Search Controller Extensions

extension View {
    /// A custom replacement for searchable that allows more precise configuration of the underlying search controller.
    ///
    /// Whilst we originally used introspect to configure parameters such as preventing the navigation bar from hiding
    /// during a search, this proved unreliable from iOS 17.1 onwards. This implementation avoids all of those shenanigans.
    /// **Note:** For some reason the font size is incorrect in the PreviewTests, buts its fine in UI tests and within the app.
    ///
    /// - Parameters:
    ///   - query: The current or starting search text.
    ///   - placeholder: The string to display when there’s no other text in the text field.
    ///   - hidesNavigationBar: A Boolean indicating whether to hide the navigation bar when searching.
    ///   - showsCancelButton: A Boolean indicating whether the search controller manages the visibility of the search bar’s cancel button.
    ///   - disablesInteractiveDismiss: Whether or not interactive dismiss is disabled whilst the user is searching.
    func searchController(query: Binding<String>,
                          placeholder: String? = nil,
                          hidesNavigationBar: Bool = false,
                          showsCancelButton: Bool = true,
                          disablesInteractiveDismiss: Bool = false) -> some View {
        modifier(SearchControllerModifier(searchQuery: query,
                                          placeholder: placeholder,
                                          hidesNavigationBar: hidesNavigationBar,
                                          showsCancelButton: showsCancelButton,
                                          disablesInteractiveDismiss: disablesInteractiveDismiss))
    }
}

private struct SearchControllerModifier: ViewModifier {
    @Binding var searchQuery: String
    
    let placeholder: String?
    let hidesNavigationBar: Bool
    let showsCancelButton: Bool
    let disablesInteractiveDismiss: Bool
    
    /// Whether or not the user is currently searching. When ``automaticallyShowsCancelButton``
    /// is `false`, checking if this value is `false` is pretty much meaningless.
    @State private var isSearching = false
    
    func body(content: Content) -> some View {
        content
            .interactiveDismissDisabled(!searchQuery.isEmpty && disablesInteractiveDismiss)
            .background {
                SearchController(searchQuery: $searchQuery,
                                 placeholder: placeholder,
                                 hidesNavigationBar: hidesNavigationBar,
                                 showsCancelButton: showsCancelButton,
                                 hidesSearchBarWhenScrolling: false,
                                 isSearching: $isSearching)
            }
            .onDisappear {
                // Dismiss search when the view disappears to tidy up appearance when popping back to the view.
                if isSearching {
                    isSearching = false
                }
            }
    }
}

private struct SearchController: UIViewControllerRepresentable {
    @Binding var searchQuery: String
    
    let placeholder: String?
    let hidesNavigationBar: Bool
    let showsCancelButton: Bool
    let hidesSearchBarWhenScrolling: Bool
    
    @Binding var isSearching: Bool
    
    func makeUIViewController(context: Context) -> SearchInjectionViewController {
        SearchInjectionViewController(searchController: context.coordinator.searchController,
                                      hidesSearchBarWhenScrolling: hidesSearchBarWhenScrolling)
    }
    
    func updateUIViewController(_ viewController: SearchInjectionViewController, context: Context) {
        let searchController = viewController.searchController
        searchController.searchBar.text = searchQuery
        searchController.hidesNavigationBarDuringPresentation = hidesNavigationBar
        searchController.automaticallyShowsCancelButton = showsCancelButton
        
        if searchController.isActive, !isSearching {
            DispatchQueue.main.async { searchController.isActive = false }
        } else if !searchController.isActive, isSearching {
            DispatchQueue.main.async { searchController.isActive = true }
        }
        
        if let placeholder { // Blindly setting nil clears the default placeholder.
            searchController.searchBar.placeholder = placeholder
        }
        
        viewController.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(searchQuery: $searchQuery, isSearching: $isSearching)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate, UISearchControllerDelegate {
        let searchController = UISearchController()
        private let searchQuery: Binding<String>
        private let isSearching: Binding<Bool>
        
        init(searchQuery: Binding<String>, isSearching: Binding<Bool>) {
            self.searchQuery = searchQuery
            self.isSearching = isSearching
            
            super.init()
            
            searchController.delegate = self
            searchController.searchBar.delegate = self
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            searchQuery.wrappedValue = searchText
        }
        
        func didPresentSearchController(_ searchController: UISearchController) {
            isSearching.wrappedValue = true
        }
        
        func willDismissSearchController(_ searchController: UISearchController) {
            // Clear any search results when the user taps cancel.
            searchQuery.wrappedValue = ""
        }
        
        func didDismissSearchController(_ searchController: UISearchController) {
            isSearching.wrappedValue = false
        }
    }
    
    class SearchInjectionViewController: UIViewController {
        let searchController: UISearchController
        var hidesSearchBarWhenScrolling: Bool
        
        init(searchController: UISearchController, hidesSearchBarWhenScrolling: Bool) {
            self.searchController = searchController
            self.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
            
            super.init(nibName: nil, bundle: nil)
            
            view.alpha = 0
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        override func willMove(toParent parent: UIViewController?) {
            parent?.navigationItem.searchController = searchController
            parent?.navigationItem.preferredSearchBarPlacement = .stacked
            parent?.navigationItem.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
        }
    }
}

// MARK: - Searchable Extensions

struct IsSearchingModifier: ViewModifier {
    @Environment(\.isSearching) private var isSearchingEnv
    @Binding var isSearching: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isSearchingEnv) { isSearching = $0 }
    }
}

extension View {
    func isSearching(_ isSearching: Binding<Bool>) -> some View {
        modifier(IsSearchingModifier(isSearching: isSearching))
    }
}
