//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
    /// Adds the send info (timestamp along indicators for edits and delivery/encryption issues) for the given timeline item to this view.
    func timelineItemSendInfo(timelineItem: EventBasedTimelineItemProtocol,
                              adjustedDeliveryStatus: TimelineItemDeliveryStatus?,
                              context: TimelineViewModel.Context) -> some View {
        modifier(TimelineItemSendInfoModifier(sendInfo: .init(timelineItem: timelineItem,
                                                              adjustedDeliveryStatus: adjustedDeliveryStatus),
                                              context: context))
    }
}

/// Adds the send info to a view with the correct layout.
private struct TimelineItemSendInfoModifier: ViewModifier {
    let sendInfo: TimelineItemSendInfo
    let context: TimelineViewModel.Context
    
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
                .contentShape(.rect)
                // Tap gesture to avoid the message being detected as a button by VoiceOver
                // (and the action shows a description that is already read to the user).
                .onTapGesture {
                    guard sendInfo.status != nil else { return }
                    context.send(viewAction: .itemSendInfoTapped(itemID: sendInfo.itemID))
                }
        }
    }
}

/// The label shown for a timeline item with info about it's timestamp and various other indicators.
private struct TimelineItemSendInfoLabel: View {
    let sendInfo: TimelineItemSendInfo
    
    var statusIcon: KeyPath<CompoundIcons, Image>? {
        switch sendInfo.status {
        case .sendingFailed: \.error
        case .encryptionAuthenticity(let authenticity): authenticity.icon
        case .none: nil
        }
    }
    
    var statusIconAccessibilityLabel: String? {
        switch sendInfo.status {
        case .sendingFailed: L10n.commonSendingFailed
        case .encryptionAuthenticity(let authenticity): authenticity.message
        case .none: nil
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
            
            if let statusIcon {
                CompoundIcon(statusIcon, size: .xSmall, relativeTo: .compound.bodyXS)
                    .accessibilityLabel(statusIconAccessibilityLabel ?? "")
                    .accessibilityHidden(statusIconAccessibilityLabel == nil)
            }
        }
        .font(.compound.bodyXS)
        .foregroundStyle(sendInfo.foregroundStyle)
    }
}

/// All the data needed to render a timeline item's send info label.
private struct TimelineItemSendInfo {
    enum Status { case sendingFailed, encryptionAuthenticity(EncryptionAuthenticity) }
    
    /// Describes how the content and the send info should be arranged inside a bubble
    enum LayoutType {
        case horizontal(spacing: CGFloat = 4)
        case vertical(spacing: CGFloat = 4)
        case overlay(capsuleStyle: Bool)
    }
    
    let itemID: TimelineItemIdentifier
    let localizedString: String
    var status: Status?
    let layoutType: LayoutType
    
    var foregroundStyle: Color {
        switch status {
        case .sendingFailed:
            .compound.textCriticalPrimary
        case .encryptionAuthenticity(let authenticity):
            authenticity.foregroundStyle
        case .none:
            .compound.textSecondary
        }
    }
}

private extension TimelineItemSendInfo {
    init(timelineItem: EventBasedTimelineItemProtocol, adjustedDeliveryStatus: TimelineItemDeliveryStatus?) {
        itemID = timelineItem.id
        localizedString = timelineItem.localizedSendInfo
        
        status = if case .sendingFailed = adjustedDeliveryStatus {
            .sendingFailed
        } else if let authenticity = timelineItem.properties.encryptionAuthenticity {
            .encryptionAuthenticity(authenticity)
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

private extension EncryptionAuthenticity {
    var foregroundStyle: SwiftUI.Color {
        switch color {
        case .red: .compound.textCriticalPrimary
        case .gray: .compound.textSecondary
        }
    }
}

// MARK: - Previews

struct TimelineItemSendInfoLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16) {
            TimelineItemSendInfoLabel(sendInfo: .init(itemID: .random,
                                                      localizedString: "09:47 AM",
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(itemID: .random,
                                                      localizedString: "09:47 AM",
                                                      status: .sendingFailed,
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(itemID: .random,
                                                      localizedString: "09:47 AM",
                                                      status: .encryptionAuthenticity(.unsignedDevice(color: .red)),
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(itemID: .random,
                                                      localizedString: "09:47 AM",
                                                      status: .encryptionAuthenticity(.notGuaranteed(color: .gray)),
                                                      layoutType: .horizontal()))
            TimelineItemSendInfoLabel(sendInfo: .init(itemID: .random,
                                                      localizedString: "09:47 AM",
                                                      status: .encryptionAuthenticity(.sentInClear(color: .red)),
                                                      layoutType: .horizontal()))
        }
    }
}
