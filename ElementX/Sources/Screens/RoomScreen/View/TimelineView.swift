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

import SwiftUI

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

struct TimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle

    private let scrollAreaId = "scrollArea"
    private let bottomID = "bottomID"

    @State private var height: CGFloat?
    @State private var offset: CGFloat?

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                GeometryReader { proxy in
                    let frame = proxy.frame(in: .named(scrollAreaId))
                    // Since the scroll view is flipped the offset maxY is inverted
                    let offset = -frame.maxY
                    let height = frame.height
                    Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                    Color.clear.preference(key: HeightPreferenceKey.self, value: height)
                }
                // It takes a little space so we give it 0 in height
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
            }
            .coordinateSpace(name: scrollAreaId)
            .scaleEffect(x: 1, y: -1)
            .animation(.default, value: context.viewState.itemViewModels)
            .onPreferenceChange(HeightPreferenceKey.self) { value in
                guard let value, value != height else {
                    return
                }
                height = value
            }
            .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                guard let value else {
                    return
                }
                context.scrollToBottomButtonVisible = value > 0
            }
            .onReceive(context.viewState.scrollToBottomPublisher) {
                guard let last = context.viewState.timelineIDs.last else {
                    return
                }
                withAnimation {
                    scrollView.scrollTo(bottomID)
                }
            }
        }
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
