//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ChatsSpaceFiltersScreen: View {
    @Bindable var context: ChatsSpaceFiltersScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(context.viewState.visibleFilters) { filter in
                        ChatsSpaceFilterCell(filter: filter,
                                             mediaProvider: context.mediaProvider) { filter in
                            context.send(viewAction: .confirm(filter))
                        }
                    }
                }
                .searchable(text: $context.searchQuery, placement: .navigationBarDrawer)
                .focusSearchIfHardwareKeyboardAvailable()
                .compoundSearchField()
            }
            .toolbar { toolbar }
            .navigationTitle(L10n.screenRoomlistYourSpaces)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .cancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct ChatsSpaceFiltersScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        ChatsSpaceFiltersScreen(context: viewModel.context)
    }
    
    static func makeViewModel() -> ChatsSpaceFiltersScreenViewModel {
        ChatsSpaceFiltersScreenViewModel(spaceService: SpaceServiceProxyMock(.populated),
                                         mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
