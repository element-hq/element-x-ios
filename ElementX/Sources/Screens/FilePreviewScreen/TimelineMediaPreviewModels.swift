//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum TimelineMediaPreviewViewModelAction: Equatable {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case displayMessageForwarding(MessageForwardingItem)
    case dismiss
}

/// Identifies a media preview item — either a whole timeline item or a single gallery attachment.
enum MediaPreviewItemID: Hashable {
    case timelineItem(TimelineItemIdentifier.UniqueID)
    case galleryItem(uniqueID: TimelineItemIdentifier.UniqueID, mediaIndex: Int)
    
    /// A sentinel the viewer pins its initial item to, so it keeps its page across the room→filtered
    /// timeline handoff. A fabricated value rather than a real unique ID, which — being per-timeline —
    /// could otherwise collide between the two timeline instances.
    static let initialItem = MediaPreviewItemID.timelineItem(.init("initialMediaPreviewItem"))
    
    /// The unique ID is stable within a timeline instance across every state change — including a
    /// local echo being sent, where the transaction ID gives way to an event ID but the unique ID
    /// is recycled. Matching across timeline instances is handled separately, at bridge time.
    init(timelineItem: EventBasedMessageTimelineItemProtocol) {
        self = .timelineItem(timelineItem.id.uniqueID)
    }
}

enum TimelineMediaPreviewDriverAction {
    case itemLoaded(MediaPreviewItemID)
    case showItemDetails(TimelineMediaPreviewItem.Media)
    case exportFile(TimelineMediaPreviewFileExportPicker.File)
    case authorizationRequired(appMediator: AppMediatorProtocol)
    case dismissDetailsSheet
    
    var isItemLoaded: Bool {
        switch self {
        case .itemLoaded: true
        default: false
        }
    }
    
    var isShowItemDetails: Bool {
        switch self {
        case .showItemDetails: true
        default: false
        }
    }
    
    var isExportFile: Bool {
        switch self {
        case .exportFile: true
        default: false
        }
    }
    
    var isAuthorizationRequired: Bool {
        switch self {
        case .authorizationRequired: true
        default: false
        }
    }
}

struct TimelineMediaPreviewViewState: BindableState {
    /// The data source for all of the preview-able items.
    var dataSource: TimelineMediaPreviewDataSource
    
    /// The media item that is currently being previewed.
    var currentItem: TimelineMediaPreviewItem {
        dataSource.currentItem
    }
    
    /// All of the available actions for the current item.
    var currentItemActions: TimelineItemMenuActions?
    
    /// A publisher that the view model uses to signal actions to the QLPreviewController.
    let previewControllerDriver = PassthroughSubject<TimelineMediaPreviewDriverAction, Never>()
    
    var bindings = TimelineMediaPreviewViewStateBindings()
}

struct TimelineMediaPreviewViewStateBindings {
    /// A binding that will present a confirmation to redact the specified item.
    var redactConfirmationItem: TimelineMediaPreviewItem.Media?
}

enum TimelineMediaPreviewViewAction {
    case updateCurrentItem(TimelineMediaPreviewItem)
    case showItemDetails(TimelineMediaPreviewItem.Media)
    case menuAction(TimelineItemMenuAction, item: TimelineMediaPreviewItem.Media)
    case redactConfirmation(item: TimelineMediaPreviewItem.Media)
    case timelineEndReached
}
