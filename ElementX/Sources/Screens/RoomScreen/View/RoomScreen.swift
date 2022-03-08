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

struct RoomScreen: View {
    
    let timelineBottomDividerIdentifier = "TimelineBottomDividerIdentifier"
    
    @ObservedObject var context: RoomScreenViewModel.Context
    @State var backPaginationMessageIdentifier: String?
    
    var body: some View {
        ScrollViewReader { reader in
            List {
                if backPaginationMessageIdentifier != nil {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    Rectangle()
                        .onAppear {
                            let _ = MXLog.debug("Request load previous page")
                            backPaginationMessageIdentifier = context.viewState.messages.first?.id
                            context.send(viewAction: .loadPreviousPage)
                        }
                        .frame(height: 0.0)
                }
                ForEach(context.viewState.messages) { message in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(message.sender)
                            Spacer()
                            Text(message.timestamp)
                        }
                        .font(.footnote)
                        Text(message.text)
                    }
                    .listRowSeparator(.hidden)
                }
                
                Divider()
                    .id(timelineBottomDividerIdentifier)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .onAppear {
                reader.scrollTo(timelineBottomDividerIdentifier, anchor: .bottom)
            }
            .onChange(of: context.viewState.messages) { _ in
                if backPaginationMessageIdentifier != nil {
                    self.backPaginationMessageIdentifier = nil
                    return
                }
                
                reader.scrollTo(timelineBottomDividerIdentifier, anchor: .bottom)
            }
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
