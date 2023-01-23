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
    @Environment(\.colorScheme) private var colorScheme
    
    @ScaledMetric private var avatarSize = AvatarSize.room(on: .details).value
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
        .navigationTitle(ElementL10n.roomDetailsTitle)
    }
    
    // MARK: - Private

    private var headerSection: some View {
        VStack(spacing: 16.0) {
            avatarImageView
            Text(context.viewState.title)
                .foregroundColor(.element.primaryContent)
                .font(.element.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
        .padding(.top, 18)
        .padding(.bottom, 42)
    }

    private func topicSection(with topic: String) -> some View {
        Section(ElementL10n.roomSettingsTopic) {
            Text(topic)
                .foregroundColor(.element.secondaryContent)
                .font(.element.footnote)
        }
    }

    private var aboutSection: some View {
        Section(ElementL10n.roomDetailsAboutSectionTitle) {
            Button {
                context.send(viewAction: .processTapPeople)
            } label: {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.element.systemGray)
                        .padding(4)
                        .background(Color.element.systemGray6)
                        .clipShape(Circle())
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
                            .foregroundColor(.element.secondaryContent)
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
        Section(ElementL10n.roomProfileSectionSecurity) {
            HStack(alignment: .center) {
                Image(systemName: "lock.shield")
                    .foregroundColor(.element.systemGray)
                    .padding(4)
                    .background(Color.element.systemGray6)
                    .clipShape(Circle())
                    .frame(width: menuIconSize, height: menuIconSize)
                VStack(alignment: .leading) {
                    Text(ElementL10n.encryptionEnabled)
                        .foregroundColor(.element.primaryContent)
                        .font(.element.body)
                    Text(ElementL10n.encryptionEnabledTileDescription)
                        .foregroundColor(.element.secondaryContent)
                        .font(.element.footnote)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.element.secondaryContent)
            }
        }
    }

    @ViewBuilder private var avatarImageView: some View {
        LoadableImage(imageProvider: context.imageProvider,
                      url: context.viewState.avatarURL,
                      avatarSize: .room(on: .details)) { image in
            image
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .accessibilityIdentifier("roomAvatarImage")
        } placeholder: {
            PlaceholderAvatarImage(text: context.viewState.title,
                                   contentId: context.viewState.roomId)
                .clipShape(Circle())
                .frame(width: avatarSize, height: avatarSize)
                .accessibilityIdentifier("roomAvatarPlaceholderImage")
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
                                          members: members)
            let viewModel = RoomDetailsViewModel(roomProxy: roomProxy,
                                                 mediaProvider: MockMediaProvider())
            RoomDetailsScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
