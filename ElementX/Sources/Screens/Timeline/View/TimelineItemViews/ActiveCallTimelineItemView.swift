//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI

/// A reusable view component for rendering active call notifications.
/// This view displays information about an ongoing call including participants, duration, and a join button.
struct ActiveCallTimelineItemView: View {
    @Environment(\.timelineContext) private var context
    
    let isDM: Bool
    let isVoiceCall: Bool
    let activeMembers: [String]
    let sender: TimelineItemSender
    let isJoined: Bool
    let callStartTimestamp: Date?
    
    static let maxAvatars = 3
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var avatars: [StackedAvatarInfo] {
        activeMembers
            .prefix(ActiveCallTimelineItemView.maxAvatars)
            .map { userID in
                StackedAvatarInfo(url: context?.viewState.members[userID]?.avatarURL,
                                  name: context?.viewState.members[userID]?.displayName,
                                  contentID: userID)
            }
    }
    
    private var elapsedTimeText: String {
        guard let startTime = callStartTimestamp else {
            return ""
        }
        
        let elapsed = currentTime.timeIntervalSince(startTime)
        
        // Protect against invalid dates (future, NaN, infinity)
        guard !elapsed.isNaN, elapsed.isFinite, elapsed >= 0 else {
            return ""
        }
        
        return Duration.seconds(elapsed).formatted(.time(pattern: .minuteSecond))
    }
    
    private var extraGroupLabel: String {
        if activeMembers.count == 1, activeMembers.first == sender.id {
            return L10n.commonUserStartedACall(sender.displayName ?? sender.id)
        } else {
            return L10n.screenTimelineActiveCallJoinedCount(activeMembers.count)
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            CompoundIcon(isVoiceCall ? \.voiceCallSolid : \.videoCallSolid, size: .medium,
                         relativeTo: .compound.headingMDBold)
                .padding(8)
                .background(.compound.bgSubtleSecondary, in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.compound.iconPrimary)
                .accessibilityHidden(true)
            
            if isDM {
                HStack(alignment: .center, spacing: 4) {
                    StackedAvatarsView(overlap: 6,
                                       lineWidth: 1,
                                       avatars: avatars,
                                       avatarSize: .user(on: .readReceipt),
                                       mediaProvider: context?.mediaProvider)
                        .padding(-1)
                    
                    let text = if activeMembers.count == 1,
                                  activeMembers.first == sender.id {
                        L10n.commonUserStartedACall(sender.displayName ?? sender.id)
                    } else {
                        L10n.commonCallInProgress
                    }
                    Text(text)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .labelStyle(.custom(spacing: 4))
                }
                
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.commonGroupCallInProgress)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .labelStyle(.custom(spacing: 4))
                    
                    HStack(alignment: .center, spacing: 4) {
                        StackedAvatarsView(overlap: 6,
                                           lineWidth: 1,
                                           avatars: avatars,
                                           avatarSize: .user(on: .readReceipt),
                                           mediaProvider: context?.mediaProvider)
                            .padding(-1)
                        
                        Text(extraGroupLabel)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .labelStyle(.custom(spacing: 4))
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                if !isJoined {
                    Button(action: { context?.send(viewAction: .joinActiveCall(isVoiceCall: isVoiceCall)) }) {
                        Text(L10n.actionJoin)
                            .font(.compound.bodyMDSemibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.compound(.primary, size: .small))
                }
                
                if callStartTimestamp != nil {
                    Text(elapsedTimeText)
                        .font(.compound.bodyXS)
                        .foregroundColor(.compound.textSecondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(.compound.borderInteractivePrimary, lineWidth: 1))
        .padding(16)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Previews

struct ActiveCallTimelineItemView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static let twoMembers = [
        "@alice:example.org",
        "@bob:example.org"
    ]
    
    static let memberIDs = [
        "@alice:example.org",
        "@bob:example.org",
        "@charlie:example.org",
        "@dave:example.org",
        "@joe:example.org",
        "@jackie:example.org"
    ]
    
    static var previews: some View {
        body
            .environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 0) {
            // Single member
            ActiveCallTimelineItemView(isDM: false,
                                       isVoiceCall: false,
                                       activeMembers: ["@alice:example.org"],
                                       sender: .init(id: "@alice:example.org", displayName: "Alice"),
                                       isJoined: false,
                                       callStartTimestamp: Date())
            
            Divider()
            
            // Multiple members
            ActiveCallTimelineItemView(isDM: false,
                                       isVoiceCall: false,
                                       activeMembers: memberIDs,
                                       sender: .init(id: "@sender:localhost"),
                                       isJoined: false,
                                       callStartTimestamp: nil)
            
            Divider()
            
            // Voice call
            ActiveCallTimelineItemView(isDM: false,
                                       isVoiceCall: true,
                                       activeMembers: memberIDs,
                                       sender: .init(id: "@sender:localhost"),
                                       isJoined: false,
                                       callStartTimestamp: nil)
            
            Divider()
            
            // DM
            ActiveCallTimelineItemView(isDM: true,
                                       isVoiceCall: false,
                                       activeMembers: twoMembers,
                                       sender: .init(id: "@sender:localhost"),
                                       isJoined: false,
                                       callStartTimestamp: nil)
            
            Divider()
            
            // DM with single member
            ActiveCallTimelineItemView(isDM: true,
                                       isVoiceCall: false,
                                       activeMembers: ["@sender:localhost"],
                                       sender: .init(id: "@sender:localhost", displayName: "John"),
                                       isJoined: false,
                                       callStartTimestamp: nil)
        }
        .padding()
    }
}
