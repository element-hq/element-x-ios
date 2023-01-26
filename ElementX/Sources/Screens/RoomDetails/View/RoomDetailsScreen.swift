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

import SwiftUI

struct RoomDetailsScreen: View {
    @ScaledMetric private var menuIconSize = 30.0
    private let listRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

    @ObservedObject var context: RoomDetailsViewModel.Context
    
    var body: some View {
        Form {
            headerSection

            if let topic = context.viewState.topic {
                topicSection(with: topic)
            }

            aboutSection

            if context.viewState.isEncrypted {
                securitySection
            }
        }
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    // MARK: - Private

    private var headerSection: some View {
        VStack(spacing: 8.0) {
            LoadableAvatarImage(url: context.viewState.avatarURL,
                                name: context.viewState.title,
                                contentID: context.viewState.roomId,
                                avatarSize: .room(on: .details),
                                imageProvider: context.imageProvider)
                .accessibilityIdentifier("roomAvatarImage")

            Text(context.viewState.title)
                .foregroundColor(.element.primaryContent)
                .font(.element.title1Bold)
                .multilineTextAlignment(.center)
            
            if let canonicalAlias = context.viewState.canonicalAlias {
                Text(canonicalAlias)
                    .foregroundColor(.element.secondaryContent)
                    .font(.element.body)
                    .multilineTextAlignment(.center)
            }

            // TODO: uncomment this code to display copy link and invite buttons
//            HStack(spacing: 32) {
//                SettingsActionButton(title: ElementL10n.roomDetailsCopyLink, image: Image(systemName: "link")) {
//                    context.send(viewAction: .copyRoomLink)
//                }
//                SettingsActionButton(title: ElementL10n.inviteUsersToRoomActionInvite.capitalized, image: Image(systemName: "square.and.arrow.up")) {
//                    context.send(viewAction: .inviteToRoom)
//                }
//            }
//            .padding(.top, 32)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }
    
    private func topicSection(with topic: String) -> some View {
        Section(header: Text(ElementL10n.roomSettingsTopic)
            .formSectionHeader()) {
                Text(topic)
                    .foregroundColor(.element.secondaryContent)
                    .font(.element.footnote)
            }
    }

    private var aboutSection: some View {
        Section(header: Text(ElementL10n.roomDetailsAboutSectionTitle)
            .formSectionHeader()) {
                Button {
                    context.send(viewAction: .processTapPeople)
                } label: {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.element.secondaryContent)
                            .padding(4)
                            .background(Color.element.system)
                            .clipShape(RoundedCornerShape(radius: 8, corners: .allCorners))
                            .frame(width: menuIconSize, height: menuIconSize)
                    
                        Text(ElementL10n.bottomActionPeople)
                            .foregroundColor(.element.primaryContent)
                            .font(.body)
                    
                        Spacer()
                    
                        if context.viewState.isLoadingMembers {
                            ProgressView()
                        } else {
                            Text(String(context.viewState.members.count))
                                .foregroundColor(.element.secondaryContent)
                                .font(.element.body)
                            Image(systemName: "chevron.forward")
                                .foregroundColor(.element.quaternaryContent)
                        }
                    }
                }
                .listRowInsets(listRowInsets)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("peopleButton")
                .disabled(context.viewState.isLoadingMembers)
            }
    }
    
    private var securitySection: some View {
        Section(header: Text(ElementL10n.roomProfileSectionSecurity)
            .formSectionHeader()) {
                HStack(alignment: .top) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.element.secondaryContent)
                        .padding(4)
                        .background(Color.element.system)
                        .clipShape(RoundedCornerShape(radius: 8, corners: .allCorners))
                        .frame(width: menuIconSize, height: menuIconSize)
                
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ElementL10n.encryptionEnabled)
                            .foregroundColor(.element.primaryContent)
                            .font(.element.body)
                    
                        Text(ElementL10n.encryptionEnabledTileDescription)
                            .foregroundColor(.element.secondaryContent)
                            .font(.element.footnote)
                    }
                
                    Spacer()
                
                    Image(systemName: "checkmark")
                        .foregroundColor(.element.quaternaryContent)
                }
                .padding(.horizontal, -3)
            }
    }
}

// MARK: - Previews

struct RoomDetails_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let members: [RoomMemberProxy] = [
                .mockAlice,
                .mockBob,
                .mockCharlie
            ]
            let roomProxy = MockRoomProxy(displayName: "Room A",
                                          topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                          isDirect: false,
                                          isEncrypted: true,
                                          canonicalAlias: "#alias:domain.com",
                                          members: members)
            let viewModel = RoomDetailsViewModel(roomProxy: roomProxy,
                                                 mediaProvider: MockMediaProvider())
            RoomDetailsScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
