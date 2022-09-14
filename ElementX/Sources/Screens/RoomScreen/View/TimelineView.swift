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
import Foundation
import SwiftUI

import Introspect

struct TimelineView: View {
    @State private var bottomVisiblePublisher = PassthroughSubject<Bool, Never>()
    @State private var scrollToBottomPublisher = PassthroughSubject<Void, Never>()
    @State private var scollToBottomButtonVisible = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TimelineItemList(bottomVisiblePublisher: bottomVisiblePublisher, scrollToBottomPublisher: scrollToBottomPublisher)
            scrollToBottomButton
        }
    }
    
    @ViewBuilder
    private var scrollToBottomButton: some View {
        Button(action: {
            scrollToBottomPublisher.send(())
        }, label: {
            Image(uiImage: Asset.Images.timelineScrollToBottom.image)
                .shadow(radius: 2.0)
                .padding()
        })
        .onReceive(bottomVisiblePublisher, perform: { visible in
            scollToBottomButtonVisible = !visible
        })
        .opacity(scollToBottomButtonVisible ? 1.0 : 0.0)
        .animation(.elementDefault, value: scollToBottomButtonVisible)
    }
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            roomName: nil)
        
        TimelineView()
            .environmentObject(viewModel.context)
    }
}
