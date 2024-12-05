//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct KnockRequestCellInfo: Equatable {
    let eventID: String
    let userID: String
    let displayName: String?
    let avatarURL: URL?
    let timestamp: String?
    let reason: String?
}

struct KnockRequestCell: View {
    let cellInfo: KnockRequestCellInfo
    var mediaProvider: MediaProviderProtocol?
    let onAccept: ((String) -> Void)?
    let onDecline: ((String) -> Void)?
    let onDeclineAndBan: ((String) -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            LoadableAvatarImage(url: cellInfo.avatarURL,
                                name: cellInfo.displayName,
                                contentID: cellInfo.userID,
                                avatarSize: .user(on: .knockingUserList),
                                mediaProvider: mediaProvider)
            VStack(alignment: .leading, spacing: 12) {
                header
                if let reason = cellInfo.reason {
                    DisclosableText(text: reason)
                }
                actions
            }
            .padding(.trailing, 16)
            .overlay(alignment: .bottom) {
                // Custom separator that uses the same color from the compound one
                Color.compound._borderInteractiveSecondaryAlpha
                    .frame(height: 0.5)
            }
        }
        .padding(.top, 16)
        .padding(.leading, 16)
        .background(.compound.bgCanvasDefault)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Text(cellInfo.displayName ?? cellInfo.userID)
                    .font(.compound.bodyLGSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let timestamp = cellInfo.timestamp {
                    Text(timestamp)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                }
            }
            if cellInfo.displayName != nil {
                Text(cellInfo.userID)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 0) {
            if onDecline != nil || onAccept != nil {
                HStack(spacing: 16) {
                    if let onDecline {
                        Button(L10n.actionDecline) {
                            onDecline(cellInfo.eventID)
                        }
                        .buttonStyle(.compound(.secondary, size: .medium))
                    }
                    
                    if let onAccept {
                        Button(L10n.actionAccept) {
                            onAccept(cellInfo.eventID)
                        }
                        .buttonStyle(.compound(.primary, size: .medium))
                    }
                }
            }
            
            if let onDeclineAndBan {
                Button(role: .destructive) {
                    onDeclineAndBan(cellInfo.eventID)
                } label: {
                    Text(L10n.screenKnockRequestsListDeclineAndBanActionTitle)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.compound(.plain))
                .padding(.top, 16)
            }
        }
        .padding(.bottom, 16)
    }
}

private struct DisclosableText: View {
    let text: String
    @State private var collapsedHeight = CGFloat.zero
    @State private var expandedHeight = CGFloat.zero
    @State private var isExpanded = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(text)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : 3)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { newValue in
                    if !isExpanded {
                        collapsedHeight = newValue
                    }
                }
                .background {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { geometry in
                            geometry.size.height
                        } action: { newValue in
                            expandedHeight = newValue
                        }
                        .hidden()
                }
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                CompoundIcon(\.chevronDown, size: .medium, relativeTo: .compound.bodyMD)
                    .foregroundStyle(.compound.iconTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
            .opacity(collapsedHeight < expandedHeight ? 1 : 0)
            .disabled(collapsedHeight >= expandedHeight)
        }
    }
}

extension KnockRequestCellInfo: Identifiable {
    var id: String { eventID }
}

struct KnockRequestCell_Previews: PreviewProvider, TestablePreview {
    // swiftlint:disable:next line_length
    static let aliceWithLongReason = KnockRequestCellInfo(eventID: "1", userID: "@alice:matrix.org", displayName: "Alice", avatarURL: nil, timestamp: "20 Nov 2024", reason: "Hello would like to join this room, also this is a very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very very long reason")
    
    static let aliceWithShortReason = KnockRequestCellInfo(eventID: "1", userID: "@alice:matrix.org", displayName: "Alice", avatarURL: nil, timestamp: "20 Nov 2024", reason: "Hello, I am Alice and would like to join this room, please")
    
    static let aliceWithNoReason = KnockRequestCellInfo(eventID: "1", userID: "@alice:matrix.org", displayName: "Alice", avatarURL: nil, timestamp: "20 Nov 2024", reason: nil)
    
    static let aliceWithNoName = KnockRequestCellInfo(eventID: "1", userID: "@alice:matrix.org", displayName: nil, avatarURL: nil, timestamp: "20 Nov 2024", reason: nil)
    
    static var previews: some View {
        KnockRequestCell(cellInfo: aliceWithLongReason) { _ in } onDecline: { _ in } onDeclineAndBan: { _ in }
            .previewDisplayName("Long reason")
        KnockRequestCell(cellInfo: aliceWithShortReason) { _ in } onDecline: { _ in } onDeclineAndBan: { _ in }
            .previewDisplayName("Short reason")
        KnockRequestCell(cellInfo: aliceWithNoReason) { _ in } onDecline: { _ in } onDeclineAndBan: { _ in }
            .previewDisplayName("No reason")
        KnockRequestCell(cellInfo: aliceWithNoName) { _ in } onDecline: { _ in } onDeclineAndBan: { _ in }
            .previewDisplayName("No name")
//        KnockRequestCell(cellInfo: aliceWithShortReason, onAccept: nil) onDecline: { _ in } onDeclineAndBan: { _ in }
//            .previewDisplayName("No Accept")
//        KnockRequestCell(cellInfo: aliceWithShortReason) onDeclineAndBan: { _ in }
//            .previewDisplayName("No Accept and Decline")
//        KnockRequestCell(cellInfo: aliceWithShortReason) { _ in } onDecline: { _ in })
//            .previewDisplayName("No Ban")
    }
}
