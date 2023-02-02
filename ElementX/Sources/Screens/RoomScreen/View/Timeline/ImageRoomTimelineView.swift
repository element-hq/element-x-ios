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

struct ImageRoomTimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    let timelineItem: ImageRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            LoadableImage(mediaSource: timelineItem.source,
                          blurhash: timelineItem.blurhash,
                          imageProvider: context.imageProvider) { image in
                image.overlay { overlay }
            } placeholder: {
                placeholder
            }
            .frame(maxHeight: 300)
            .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
        }
    }
    
    var placeholder: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.element.systemGray6)
                .opacity(0.3)
            
            ProgressView(ElementL10n.loading)
                .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    var overlay: some View {
        if timelineItem.type == .gif {
            Text(ElementL10n.roomTimelineImageGif)
                .font(.element.bodyBold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.thinMaterial)
                .cornerRadius(8)
                .environment(\.colorScheme, .dark)
        }
    }
}

struct ImageRoomTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        body.timelineStyle(.plain).environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 20.0) {
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Some image",
                                                                      timestamp: "Now",
                                                                      groupState: .single,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      source: nil))

            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Some other image",
                                                                      timestamp: "Now",
                                                                      groupState: .single,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      source: nil))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Blurhashed image",
                                                                      timestamp: "Now",
                                                                      groupState: .single,
                                                                      isOutgoing: false,
                                                                      isEditable: false,
                                                                      sender: .init(id: "Bob"),
                                                                      source: nil,
                                                                      aspectRatio: 0.7,
                                                                      blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW",
                                                                      type: .gif))
        }
    }
}
