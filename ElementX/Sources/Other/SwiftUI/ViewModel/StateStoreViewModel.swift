//
// Copyright 2022 New Vector Ltd
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

import Combine
import Foundation

/// A common ViewModel implementation for handling of `State` and `ViewAction`s
///
/// Generic type State is constrained to the BindableState protocol in that it may contain (but doesn't have to)
/// a specific portion of state that can be safely bound to.
/// If we decide to add more features to our state management (like doing state processing off the main thread)
/// we can do it in this centralised place.
@MainActor
class StateStoreViewModel<State: BindableState, ViewAction> {
    /// For storing subscription references.
    ///
    /// Left as public for `ViewModel` implementations convenience.
    var cancellables = Set<AnyCancellable>()

    /// Constrained interface for passing to Views.
    var context: Context

    var state: State {
        get { context.viewState }
        set { context.viewState = newValue }
    }

    init(initialViewState: State, imageProvider: ImageProviderProtocol? = nil) {
        context = Context(initialViewState: initialViewState, imageProvider: imageProvider)
        context.viewModel = self
    }

    /// Override to handles incoming `ViewAction`s from the `ViewModel`.
    /// - Parameter viewAction: The `ViewAction` to be processed in `ViewModel` implementation.
    func process(viewAction: ViewAction) {
        // Default implementation, -no-op
    }

    // MARK: - Context

    /// A constrained and concise interface for interacting with the ViewModel.
    ///
    /// This class is closely bound to`StateStoreViewModel`. It provides the exact interface the view should need to interact
    /// ViewModel (as modelled on our previous template architecture with the addition of two-way binding):
    /// - The ability read/observe view state
    /// - The ability to send view events
    /// - The ability to bind state to a specific portion of the view state safely.
    /// This class was brought about a little bit by necessity. The most idiomatic way of interacting with SwiftUI is via `@Published`
    /// properties which which are property wrappers and therefore can't be defined within protocols.
    /// A similar approach is taken in libraries like [CombineFeedback](https://github.com/sergdort/CombineFeedback).
    /// It provides a nice layer of consistency and also safety. As we are not passing the `ViewModel` to the view directly, shortcuts/hacks
    /// can't be made into the `ViewModel`.
    @dynamicMemberLookup
    @MainActor
    final class Context: ObservableObject {
        fileprivate weak var viewModel: StateStoreViewModel?
    
        /// Get-able/Observable `Published` property for the `ViewState`
        @Published fileprivate(set) var viewState: State
    
        /// An optional image loading service so that views can manage themselves
        /// Intentionally non-generic so that it doesn't grow uncontrollably
        let imageProvider: ImageProviderProtocol?
    
        /// Set-able/Bindable access to the bindable state.
        subscript<T>(dynamicMember keyPath: WritableKeyPath<State.BindStateType, T>) -> T {
            get { viewState.bindings[keyPath: keyPath] }
            set { viewState.bindings[keyPath: keyPath] = newValue }
        }
    
        /// Send a `ViewAction` to the `ViewModel` for processing.
        /// - Parameter viewAction: The `ViewAction` to send to the `ViewModel`.
        func send(viewAction: ViewAction) {
            viewModel?.process(viewAction: viewAction)
        }
    
        fileprivate init(initialViewState: State, imageProvider: ImageProviderProtocol?) {
            self.viewState = initialViewState
            self.imageProvider = imageProvider
        }
    }
}
