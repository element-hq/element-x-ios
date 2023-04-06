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

struct SelectableUserCell: View {
    let user: UserProfile
    let selected: Bool
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
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(selected ? .element.primaryContent : .element.tertiaryContent)
        }
    }
}

struct SelectableUserCell_Previews: PreviewProvider {
    static var previews: some View {
        SelectableUserCell(user: .mockAlice, selected: false, imageProvider: MockMediaProvider())
    }
}
