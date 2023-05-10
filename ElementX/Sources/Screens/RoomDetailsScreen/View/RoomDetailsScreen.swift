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
    @ObservedObject var context: RoomDetailsScreenViewModel.Context
    
    var body: some View {
        Form {
            if let recipient = context.viewState.dmRecipient {
                dmHeaderSection(recipient: recipient)
            } else {
                normalRoomHeaderSection
            }

            topicSection

            if context.viewState.dmRecipient == nil {
                aboutSection
            }

            securitySection

            if let recipient = context.viewState.dmRecipient {
                ignoreUserSection(user: recipient)
            } else {
                leaveRoomSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .alert(item: $context.alertInfo) { $0.alert }
        .alert(item: $context.leaveRoomAlertItem,
               actions: leaveRoomAlertActions,
               message: leaveRoomAlertMessage)
        .alert(item: $context.ignoreUserRoomAlertItem,
               actions: blockUserAlertActions,
               message: blockUserAlertMessage)
    }
    
    // MARK: - Private

    @ViewBuilder
    private var normalRoomHeaderSection: some View {
        AvatarHeaderView(avatarUrl: context.viewState.avatarURL,
                         name: context.viewState.title,
                         id: context.viewState.roomId,
                         avatarSize: .room(on: .details),
                         imageProvider: context.imageProvider,
                         subtitle: context.viewState.canonicalAlias) {
            if let permalink = context.viewState.permalink {
                HStack(spacing: 32) {
                    ShareLink(item: permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
                }
                .padding(.top, 32)
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.avatar)
    }

    @ViewBuilder
    private func dmHeaderSection(recipient: RoomMemberDetails) -> some View {
        AvatarHeaderView(avatarUrl: recipient.avatarURL,
                         name: recipient.name,
                         id: recipient.id,
                         avatarSize: .user(on: .memberDetails),
                         imageProvider: context.imageProvider,
                         subtitle: recipient.id) {
            if let permalink = recipient.permalink {
                HStack(spacing: 32) {
                    ShareLink(item: permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
                }
                .padding(.top, 32)
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.dmAvatar)
    }
    
    @ViewBuilder
    private var topicSection: some View {
        if let topic = context.viewState.topic {
            Section {
                Text(topic)
                    .foregroundColor(.element.secondaryContent)
                    .font(.compound.bodySM)
            } header: {
                Text(L10n.commonTopic)
                    .formSectionHeader()
            }
            .formSectionStyle()
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                context.send(viewAction: .processTapPeople)
            } label: {
                LabeledContent {
                    if context.viewState.isLoadingMembers {
                        ProgressView()
                    } else {
                        Text(String(context.viewState.joinedMembersCount))
                            .foregroundColor(.element.tertiaryContent)
                            .font(.compound.bodyLG)
                    }
                } label: {
                    Label(L10n.commonPeople, systemImage: "person")
                }
            }
            .buttonStyle(FormButtonStyle(accessory: context.viewState.isLoadingMembers ? nil : .navigationLink))
            .foregroundColor(.element.primaryContent)
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.people)
            .disabled(context.viewState.isLoadingMembers)
        }
        .formSectionStyle()
    }

    @ViewBuilder
    private var securitySection: some View {
        if context.viewState.isEncrypted {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.screenRoomDetailsEncryptionEnabledTitle)
                        Text(L10n.screenRoomDetailsEncryptionEnabledSubtitle)
                            .foregroundColor(.element.secondaryContent)
                            .font(.compound.bodySM)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                }
                .labelStyle(FormRowLabelStyle(alignment: .top))
            } header: {
                Text(L10n.commonSecurity)
                    .formSectionHeader()
            }
            .formSectionStyle()
        }
    }

    private var leaveRoomSection: some View {
        Section {
            Button(role: .destructive) {
                context.send(viewAction: .processTapLeave)
            } label: {
                Label(L10n.actionLeaveRoom, systemImage: "door.right.hand.open")
            }
            .buttonStyle(FormButtonStyle(accessory: nil))
        }
        .formSectionStyle()
    }

    @ViewBuilder
    private func ignoreUserSection(user: RoomMemberDetails) -> some View {
        Section {
            Button(role: user.isIgnored ? nil : .destructive) {
                context.send(viewAction: user.isIgnored ? .processTapUnignore : .processTapIgnore)
            } label: {
                Label(user.isIgnored ? L10n.screenDmDetailsUnblockUser : L10n.screenDmDetailsBlockUser,
                      systemImage: "slash.circle")
            }
            .buttonStyle(FormButtonStyle(accessory: context.viewState.isProcessingIgnoreRequest ? .progressView : nil))
            .disabled(context.viewState.isProcessingIgnoreRequest)
        }
        .formSectionStyle()
    }

    @ViewBuilder
    private func leaveRoomAlertActions(_ item: LeaveRoomAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle, role: .destructive) {
            context.send(viewAction: .confirmLeave)
        }
    }

    private func leaveRoomAlertMessage(_ item: LeaveRoomAlertItem) -> some View {
        Text(item.subtitle)
    }

    @ViewBuilder
    private func blockUserAlertActions(_ item: RoomDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle,
               role: item.action == .ignore ? .destructive : nil) {
            context.send(viewAction: item.viewAction)
        }
    }

    private func blockUserAlertMessage(_ item: RoomDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Text(item.description)
    }
}

// MARK: - Previews

struct RoomDetailsScreen_Previews: PreviewProvider {
    static let genericRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let roomProxy = RoomProxyMock(with: .init(displayName: "Room A",
                                                  topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                                  isDirect: false,
                                                  isEncrypted: true,
                                                  canonicalAlias: "#alias:domain.com",
                                                  members: members))
        
        return RoomDetailsScreenViewModel(roomProxy: roomProxy,
                                          mediaProvider: MockMediaProvider())
    }()
    
    static let dmRoomViewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockMe,
            .mockDan
        ]
        
        let roomProxy = RoomProxyMock(with: .init(displayName: "DM Room",
                                                  topic: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                                                  isDirect: true,
                                                  isEncrypted: true,
                                                  canonicalAlias: "#alias:domain.com",
                                                  members: members))
        
        return RoomDetailsScreenViewModel(roomProxy: roomProxy,
                                          mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        RoomDetailsScreen(context: genericRoomViewModel.context)
            .previewDisplayName("Generic Room")
        RoomDetailsScreen(context: dmRoomViewModel.context)
            .previewDisplayName("DM Room")
    }
}
