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

import Introspect

struct TimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle

    private let bottomID = "bottomID"

    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var paginateBackwardsPublisher = PassthroughSubject<Void, Never>()

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                // Only used ton get to the bottom of the scroll view
                Divider()
                    .id(bottomID)
                    .hidden()
                    .frame(height: 0)

                LazyVStack(spacing: 0) {
                    ForEach(context.viewState.itemViewModels.reversed()) { viewModel in
                        RoomTimelineItemView(viewModel: viewModel)
                            .environmentObject(context)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(timelineStyle.rowInsets)
                            .scaleEffect(x: 1, y: -1)
                    }
                }
            }
            .introspect(.scrollView, on: .iOS(.v16)) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scaleEffect(x: 1, y: -1)
            .animation(.elementDefault, value: context.viewState.itemViewModels)
            .onReceive(scrollViewAdapter.didScroll) { _ in
                guard let scrollView = scrollViewAdapter.scrollView else {
                    return
                }
                let offset = scrollView.contentOffset.y + scrollView.contentInset.top
                context.scrollToBottomButtonVisible = offset > 0
                paginateBackwardsPublisher.send()
            }
            .onReceive(context.viewState.scrollToBottomPublisher) { _ in
                withAnimation {
                    scrollView.scrollTo(bottomID)
                }
            }
            .onReceive(paginateBackwardsPublisher.collect(.byTime(DispatchQueue.main, 0.1))) { _ in
                tryPaginateBackwards()
            }
        }
    }

    private func tryPaginateBackwards() {
        guard let scrollView = scrollViewAdapter.scrollView,
              context.viewState.canBackPaginate,
              !context.viewState.isBackPaginating else {
            return
        }

        let visibleHeight = scrollView.visibleSize.height
        let contentHeight = scrollView.contentSize.height
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        let threshold = contentHeight - visibleHeight * 2

        guard offset > threshold else {
            return
        }

        context.send(viewAction: .paginateBackwards)
    }
}

private struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

private struct VisibleHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
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
