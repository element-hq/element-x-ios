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
import SwiftUI

import SwiftUIIntrospect
import WysiwygComposer

struct TimelineView: View {
    let viewState: TimelineViewState
    @Binding var isScrolledToBottom: Bool
    let paginationAction: () -> Void

    @Environment(\.timelineStyle) private var timelineStyle

    private let bottomID = "RoomTimelineBottomPinIdentifier"
    private let topID = "RoomTimelineTopPinIdentifier"

    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var paginateBackwardsPublisher = PassthroughSubject<Void, Never>()

    var body: some View {
        ScrollViewReader { scrollView in
            timelineScrollView
                .introspect(.scrollView, on: .iOS(.v16)) { uiScrollView in
                    guard uiScrollView != scrollViewAdapter.scrollView else {
                        return
                    }

                    scrollViewAdapter.scrollView = uiScrollView
                    scrollViewAdapter.shouldScrollToTopClosure = { _ in
                        withElementAnimation {
                            scrollView.scrollTo(topID)
                        }
                        return false
                    }

                    // Allows the scroll to top to work properly
                    uiScrollView.contentOffset.y -= 1
                    paginateBackwardsPublisher.send()
                }
                .scaleEffect(x: 1, y: -1)
                .onReceive(viewState.scrollToBottomPublisher) { _ in
                    withElementAnimation {
                        scrollView.scrollTo(bottomID)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
        }
        .overlay(scrollToBottomButton, alignment: .bottomTrailing)
        .onReceive(scrollViewAdapter.didScroll) { _ in
            guard let scrollView = scrollViewAdapter.scrollView else {
                return
            }
            let offset = scrollView.contentOffset.y + scrollView.contentInset.top

            let isScrolledToBottom = offset <= 0
            
            // Only update the binding on changes to avoid needlessly recomputing the hierarchy when scrolling.
            if self.isScrolledToBottom != isScrolledToBottom {
                self.isScrolledToBottom = isScrolledToBottom
            }

            // Allows the scroll to top to work properly
            if offset == 0 {
                scrollView.contentOffset.y -= 1
            }

            paginateBackwardsPublisher.send()
        }
        .onReceive(paginateBackwardsPublisher.collect(.byTime(DispatchQueue.main, 0.1))) { _ in
            paginateBackwardsIfNeeded()
        }
        .onAppear {
            paginateBackwardsPublisher.send()
        }
    }

    private var timelineScrollView: some View {
        ScrollView {
            bottomPin
            LazyVStack(spacing: 0) {
                ForEach(viewState.itemViewStates.reversed()) { viewState in
                    RoomTimelineItemView(viewState: viewState)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(timelineStyle.rowInsets)
                        .scaleEffect(x: 1, y: -1)
                }
            }
            .animation(.elementDefault, value: viewState.itemViewStates)
            topPin
        }
    }

    /// Used to mark the top of the scroll view and easily scroll to it
    private var topPin: some View {
        Divider()
            .id(topID)
            .hidden()
            .frame(height: 0)
    }

    /// Used to mark the bottom of the scroll view and easily scroll to it
    private var bottomPin: some View {
        Divider()
            .id(bottomID)
            .hidden()
            .frame(height: 0)
    }

    private var scrollToBottomButton: some View {
        Button {
            viewState.scrollToBottomPublisher.send()
        } label: {
            Image(systemName: "chevron.down")
                .font(.compound.bodyLG)
                .fontWeight(.semibold)
                .foregroundColor(.compound.iconSecondary)
                .padding(13)
                .offset(y: 1)
                .background {
                    Circle()
                        .fill(Color.compound.iconOnSolidPrimary)
                        // Intentionally using system primary colour to get white/black.
                        .shadow(color: .primary.opacity(0.33), radius: 2.0)
                }
                .padding()
        }
        .opacity(isScrolledToBottom ? 0.0 : 1.0)
        .accessibilityHidden(isScrolledToBottom)
        .animation(.elementDefault, value: isScrolledToBottom)
    }

    private func paginateBackwardsIfNeeded() {
        guard let scrollView = scrollViewAdapter.scrollView,
              viewState.canBackPaginate,
              !viewState.isBackPaginating else {
            return
        }

        let visibleHeight = scrollView.visibleSize.height
        let contentHeight = scrollView.contentSize.height
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        let threshold = contentHeight - visibleHeight * 2

        guard offset > threshold else {
            return
        }

        paginationAction()
    }
}

// MARK: - Previews

struct TimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                               appSettings: ServiceLocator.shared.settings,
                                               analytics: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController)

    static let wysiwygViewModel = WysiwygComposerViewModel()
    static let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel)
    static let composerToolbar = ComposerToolbar(context: composerViewModel.context,
                                                 wysiwygViewModel: wysiwygViewModel,
                                                 keyCommandHandler: { _ in false })
    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: composerToolbar)
        }
    }
}
