//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineItemMenu: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    @Environment(\.dismiss) private var dismiss
    
    @State private var reactionsFrame = CGRect.zero
    
    let item: EventBasedTimelineItemProtocol
    let actions: TimelineItemMenuActions
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        VStack(spacing: 8) {
            messagePreview
                .padding(.horizontal, 16)
                .padding(.top, 32.0)
                .padding(.bottom, 4.0)
                .frame(idealWidth: 300.0)
            
            Divider()
                .background(Color.compound.bgSubtlePrimary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    if !actions.reactions.isEmpty {
                        reactionsSection
                            .padding(.bottom, 8.0)

                        Divider()
                            .background(Color.compound.bgSubtlePrimary)
                    }

                    if !actions.actions.isEmpty {
                        viewsForActions(actions.actions)

                        Divider()
                            .background(Color.compound.bgSubtlePrimary)
                    }
                    
                    viewsForActions(actions.debugActions)
                }
            }
        }
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.timelineItemActionMenu)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.compound.bgCanvasDefault)
        .presentationDragIndicator(.visible)
    }
    
    private var messagePreview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 0.0) {
                LoadableAvatarImage(url: item.sender.avatarURL,
                                    name: item.sender.displayName,
                                    contentID: item.sender.id,
                                    avatarSize: .user(on: .timeline),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityHidden(true)
                
                Spacer(minLength: 8.0)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.sender.displayName ?? item.sender.id)
                        .font(.compound.bodySMSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .textSelection(.enabled)
                    
                    Text(item.timelineMenuDescription)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 16.0)
                
                Text(item.timestamp)
                    .font(.compound.bodyXS)
                    .foregroundColor(.compound.textSecondary)
            }
            .accessibilityElement(children: .combine)
            
            if case let .sendingFailed(.verifiedUser(failure)) = item.properties.deliveryStatus {
                Divider()
                    .padding(.horizontal, -16)
                
                VerifiedUserSendFailureView(failure: failure,
                                            members: context.viewState.members,
                                            ownUserID: context.viewState.ownUserID) {
                    send(.itemSendInfoTapped(itemID: item.id))
                }
                .padding(.bottom, 8)
            } else if let authenticity = item.properties.encryptionAuthenticity {
                Label(authenticity.message, icon: authenticity.icon, iconSize: .small, relativeTo: .compound.bodySMSemibold)
                    .font(.compound.bodySMSemibold)
                    .foregroundStyle(authenticity.foregroundStyle)
            }
        }
    }
    
    private var reactionsSection: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(actions.reactions, id: \.key) {
                    reactionButton(for: $0.key)
                }
                
                Button {
                    dismiss()
                    // Otherwise we get errors that a sheet is already presented
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        context.send(viewAction: .displayEmojiPicker(itemID: item.id))
                    }
                } label: {
                    CompoundIcon(\.reactionAdd, size: .medium, relativeTo: .compound.headingLG)
                        .foregroundColor(.compound.iconSecondary)
                        .padding(10)
                }
                .accessibilityLabel(L10n.actionReact)
            }
            .padding(.horizontal)
            .frame(minWidth: reactionsFrame.width, maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .readFrame($reactionsFrame)
    }
    
    private func reactionButton(for emoji: String) -> some View {
        Button {
            feedbackGenerator.impactOccurred()
            dismiss()
            context.send(viewAction: .toggleReaction(key: emoji, itemID: item.id))
        } label: {
            Text(emoji)
                .font(.compound.headingLG)
                .padding(8)
                .background(Circle()
                    .foregroundColor(reactionBackgroundColor(for: emoji)))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func reactionBackgroundColor(for emoji: String) -> Color {
        if let reaction = item.properties.reactions.first(where: { $0.key == emoji }),
           reaction.isHighlighted {
            return .compound.bgActionPrimaryRest
        } else {
            return .clear
        }
    }
    
    private func viewsForActions(_ actions: [TimelineItemMenuAction]) -> some View {
        ForEach(actions, id: \.self) { action in
            Button(role: action.isDestructive ? .destructive : nil) {
                send(action)
            } label: {
                action.label
                    .labelStyle(.menuSheet)
            }
        }
    }
    
    private func send(_ action: TimelineItemMenuAction) {
        send(.handleTimelineItemMenuAction(itemID: item.id, action: action))
    }
    
    private func send(_ action: TimelineViewAction) {
        dismiss()
        // Otherwise we might get errors that a sheet is already presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.send(viewAction: action)
        }
    }
}

