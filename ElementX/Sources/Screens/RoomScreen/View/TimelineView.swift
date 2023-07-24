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

import OrderedCollections
import SwiftUIIntrospect

struct TimelineView: View {
    @ObservedObject var viewState: TimelineViewState
    @Environment(\.timelineStyle) private var timelineStyle

    private let bottomID = "bottomID"

    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var paginateBackwardsPublisher = PassthroughSubject<Void, Never>()
    @State private var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    @State private var scrollToBottomButtonVisible = false

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                // Only used ton get to the bottom of the scroll view
                Divider()
                    .id(bottomID)
                    .hidden()
                    .frame(height: 0)

                LazyVStack(spacing: 0) {
                    ForEach(viewState.timelineIDs.reversed(), id: \.self) { id in
                        if let viewModel = viewState.itemsDictionary[id] {
                            RoomTimelineItemView(viewModel: viewModel)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(timelineStyle.rowInsets)
                                .scaleEffect(x: 1, y: -1)
                        }
                    }
                }
            }
            .introspect(.scrollView, on: .iOS(.v16)) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scaleEffect(x: 1, y: -1)
            .animation(.elementDefault, value: viewState.itemsDictionary)
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
            }
            .onReceive(scrollToBottomPublisher) { _ in
                withAnimation {
                    scrollView.scrollTo(bottomID)
                }
            }
            .onReceive(paginateBackwardsPublisher.collect(.byTime(DispatchQueue.main, 0.1))) { _ in
                tryPaginateBackwards()
            }
        }
        .overlay(scrollToBottomButton, alignment: .bottomTrailing)
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

    private func tryPaginateBackwards() {
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
