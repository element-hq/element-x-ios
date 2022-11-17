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

struct TimelineItemList: View {
    @ObservedObject private var settings = ElementSettings.shared
    
    @State private var timelineItems: [RoomTimelineViewProvider] = []
    @State private var viewFrame: CGRect = .zero
    @State private var pinnedItem: PinnedItem?
    @State private var visibleItemIdentifiers: Set<String> = []
    @State private var topVisiblePublisher = CurrentValueSubject<Bool, Never>(false)
    
    @EnvironmentObject var context: RoomScreenViewModel.Context
    
    let bottomVisiblePublisher: CurrentValueSubject<Bool, Never>
    let scrollToBottomPublisher: PassthroughSubject<Void, Never>

    var body: some View {
        ScrollViewReader { proxy in
            ReversedScrollView(.vertical) {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .opacity(context.viewState.isBackPaginating ? 1.0 : 0.0)
                    .animation(.elementDefault, value: context.viewState.isBackPaginating)
                
                LazyVStack(alignment: .leading, spacing: 0.0) {
                    ForEach(isRunningPreviews ? context.viewState.items : timelineItems) { item in
                        item
                            .contextMenu {
                                context.viewState.contextMenuBuilder?(item.id)
                                    .id(item.id)
                            }
                            .opacity(opacityForItem(item))
                            .padding(settings.timelineStyle.rowInsets)
                            .onAppear {
                                context.send(viewAction: .itemAppeared(id: item.id))
                                visibleItemIdentifiers.insert(item.id)
                                
                                if timelineItems.first == item {
                                    topVisiblePublisher.send(true)
                                }
                                
                                if timelineItems.last == item {
                                    bottomVisiblePublisher.send(true)
                                }
                            }
                            .onDisappear {
                                context.send(viewAction: .itemDisappeared(id: item.id))
                                visibleItemIdentifiers.remove(item.id)
                                
                                if timelineItems.first == item {
                                    topVisiblePublisher.send(false)
                                }
                                
                                if timelineItems.last == item {
                                    bottomVisiblePublisher.send(false)
                                }
                            }
                            .environment(\.openURL, OpenURLAction { url in
                                context.send(viewAction: .linkClicked(url: url))
                                return .systemAction
                            })
                            .onTapGesture {
                                context.send(viewAction: .itemTapped(id: item.id))
                            }
                    }
                }
            }
            .onChange(of: pinnedItem) { item in
                guard let item else {
                    return
                }
                
                if item.animated {
                    withAnimation(Animation.elementDefault) {
                        proxy.scrollTo(item.id, anchor: item.anchor)
                    }
                } else {
                    proxy.scrollTo(item.id, anchor: item.anchor)
                }
                
                pinnedItem = nil
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background(ViewFrameReader(frame: $viewFrame))
        .timelineStyle(settings.timelineStyle)
        .onAppear {
            timelineItems = context.viewState.items
            requestBackPagination()
        }
        // Allow SwiftUI to layout the views properly before checking if the top is visible
        .onReceive(topVisiblePublisher.collect(.byTime(DispatchQueue.main, 0.5))) { values in
            if values.last == true {
                requestBackPagination()
            }
        }
        .onReceive(scrollToBottomPublisher) {
            scrollToBottom(animated: true)
        }
        .onChange(of: context.viewState.items.count) { _ in
            guard !context.viewState.items.isEmpty,
                  context.viewState.items.count != timelineItems.count else {
                return
            }
            
            // Pin to the bottom if empty
            if timelineItems.isEmpty {
                if let lastItem = context.viewState.items.last {
                    let pinnedItem = PinnedItem(id: lastItem.id, anchor: .bottom, animated: false)
                    timelineItems = context.viewState.items
                    self.pinnedItem = pinnedItem
                }
                
                return
            }
            
            // Pin to the new bottom if visible
            if let currentLastItem = timelineItems.last,
               visibleItemIdentifiers.contains(currentLastItem.id),
               let newLastItem = context.viewState.items.last {
                let pinnedItem = PinnedItem(id: newLastItem.id, anchor: .bottom, animated: false)
                timelineItems = context.viewState.items
                self.pinnedItem = pinnedItem
                
                return
            }
            
            // Pin to the old topmost visible
            if let currentFirstItem = timelineItems.first,
               visibleItemIdentifiers.contains(currentFirstItem.id) {
                let pinnedItem = PinnedItem(id: currentFirstItem.id, anchor: .top, animated: false)
                timelineItems = context.viewState.items
                self.pinnedItem = pinnedItem
                
                return
            }
            
            // Otherwise just update the items
            timelineItems = context.viewState.items
        }
        .onChange(of: context.viewState.items, perform: { items in
            if timelineItems != items {
                timelineItems = items
            }
        })
        .background(GeometryReader { geo in
            Color.clear.preference(key: ViewFramePreferenceKey.self, value: [geo.frame(in: .global)])
        })
        .onPreferenceChange(ViewFramePreferenceKey.self) { _ in
            guard bottomVisiblePublisher.value == true else {
                return
            }
            
            // Pin the timeline to the bottom if was there on the frame change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToBottom(animated: true)
            }
        }
    }
    
    // MARK: - Private
    
    private func scrollToBottom(animated: Bool = false) {
        if let lastItem = timelineItems.last {
            pinnedItem = PinnedItem(id: lastItem.id, anchor: .bottom, animated: animated)
        }
    }
    
    private func requestBackPagination() {
        guard !context.viewState.isBackPaginating else {
            return
        }
        context.send(viewAction: .loadPreviousPage)
    }
    
    private func opacityForItem(_ item: RoomTimelineViewProvider) -> Double {
        guard case let .reply(selectedItemId, _) = context.viewState.composerMode else {
            return 1.0
        }
        
        return selectedItemId == item.id ? 1.0 : 0.5
    }
    
    private var isRunningPreviews: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}

private struct PinnedItem: Equatable {
    let id: String
    let anchor: UnitPoint
    let animated: Bool
}

private struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue = [CGRect]() // Doesn't work with plain CGRects
    
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value += nextValue()
    }
}

struct TimelineItemList_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: nil)
        
        TimelineItemList(bottomVisiblePublisher: CurrentValueSubject(false), scrollToBottomPublisher: PassthroughSubject())
            .environmentObject(viewModel.context)
    }
}
