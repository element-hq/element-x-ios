// 
// Copyright 2021 New Vector Ltd
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
import Introspect
import Combine

struct RoomScreen: View {
    
    @State private var scrollViewObserver: ScrollViewObserver = ScrollViewObserver()
    @State private var messages: [RoomTimelineItem] = []
    
    @State private var didRequestBackPagination = false
    @State private var hasPendingMessages = false
    @State private var wasBottomVisible = false
    
    @State private var previousTopMostMessageIdentifier: String?
    
    private let timelineBottomAnchor = "TimelineBottomAnchor"
    
    @ObservedObject var context: RoomScreenViewModel.Context
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List {
                if didRequestBackPagination == false {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .onAppear {
                        guard didRequestBackPagination == false else {
                            return
                        }
                        
                        didRequestBackPagination = true
                        context.send(viewAction: .loadPreviousPage)
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                
                ForEach(messages) { message in
                    message.body
                }
                
                Color.clear
                    .listRowSeparator(.hidden)
                    .id(timelineBottomAnchor)
            }
            .listStyle(.plain)
            .navigationTitle(context.viewState.roomTitle)
            .environment(\.defaultMinListRowHeight, 0.0)
            .navigationBarTitleDisplayMode(.inline)
            // Fetch the underlying UIScrollView and start observing it
            .introspectTableView { scrollView in
                if scrollView == scrollViewObserver.scrollView {
                    return
                }
                
                scrollViewObserver = ScrollViewObserver(scrollView: scrollView)
            }
            // Scroll to the bottom when the timeline first appears
            .onAppear {
                scrollViewProxy.scrollTo(timelineBottomAnchor, anchor: .bottom)
            }
            // When the view state changes check whether the user is interacting with the scroll view.
            // Updating in that case causes undesired scrolling. Delay until the scroll view stops scrolling.
            // Also store previous top most message identifier to have something to scroll to after the update.
            .onChange(of: context.viewState.messages) { newValue in
                previousTopMostMessageIdentifier = messages.first?.id
                wasBottomVisible = scrollViewObserver.isBottomVisible
                
                if scrollViewObserver.isTracking == true {
                    hasPendingMessages = true
                    return
                }
                
                messages = newValue
            }
            // Check if we have pending messages to apply and apply them when the scroll finishes scrolling
            .onReceive(scrollViewObserver.didEndScrolling, perform: {
                if hasPendingMessages {
                    messages = context.viewState.messages
                    hasPendingMessages = false
                }
            })
            // Process timeline updates
            .onChange(of: messages, perform: { _ in
                if didRequestBackPagination && wasBottomVisible {
                    scrollViewProxy.scrollTo(timelineBottomAnchor, anchor: .bottom)
                } else if didRequestBackPagination == false {
                    if wasBottomVisible {
                        scrollViewProxy.scrollTo(timelineBottomAnchor, anchor: .bottom)
                    }
                } else {
                    // Manual scrolling breaks inertia. Don't do it if the scroll view is decelerating
                    if scrollViewObserver.isDecelerating == false {
                        scrollViewProxy.scrollTo(previousTopMostMessageIdentifier, anchor: .top)
                    }
                }
                
                didRequestBackPagination = false
            })
        }
    }
}

/// Simple wrapper around an UIScrollView that publishes when it finishes scrolling
class ScrollViewObserver: NSObject, UIScrollViewDelegate {
    private(set) var scrollView: UIScrollView?
    
    let didEndScrolling = PassthroughSubject<Void, Never>()
    
    override init() {
        
    }
    
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()
        
        scrollView.delegate = self
    }
    
    var isTracking: Bool {
        self.scrollView?.isTracking == true
    }
    
    var isDecelerating: Bool {
        self.scrollView?.isDecelerating == true
    }
    
    var isTopVisible: Bool {
        guard let scrollView = scrollView else {
            return false
        }

        return (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) <= 0.0
    }
    
    var isBottomVisible: Bool {
        guard let scrollView = scrollView else {
            return false
        }

        return (scrollView.contentOffset.y) >= (scrollView.contentSize.height - scrollView.frame.size.height)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndScrolling.send(())
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerating: Bool) {
        if decelerating == false {
            didEndScrolling.send(())
        }
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomScreenViewModel(roomProxy: MockRoomProxy(displayName: "Test"),
                                            timelineController: MockRoomTimelineController())
        RoomScreen(context: viewModel.context)
    }
}
