//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum TimelineMediaPreviewViewModelAction: Equatable {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case dismiss
}

struct TimelineMediaPreviewViewState: BindableState {
    /// The data source for all of the preview-able items.
    var dataSource: TimelineMediaPreviewDataSource
    
    /// The media item that is currently being previewed.
    var currentItem: TimelineMediaPreviewItem { dataSource.currentItem }
    /// All of the available actions for the current item.
    var currentItemActions: TimelineItemMenuActions?
    
    /// The namespace used for the zoom transition.
    let transitionNamespace: Namespace.ID
    /// A publisher that the view model uses to signal to the QLPreviewController when the current item has been loaded.
    let fileLoadedPublisher = PassthroughSubject<TimelineItemIdentifier, Never>()
    
    var bindings = TimelineMediaPreviewViewStateBindings()
}

struct TimelineMediaPreviewViewStateBindings {
    /// A binding that will present the Details view for the specified item.
    var mediaDetailsItem: TimelineMediaPreviewItem.Media?
    /// A binding that will present a confirmation to redact the specified item.
    var redactConfirmationItem: TimelineMediaPreviewItem.Media?
    /// A binding that will present a document picker to export the specified file.
    var fileToExport: TimelineMediaPreviewFileExportPicker.File?
    
    var alertInfo: AlertInfo<TimelineMediaPreviewAlertType>?
}

enum TimelineMediaPreviewAlertType {
    case authorizationRequired
}

enum TimelineMediaPreviewViewAction {
    case updateCurrentItem(TimelineMediaPreviewItem)
    case showItemDetails(TimelineMediaPreviewItem.Media)
    case menuAction(TimelineItemMenuAction, item: TimelineMediaPreviewItem.Media)
    case redactConfirmation(item: TimelineMediaPreviewItem.Media)
    case timelineEndReached
    case dismiss
}
