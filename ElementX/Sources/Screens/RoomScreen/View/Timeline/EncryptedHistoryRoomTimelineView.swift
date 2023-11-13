//
// Copyright 2023 New Vector Ltd
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
import SwiftUI

/// The item shown when all previous items are un-decryptable due to
/// key backup not yet being supported in the app.
struct EncryptedHistoryRoomTimelineView: View {
    let timelineItem: EncryptedHistoryRoomTimelineItem
    
    var body: some View {
        Label {
            Text(title)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textInfoPrimary)
        } icon: {
            CompoundIcon(\.infoSolid, size: .small, relativeTo: .compound.bodyMDSemibold)
                .foregroundColor(.compound.iconInfoPrimary)
        }
        .labelStyle(EncryptedHistoryLabelStyle())
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.compound.bgInfoSubtle)
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.compound.borderInfoSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
    }
    
    private var title: String {
        timelineItem.isSessionVerified ? L10n.screenRoomEncryptedHistoryBanner : L10n.screenRoomEncryptedHistoryBannerUnverified
    }
}

private struct EncryptedHistoryLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 16) {
            configuration.icon
            configuration.title
        }
    }
}

struct EncryptedHistoryRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
            EncryptedHistoryRoomTimelineView(timelineItem: .init(id: .random, isSessionVerified: true))
            EncryptedHistoryRoomTimelineView(timelineItem: .init(id: .random, isSessionVerified: false))
        }
    }
}
