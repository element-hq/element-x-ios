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
import Introspect
import SwiftUI

struct TimelineItemList: View {
    @State private var collectionViewObserver = ListCollectionViewAdapter()
    @State private var timelineItems: [RoomTimelineViewProvider] = []
    @State private var hasPendingChanges = false
    @ObservedObject private var settings = ElementSettings.shared
    
    @EnvironmentObject var context: RoomScreenViewModel.Context
    
    let bottomVisiblePublisher: PassthroughSubject<Bool, Never>
    let scrollToBottomPublisher: PassthroughSubject<Void, Never>

    @State private var viewFrame: CGRect = .zero

    var body: some View {
        List {
            ProgressView()
                .frame(maxWidth: .infinity)
                .opacity(context.viewState.isBackPaginating ? 1.0 : 0.0)
                .animation(.elementDefault, value: context.viewState.isBackPaginating)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            
            // timelineItems won't be set for static Xcode Previews until they're run.
            ForEach(isPreview ? context.viewState.items : timelineItems) { timelineItem in
                timelineItem
                    .contextMenu {
                        context.viewState.contextMenuBuilder?(timelineItem.id)
                    }
                    .opacity(opacityForItem(timelineItem))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(settings.timelineStyle.listRowInsets)
                    .onAppear {
                        context.send(viewAction: .itemAppeared(id: timelineItem.id))
                    }
                    .onDisappear {
                        context.send(viewAction: .itemDisappeared(id: timelineItem.id))
                    }
                    .environment(\.openURL, OpenURLAction { url in
                        context.send(viewAction: .linkClicked(url: url))
                        return .systemAction
                    })
            }
        }
        .listStyle(.plain)
        .background(ViewFrameReader(frame: $viewFrame))
        .environment(\.timelineWidth, viewFrame.width)
        .timelineStyle(settings.timelineStyle)
        .environment(\.defaultMinListRowHeight, 0.0)
        .introspectCollectionView { collectionView in
            if collectionView == collectionViewObserver.collectionView { return }
            
            collectionViewObserver = ListCollectionViewAdapter(collectionView: collectionView,
                                                               topDetectionOffset: collectionView.bounds.size.height / 3.0,
                                                               bottomDetectionOffset: 10.0)
            
            collectionViewObserver.scrollToBottom()
            
            // Check if there are enough items. Otherwise ask for more
            attemptBackPagination()
        }
        .onAppear {
            if timelineItems != context.viewState.items {
                timelineItems = context.viewState.items
            }
        }
        .onReceive(scrollToBottomPublisher) {
            collectionViewObserver.scrollToBottom(animated: true)
        }
        .onReceive(collectionViewObserver.scrollViewTopVisiblePublisher) { isTopVisible in
            if !isTopVisible || context.viewState.isBackPaginating {
                return
            }
            
            attemptBackPagination()
        }
        .onReceive(collectionViewObserver.scrollViewBottomVisiblePublisher) { isBottomVisible in
            bottomVisiblePublisher.send(isBottomVisible)
        }
        .onChange(of: context.viewState.items) { _ in
            // If the count hasn't changed then don't observe a pagination
            guard context.viewState.items.count != timelineItems.count else {
                timelineItems = context.viewState.items
                return
            }
            
            // Don't update the list while moving
            if collectionViewObserver.isDecelerating || collectionViewObserver.isTracking {
                hasPendingChanges = true
                return
            }
            
            collectionViewObserver.saveCurrentOffset()
            timelineItems = context.viewState.items
        }
        .onReceive(collectionViewObserver.scrollViewDidRestPublisher) {
            if hasPendingChanges == false {
                return
            }
            
            collectionViewObserver.saveCurrentOffset()
            timelineItems = context.viewState.items
            hasPendingChanges = false
        }
        .onChange(of: timelineItems.count) { _ in
            collectionViewObserver.restoreSavedOffset()
            
            // Check if there are enough items. Otherwise ask for more
            attemptBackPagination()
        }
    }
    
    func scrollToBottom(animated: Bool = false) {
        collectionViewObserver.scrollToBottom(animated: animated)
    }
    
    private func attemptBackPagination() {
        if context.viewState.isBackPaginating {
            return
        }
        
        if collectionViewObserver.scrollViewTopVisiblePublisher.value == false {
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
    
    private var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
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
        
        TimelineItemList(bottomVisiblePublisher: PassthroughSubject(), scrollToBottomPublisher: PassthroughSubject())
            .environmentObject(viewModel.context)
    }
}
