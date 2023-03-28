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

import Foundation
import SwiftUI

struct VideoRoomTimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    let timelineItem: VideoRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            LoadableImage(mediaSource: timelineItem.thumbnailSource,
                          blurhash: timelineItem.blurhash,
                          imageProvider: context.imageProvider) { imageView in
                imageView
                    .overlay { playIcon }
            } placeholder: {
                placeholder
            }
            .frame(maxHeight: 300)
            .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
        }
    }
    
    var playIcon: some View {
        Image(systemName: "play.circle.fill")
            .resizable()
            .frame(width: 50, height: 50)
            .background(.ultraThinMaterial, in: Circle())
            .foregroundColor(.white)
    }
    
    var placeholder: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.element.systemGray6)
                .opacity(0.3)
            
            ProgressView(L10n.commonLoading)
                .frame(maxWidth: .infinity)
        }
    }
}

struct VideoRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        body.timelineStyle(.plain).environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: UUID().uuidString,
                                                                      body: "Some video",
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      duration: 21,
                                                                      source: nil,
                                                                      thumbnailSource: nil))

            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: UUID().uuidString,
                                                                      body: "Some other video",
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      duration: 22,
                                                                      source: nil,
                                                                      thumbnailSource: nil))
            
            VideoRoomTimelineView(timelineItem: VideoRoomTimelineItem(id: UUID().uuidString,
                                                                      body: "Blurhashed video",
                                                                      timestamp: "Now",
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      duration: 23,
                                                                      source: nil,
                                                                      thumbnailSource: nil,
                                                                      aspectRatio: 0.7,
                                                                      blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
        }
    }
}
