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
    @State private var timelineItems: [RoomTimelineViewProvider] = []
    
    @EnvironmentObject var context: RoomScreenViewModel.Context
    
    let scrollToBottomPublisher: PassthroughSubject<Void, Never>

    var body: some View {
        TimelineScrollView(visibleEdges: .constant([])) {
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
        .scrollDismissesKeyboard(.immediately)
        .onReceive(scrollToBottomPublisher) {
            scrollToBottom(animated: true)
        }
    }
    
    // MARK: - Private
    
    private func scrollToBottom(animated: Bool = false) { /* removed */ }
    
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

struct TimelineItemList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: nil)
        
        TimelineItemList(scrollToBottomPublisher: PassthroughSubject())
            .environmentObject(viewModel.context)
    }
}
