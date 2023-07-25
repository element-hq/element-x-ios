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

struct TimelineView: View {
    let viewState: TimelineViewState
    @Environment(\.timelineStyle) private var timelineStyle

    private let bottomID = "RoomTimelineBottomPinIdentifier"
    private let topID = "RoomTimelineTopPinIdentifier"

    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var paginateBackwardsPublisher = PassthroughSubject<Void, Never>()
    @State private var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    @State private var scrollToBottomButtonVisible = false

    var body: some View {
        ScrollViewReader { scrollView in
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

                topPin
            }
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
            }
            .scaleEffect(x: 1, y: -1)
            .onReceive(scrollToBottomPublisher) { _ in
                withElementAnimation {
                    scrollView.scrollTo(bottomID)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .overlay(scrollToBottomButton, alignment: .bottomTrailing)
        .animation(.elementDefault, value: viewState.itemViewStates)
        .onReceive(scrollViewAdapter.didScroll) { _ in
            guard let scrollView = scrollViewAdapter.scrollView else {
                return
            }
            let offset = scrollView.contentOffset.y + scrollView.contentInset.top
            let scrollToBottomButtonVisibleValue = offset > 0
            if scrollToBottomButtonVisibleValue != scrollToBottomButtonVisible {
                scrollToBottomButtonVisible = scrollToBottomButtonVisibleValue
            }
            paginateBackwardsPublisher.send()

            // Allows the scroll to top to work properly
            if offset == 0 {
                scrollView.contentOffset.y -= 1
            }
        }
        .onReceive(paginateBackwardsPublisher.collect(.byTime(DispatchQueue.main, 0.1))) { _ in
            paginateBackwardsIfNeeded()
        }
        .onAppear {
            paginateBackwardsPublisher.send()
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
            scrollToBottomPublisher.send()
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
        .opacity(scrollToBottomButtonVisible ? 1.0 : 0.0)
        .accessibilityHidden(!scrollToBottomButtonVisible)
        .animation(.elementDefault, value: scrollToBottomButtonVisible)
    }

    private func paginateBackwardsIfNeeded() {
        guard let paginateAction = viewState.paginateAction,
              let scrollView = scrollViewAdapter.scrollView,
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

        paginateAction()
    }
}

// MARK: - Previews

struct TimelineTableView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                               appSettings: ServiceLocator.shared.settings,
                                               analytics: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController)
    
    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context)
        }
    }
}