private struct VerifiedUserSendFailureView: View {
    let failure: TimelineItemSendFailure.VerifiedUser
    let action: () -> Void
    
    private let memberDisplayName: String
    private let isYou: Bool
    
    init(failure: TimelineItemSendFailure.VerifiedUser,
         members: [String: RoomMemberState],
         ownUserID: String,
         action: @escaping () -> Void) {
        self.failure = failure
        self.action = action
        
        let userIDs = failure.affectedUserIDs
        memberDisplayName = userIDs.first.map { members[$0]?.displayName ?? $0 } ?? ""
        isYou = ownUserID == userIDs.first
    }
    
    var title: String {
        switch failure {
        case .hasUnsignedDevice:
            isYou ? L10n.screenTimelineItemMenuSendFailureYouUnsignedDevice : L10n.screenTimelineItemMenuSendFailureUnsignedDevice(memberDisplayName)
        case .changedIdentity:
            L10n.screenTimelineItemMenuSendFailureChangedIdentity(memberDisplayName)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Label(title, icon: \.error, iconSize: .small, relativeTo: .compound.bodySMSemibold)
                    .font(.compound.bodySMSemibold)
                    .foregroundStyle(.compound.textCriticalPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ListRowAccessory.navigationLink
            }
        }
    }
}

private extension EncryptionAuthenticity {
    var foregroundStyle: SwiftUI.Color {
        switch color {
        case .red: .compound.textCriticalPrimary
        case .gray: .compound.textSecondary
        }
    }
}

// MARK: - Previews

struct TimelineItemMenu_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let (item, actions) = makeItem()
    static let (backupItem, _) = makeItem(authenticity: .notGuaranteed(color: .gray))
    static let (unsignedItem, _) = makeItem(authenticity: .unsignedDevice(color: .red))
    static let (unencryptedItem, _) = makeItem(authenticity: .sentInClear(color: .red))
    static let (unknownFailureItem, _) = makeItem(deliveryStatus: .sendingFailed(.unknown))
    static let (identityChangedItem, _) = makeItem(deliveryStatus: .sendingFailed(.verifiedUser(.changedIdentity(users: [
        "@alice:matrix.org"
    ]))))
    static let (unsignedDevicesItem, _) = makeItem(deliveryStatus: .sendingFailed(.verifiedUser(.hasUnsignedDevice(devices: [
        "@alice:matrix.org": ["DEVICE1", "DEVICE2"]
    ]))))
    static let (ownUnsignedDevicesItem, _) = makeItem(deliveryStatus: .sendingFailed(.verifiedUser(.hasUnsignedDevice(devices: [
        RoomMemberProxyMock.mockMe.userID: ["DEVICE1"]
    ]))))

    static var previews: some View {
        TimelineItemMenu(item: item, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Normal")
        
        TimelineItemMenu(item: item, actions: actions)
            .environmentObject(viewModel.context)
            .environment(\._accessibilityShowButtonShapes, true)
            .previewDisplayName("Button shapes")
        
        TimelineItemMenu(item: backupItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Authenticity")
        
        TimelineItemMenu(item: unsignedItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Unsigned")
        
        TimelineItemMenu(item: unencryptedItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Unencrypted")
        
        TimelineItemMenu(item: unknownFailureItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Unknown failure")
        
        TimelineItemMenu(item: unsignedDevicesItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Unsigned Devices")
        
        TimelineItemMenu(item: ownUnsignedDevicesItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Own Unsigned Devices")
        
        TimelineItemMenu(item: identityChangedItem, actions: actions)
            .environmentObject(viewModel.context)
            .previewDisplayName("Identity Changed")
    }
    
    static func makeItem(authenticity: EncryptionAuthenticity? = nil,
                         deliveryStatus: TimelineItemDeliveryStatus? = nil) -> (TextRoomTimelineItem, TimelineItemMenuActions)! {
        guard var item = RoomTimelineItemFixtures.singleMessageChunk.first as? TextRoomTimelineItem,
              let actions = TimelineItemMenuActions(isReactable: true,
                                                    actions: [.copy, .edit, .reply(isThread: false), .pin, .redact],
                                                    debugActions: [.viewSource]) else {
            return nil
        }
        
        if let authenticity {
            item.properties.encryptionAuthenticity = authenticity
        }
        
        if let deliveryStatus {
            item.properties.deliveryStatus = deliveryStatus
        }
        
        return (item, actions)
    }
}
