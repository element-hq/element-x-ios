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

import SwiftUI

struct StartChatSuggestedUserCell: View {
    let user: UserProfile
    let imageProvider: ImageProviderProtocol?
    
    var body: some View {
        HStack(spacing: 16) {
            LoadableAvatarImage(url: user.avatarURL,
                                name: user.displayName,
                                contentID: user.userID,
                                avatarSize: .user(on: .startChat),
                                imageProvider: imageProvider)
                .padding(.vertical, 10)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName ?? user.userID)
                    .font(.element.title3)
                    .foregroundColor(.element.primaryContent)
                
                if user.displayName != nil {
                    Text(user.userID)
                        .font(.element.subheadline)
                        .foregroundColor(.element.tertiaryContent)
                }
                
                if !user.isVerified {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Image(systemName: "exclamationmark.circle"))
                            .foregroundColor(.compound.textActionCritical)
                        
                        Text(L10n.screenStartChatUnknownProfile)
                            .foregroundColor(.secondary)
                    }
                    .font(.compound.bodyXS)
                    .padding(.top, 4)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private extension UserProfile {
    /// A user is meant to be "verified" when the GET profile returns back either the display name or the avatar
    /// If isn't we aren't sure that the related matrix id really exists.
    var isVerified: Bool {
        displayName != nil || avatarURL != nil
    }
}
