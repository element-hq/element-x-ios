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
    
    /// Configures a searchable's underlying search controller.
    /// - Parameters:
    ///   - hidesNavigationBar: A Boolean indicating whether to hide the navigation bar when searching.
    ///   - showsCancelButton: A Boolean indicating whether the search controller manages the visibility of the search bar’s cancel button.
    ///
    ///   This modifier may be moved into Compound once styles for the various configuration options have been defined.
    func searchableConfiguration(hidesNavigationBar: Bool = true,
                                 showsCancelButton: Bool = true) -> some View {
        introspect(.navigationStack, on: .iOS(.v16), scope: .ancestor) { navigationController in
            guard let searchController = navigationController.navigationBar.topItem?.searchController else { return }
            searchController.hidesNavigationBarDuringPresentation = hidesNavigationBar
            searchController.automaticallyShowsCancelButton = showsCancelButton
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
