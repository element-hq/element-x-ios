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

import SwiftUI

struct TypingIndicatorView: View {
    @ObservedObject var typingMembers: TypingMembersObservableObject
    @State private var didShowTextOnce = false
    
    var body: some View {
        content
            .font(.compound.bodySM)
            .foregroundColor(.compound.textPlaceholder)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 4)
            .animation(.elementDefault, value: typingMembers.members)
            .onChange(of: typingMembers.members) { newValue in
                if !newValue.isEmpty {
                    didShowTextOnce = true
                }
            }
    }
    
    @ViewBuilder
    var content: some View {
        // Plurals with string arguments aren't generated correctly by so we need to work around that
        // https://github.com/SwiftGen/SwiftGen/issues/1089
        
        switch typingMembers.members.count {
        case 1:
            let firstMember = typingMembers.members[0]
            
            Text(firstMember).bold() +
                Text(L10n.screenRoomTypingNotificationSingularIos)
        case 2:
            let firstMember = typingMembers.members[0]
            let lastMember = typingMembers.members[1]
            
            Text(L10n.screenRoomTypingTwoMembers(firstMember, lastMember)).bold() +
                Text(L10n.screenRoomTypingNotificationPluralIos)
        case 3...:
            let firstMember = typingMembers.members[0]
            let lastMember = typingMembers.members[1]
            
            Text(L10n.tr("Localizable", "screen_room_typing_many_members_first_component_ios", firstMember, lastMember)).bold() +
                Text(L10n.tr("Localizable", "screen_room_typing_many_members_second_component_ios", typingMembers.members.count - 2)).bold() +
                Text(L10n.screenRoomTypingNotificationPluralIos)
        default:
            if didShowTextOnce {
                Text(L10n.screenRoomTypingNotificationSingularIos)
                    .opacity(0)
            } else {
                EmptyView()
            }
        }
    }
}

struct TypingIndicatorView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            TypingIndicatorView(typingMembers: TypingMembersObservableObject(members: ["Alice"]))
            TypingIndicatorView(typingMembers: TypingMembersObservableObject(members: ["Alice", "Bob"]))
            TypingIndicatorView(typingMembers: TypingMembersObservableObject(members: ["Alice", "Bob", "Charlie"]))
            TypingIndicatorView(typingMembers: TypingMembersObservableObject(members: ["Alice", "Bob", "Charlie", "Dan"]))
            TypingIndicatorView(typingMembers: TypingMembersObservableObject(members: ["Alice", "Bob", "Charlie", "Dan", "Frannie"]))
            TypingIndicatorView(typingMembers: TypingMembersObservableObject(members: ["Alice with her very long display name", "Bob", "Charlie", "Dan", "Frannie"]))
        }
        .frame(width: 300)
    }
}
