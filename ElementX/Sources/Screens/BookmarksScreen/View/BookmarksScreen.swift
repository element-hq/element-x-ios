//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct BookmarksScreen: View {
    @Bindable var context: BookmarksScreenViewModel.Context
    
    var body: some View {
        bookmarks
            .navigationTitle("Bookmarks")
            .toolbar { toolbar }
    }
    
    @ViewBuilder
    private var bookmarks: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(context.viewState.items) { bookmark in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookmark.body)
                        Text(bookmark.roomName)
                    }
                    .bubbleBackground(isOutgoing: true,
                                      insets: .init(top: 4, leading: 4, bottom: 4, trailing: 4),
                                      color: .compound._bgBubbleOutgoing)
                }
            }
            .padding()
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionDone) { context.send(viewAction: .dismiss) }
        }
    }
}

// MARK: - Previews

struct BookmarksScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        NavigationStack {
            BookmarksScreen(context: viewModel.context)
        }
    }
    
    static func makeViewModel() -> BookmarksScreenViewModel {
        let viewModel = BookmarksScreenViewModel(clientProxy: ClientProxyMock())
        
        return viewModel
    }
}
