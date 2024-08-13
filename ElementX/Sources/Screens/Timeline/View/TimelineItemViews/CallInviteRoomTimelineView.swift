//
// Copyright 2024 New Vector Ltd
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

import Compound
import Foundation
import SwiftUI

struct CallInviteRoomTimelineView: View {
    let timelineItem: CallInviteRoomTimelineItem
    
    var body: some View {
        Label(title: { Text(L10n.commonCallInvite) },
              icon: { CompoundIcon(\.voiceCall, size: .medium, relativeTo: .compound.bodyMD) })
            .font(.compound.bodyMD)
            .foregroundColor(.compound.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

struct CallInviteRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        CallInviteRoomTimelineView(timelineItem: .init(id: .random,
                                                       timestamp: "Now",
                                                       isEditable: false,
                                                       canBeRepliedTo: false,
                                                       sender: .init(id: "Bob")))
    }
}
