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
    
    @Binding var visibleEdges: [VerticalEdge]
    /// The last known value of the visible edges. This is stored because `visibleEdges`
    /// updates at the same time as the `viewFrame` but we need to know the previous
    /// value when the keyboard appears to determine whether to scroll to the bottom.
    @State private var cachedVisibleEdges: [VerticalEdge] = []
    
    @EnvironmentObject var context: RoomScreenViewModel.Context
    
    let scrollToBottomPublisher: PassthroughSubject<Void, Never>

    var body: some View {
        ScrollViewReader { scrollView in
            TimelineScrollView(visibleEdges: $visibleEdges) {
                // The scroll view already contains a VStack so simply provide the content to fill it.
                
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .opacity(context.viewState.isBackPaginating ? 1.0 : 0.0)
                    .animation(.elementDefault, value: context.viewState.isBackPaginating)
                
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
                        }
                        .onDisappear {
                            context.send(viewAction: .itemDisappeared(id: item.id))
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
            .onChange(of: visibleEdges) { edges in
                cachedVisibleEdges = edges
                // Paginate when the top becomes visible
                guard edges.contains(.top) else { return }
                requestBackPagination()
            }
            .onChange(of: context.viewState.isBackPaginating) { isBackPaginating in
                guard !isBackPaginating else { return }
                
                // Repeat the pagination if the top edge is still visible.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    guard visibleEdges.contains(.top) else { return }
                    requestBackPagination()
                }
            }
            .onChange(of: pinnedItem) { item in
                guard let item else { return }
                
                if item.animated {
                    withAnimation(Animation.elementDefault) {
                        scrollView.scrollTo(item.id, anchor: item.anchor)
                    }
                } else {
                    scrollView.scrollTo(item.id, anchor: item.anchor)
                }
                
                pinnedItem = nil
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background(ViewFrameReader(frame: $viewFrame))
        .timelineStyle(settings.timelineStyle)
        .onAppear {
            timelineItems = context.viewState.items
        }
        .onReceive(scrollToBottomPublisher) {
            scrollToBottom(animated: true)
        }
        .onChange(of: context.viewState.items) { items in
            guard
                !context.viewState.items.isEmpty,
                context.viewState.items.count != timelineItems.count
            else {
                // Update the items, but don't worry about scrolling if the count is unchanged.
                timelineItems = items
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
            if visibleEdges.contains(.bottom), let newLastItem = context.viewState.items.last {
                let pinnedItem = PinnedItem(id: newLastItem.id, anchor: .bottom, animated: false)
                timelineItems = context.viewState.items
                self.pinnedItem = pinnedItem
                
                return
            }
            
            // Pin to the old topmost visible
            if visibleEdges.contains(.top), let currentFirstItem = timelineItems.first {
                let pinnedItem = PinnedItem(id: currentFirstItem.id, anchor: .top, animated: false)
                timelineItems = context.viewState.items
                self.pinnedItem = pinnedItem
                
                return
            }
            
            // Otherwise just update the items
            timelineItems = context.viewState.items
        }
        .onChange(of: viewFrame) { _ in
            // Use the cached version as visibleEdges will already have changed
            // (but its onChange handler is yet to be called - possible race condition?)
            guard cachedVisibleEdges.contains(.bottom) else { return }
            
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
        
        TimelineItemList(visibleEdges: .constant([]), scrollToBottomPublisher: PassthroughSubject())
            .environmentObject(viewModel.context)
    }
}
