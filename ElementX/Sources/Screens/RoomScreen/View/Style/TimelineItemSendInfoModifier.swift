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

import Compound
import SwiftUI

extension View {
    /// Adds the send info (timestamp along indicators for edits and delivery/encryption issues) for the given timeline item to this view.
    func timelineItemSendInfo(timelineItem: EventBasedTimelineItemProtocol,
                              adjustedDeliveryStatus: TimelineItemDeliveryStatus?) -> some View {
        modifier(TimelineItemSendInfoModifier(sendInfo: .init(timelineItem: timelineItem,
                                                              adjustedDeliveryStatus: adjustedDeliveryStatus)))
    }
}

/// Adds the send info to a view with the correct layout.
private struct TimelineItemSendInfoModifier: ViewModifier {
    let sendInfo: TimelineItemSendInfo
    
    var layout: AnyLayout {
        switch sendInfo.layoutType {
        case .horizontal(let spacing):
            AnyLayout(HStackLayout(alignment: .bottom, spacing: spacing))
        case .vertical(let spacing):
            AnyLayout(GridLayout(alignment: .leading, verticalSpacing: spacing))
        case .overlay:
            AnyLayout(ZStackLayout(alignment: .bottomTrailing))
        }
    }
    
    func body(content: Content) -> some View {
        layout {
            content
            TimelineItemSendInfoLabel(sendInfo: sendInfo)
        }
    }
}

/// The label shown for a timeline item with info about it's timestamp and various other indicators.
private struct TimelineItemSendInfoLabel: View {
    let sendInfo: TimelineItemSendInfo
    
    var statusIcon: KeyPath<CompoundIcons, Image>? {
        switch sendInfo.status {
        case .sendingFailed: \.error
        case .unverifiedSession, .authenticityUnknown: \.admin
        case .unencrypted: \.keyOff
        case .none: nil
        }
    }
    
    var statusIconAccessibilityLabel: String? {
        switch sendInfo.status {
        case .sendingFailed: L10n.commonSendingFailed
        case .none: nil
        // Temporary testing strings.
        case .unverifiedSession: L10n.eventShieldReasonUnsignedDevice
        case .authenticityUnknown: L10n.eventShieldReasonAuthenticityNotGuaranteed
        case .unencrypted: UntranslatedL10n.sendInfoNotEncrypted
        }
    }
    
    var body: some View {
        switch sendInfo.layoutType {
        case .overlay(capsuleStyle: true):
            content
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.compound.bgSubtleSecondary)
                .cornerRadius(10)
                .padding(.trailing, 4)
                .padding(.bottom, 4)
        case .horizontal, .overlay(capsuleStyle: false):
            content
                .padding(.bottom, -4)
        case .vertical:
            GridRow {
                content
                    .gridColumnAlignment(.trailing)
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        HStack(spacing: 4) {
            Text(sendInfo.localizedString)
            
            if let statusIcon, let statusIconAccessibilityLabel {
                CompoundIcon(statusIcon, size: .xSmall, relativeTo: .compound.bodyXS)
                    .accessibilityLabel(statusIconAccessibilityLabel)
            }
        }
        .font(.compound.bodyXS)
        .foregroundStyle(sendInfo.foregroundStyle)
    }
}

/// All the data needed to render a timeline item's send info label.
private struct TimelineItemSendInfo {
    enum Status { case sendingFailed, unverifiedSession, authenticityUnknown, unencrypted }
    
    /// Describes how the content and the send info should be arranged inside a bubble
    enum LayoutType {
        case horizontal(spacing: CGFloat = 4)
        case vertical(spacing: CGFloat = 4)
        case overlay(capsuleStyle: Bool)
    }
    
    let localizedString: String
    var status: Status?
    let layoutType: LayoutType
    
    var foregroundStyle: Color {
        switch status {
        case .sendingFailed, .unverifiedSession:
            .compound.textCriticalPrimary
        case .authenticityUnknown, .unencrypted, .none:
            .compound.textSecondary
        }
    }
}

private extension TimelineItemSendInfo {
    init(timelineItem: EventBasedTimelineItemProtocol, adjustedDeliveryStatus: TimelineItemDeliveryStatus?) {
        localizedString = timelineItem.localizedSendInfo
        
        status = if adjustedDeliveryStatus == .sendingFailed {
            .sendingFailed
        } else {
            nil
        }
        
        layoutType = switch timelineItem {
        case is TextBasedRoomTimelineItem:
            .overlay(capsuleStyle: false)
        case is ImageRoomTimelineItem,
             is VideoRoomTimelineItem,
             is StickerRoomTimelineItem:
            .overlay(capsuleStyle: true)
        case let locationTimelineItem as LocationRoomTimelineItem:
            .overlay(capsuleStyle: locationTimelineItem.content.geoURI != nil)
        case is PollRoomTimelineItem:
            .vertical(spacing: 16)
        default:
            .horizontal()
        }
    }
}

// MARK: - Previews

struct TimelineItemSendInfoLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16) {
            TimelineItemSendInfoLabel(sendInfo: .init(localizedString: "09:47 AM",
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(localizedString: "09:47 AM",
                                                      status: .sendingFailed,
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(localizedString: "09:47 AM",
                                                      status: .unverifiedSession,
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(localizedString: "09:47 AM",
                                                      status: .authenticityUnknown,
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(localizedString: "09:47 AM",
                                                      status: .unencrypted,
                                                      layoutType: .horizontal()))
        }
    }
}
