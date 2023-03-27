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
    @ObservedObject var context: RoomDetailsViewModel.Context
    
    var body: some View {
        Form {
            headerSection
            
            topicSection
            
            aboutSection
            
            if context.viewState.isEncrypted {
                securitySection
            }

            leaveRoomSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .alert(item: $context.alertInfo) { $0.alert }
        .alert(item: $context.leaveRoomAlertItem,
               actions: leaveRoomAlertActions,
               message: leaveRoomAlertMessage)
    }
    
    // MARK: - Private

    private var headerSection: some View {
        VStack(spacing: 8.0) {
            LoadableAvatarImage(url: context.viewState.avatarURL,
                                name: context.viewState.title,
                                contentID: context.viewState.roomId,
                                avatarSize: .room(on: .details),
                                imageProvider: context.imageProvider)
                .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.avatar)

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
            
            if let permalink = context.viewState.permalink {
                HStack(spacing: 32) {
                    Button { context.send(viewAction: .copyRoomLink) } label: {
                        Image(systemName: "link")
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionCopyLink))
                    
                    ShareLink(item: permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionInvite))
                }
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private var topicSection: some View {
        if let topic = context.viewState.topic {
            Section {
                Text(topic)
                    .foregroundColor(.element.secondaryContent)
                    .font(.element.footnote)
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
                        Text(String(context.viewState.members.count))
                            .foregroundColor(.element.tertiaryContent)
                            .font(.element.body)
                    }
                } label: {
                    Label(L10n.commonPeople, systemImage: "person")
                }
            }
            .buttonStyle(FormButtonStyle(accessory: context.viewState.isLoadingMembers ? nil : .navigationLink))
            .foregroundColor(.element.primaryContent)
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.people)
            .disabled(context.viewState.isLoadingMembers)
        } header: {
            Text(L10n.commonAbout)
                .formSectionHeader()
        }
        .formSectionStyle()
    }
    
    private var securitySection: some View {
        Section {
            HStack(alignment: .top) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.screenRoomDetailsEncryptionEnabledTitle)
                        Text(L10n.screenRoomDetailsEncryptionEnabledSubtitle)
                            .foregroundColor(.element.secondaryContent)
                            .font(.element.footnote)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                }
                .labelStyle(FormRowLabelStyle(alignment: .top))
                
                Spacer()
                
                Image(systemName: "checkmark")
                    .foregroundColor(.element.quaternaryContent)
            }
        } header: {
            Text(L10n.commonSecurity)
                .formSectionHeader()
        }
        .formSectionStyle()
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
    private func leaveRoomAlertActions(_ item: LeaveRoomAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle, role: .destructive) {
            context.send(viewAction: .confirmLeave)
        }
    }

    private func leaveRoomAlertMessage(_ item: LeaveRoomAlertItem) -> some View {
        Text(item.subtitle)
    }
}

// MARK: - Previews

struct RoomDetails_Previews: PreviewProvider {
    static let viewModel = {
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
        
        return RoomDetailsViewModel(roomProxy: roomProxy,
                                    mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        RoomDetailsScreen(context: viewModel.context)
    }
}
