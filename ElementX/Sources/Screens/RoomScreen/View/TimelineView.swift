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
    @ObservedObject private var settings = ElementSettings.shared
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    
    var body: some View {
        TimelineTableView()
            .timelineStyle(settings.timelineStyle)
            .overlay(alignment: .bottomTrailing) { scrollToBottomButton }
    }
    
    private var scrollToBottomButton: some View {
        Button { context.viewState.scrollToBottomPublisher.send(()) } label: {
            Image(uiImage: Asset.Images.timelineScrollToBottom.image)
                .shadow(radius: 2.0)
                .padding()
        }
        .opacity(context.scrollToBottomButtonVisible ? 1.0 : 0.0)
        .animation(.elementDefault, value: context.scrollToBottomButtonVisible)
    }
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: nil)
        
        TimelineView()
            .environmentObject(viewModel.context)
    }
}
