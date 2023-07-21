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

struct TimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle

    private let visibleArea = "visibleArea"
    private let scrollAreaID = "scrollArea"
    private let bottomID = "bottomID"

    @State private var contentHeight: CGFloat?
    @State private var offset: CGFloat?
    @State private var visibleHeight: CGFloat?
    @State private var paginateBackwardsPublisher = PassthroughSubject<Void, Never>()

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                // This is used as a pointer to the bottom of the view
                // both for scrolling purposes and to understand the
                // current content offset
                GeometryReader { proxy in
                    let frame = proxy.frame(in: .named(scrollAreaID))
                    // Since the scroll view is flipped the offset maxY is inverted
                    let offset = -frame.maxY
                    Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                }
                // It takes a little bit of space so we give it 0 in height
                .frame(height: 0)
                .id(bottomID)

                LazyVStack(spacing: 0) {
                    ForEach(context.viewState.itemViewModels.reversed()) { viewModel in
                        RoomTimelineItemView(viewModel: viewModel)
                            .environmentObject(context)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(timelineStyle.rowInsets)
                            .scaleEffect(x: 1, y: -1)
                    }
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            }
            .coordinateSpace(name: scrollAreaID)
            .scaleEffect(x: 1, y: -1)
            .animation(.default, value: context.viewState.itemViewModels)
            .onPreferenceChange(ContentHeightPreferenceKey.self) { value in
                guard let value, value != contentHeight else {
                    return
                }

                contentHeight = value
            }
            .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                guard let value, value != offset else {
                    return
                }

                offset = value
                context.scrollToBottomButtonVisible = value > 0

                paginateBackwardsPublisher.send()
            }
            .onReceive(context.viewState.scrollToBottomPublisher) {
                withAnimation {
                    scrollView.scrollTo(bottomID)
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: VisibleHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(VisibleHeightPreferenceKey.self) { value in
                guard let value, value != visibleHeight else {
                    return
                }
                visibleHeight = value
            }
            .onReceive(paginateBackwardsPublisher.collect(.byTime(DispatchQueue.main, 0.1))) { _ in
                guard let offset,
                      let contentHeight,
                      let visibleHeight,
                      context.viewState.canBackPaginate,
                      !context.viewState.isBackPaginating,
                      offset > contentHeight - visibleHeight * 2.0 else {
                    return
                }

                context.send(viewAction: .paginateBackwards)
            }
        }
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
