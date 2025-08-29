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
                        RoomTimelineItemView(viewState: bookmark.timelineItemViewState)
                            .environment(\.timelineContext, bookmark.timelineContext)
                            .environmentObject(bookmark.timelineContext)
                        Text(bookmark.roomName)
                            .font(.compound.bodySMSemibold)
                            .foregroundStyle(.compound.textPrimary)
                            .padding(.leading, 32)
                    }
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
        let viewModel = BookmarksScreenViewModel(userSession: UserSessionMock(.init()),
                                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                 appMediator: AppMediatorMock.default,
                                                 appSettings: ServiceLocator.shared.settings,
                                                 analyticsService: ServiceLocator.shared.analytics,
                                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        return viewModel
    }
}
