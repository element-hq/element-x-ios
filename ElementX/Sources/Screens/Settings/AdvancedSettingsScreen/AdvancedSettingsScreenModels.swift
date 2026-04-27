//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct AdvancedSettingsScreenViewState: BindableState {
    init(timelineMediaVisibility: TimelineMediaVisibility, hideInviteAvatars: Bool, isWaitingTimelineMediaVisibility: Bool = false, isWaitingHideInviteAvatars: Bool = false, bindings: AdvancedSettingsScreenViewStateBindings) {
        self.timelineMediaVisibility = timelineMediaVisibility
        self.hideInviteAvatars = hideInviteAvatars
        self.isWaitingTimelineMediaVisibility = isWaitingTimelineMediaVisibility
        self.isWaitingHideInviteAvatars = isWaitingHideInviteAvatars
        self.bindings = bindings
        
        let linkPlaceholder = "{link}"
        var footerString = AttributedString(L10n.screenAdvancedSettingsLiveLocationSectionFooter(linkPlaceholder))
        var linkString = AttributedString(L10n.screenAdvancedSettingsLiveLocationSectionFooterLink)
        linkString.link = URL(string: UIApplication.openSettingsURLString)
        linkString.bold()
        footerString.replace(linkPlaceholder, with: linkString)
        liveLocationUpdateFooterAttributedString = footerString
    }
    
    let liveLocationUpdateFooterAttributedString: AttributedString
    var timelineMediaVisibility: TimelineMediaVisibility
    var hideInviteAvatars: Bool
    var isWaitingTimelineMediaVisibility: Bool
    var isWaitingHideInviteAvatars: Bool
    var bindings: AdvancedSettingsScreenViewStateBindings
}

// periphery:ignore - subscript are seen as false positives
@dynamicMemberLookup
struct AdvancedSettingsScreenViewStateBindings {
    private let advancedSettings: AdvancedSettingsProtocol

    init(advancedSettings: AdvancedSettingsProtocol) {
        self.advancedSettings = advancedSettings
    }

    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<AdvancedSettingsProtocol, Setting>) -> Setting {
        get { advancedSettings[keyPath: keyPath] }
        set { advancedSettings[keyPath: keyPath] = newValue }
    }
}

enum AdvancedSettingsScreenViewAction {
    case optimizeMediaUploadsChanged
    case updateTimelineMediaVisibility(TimelineMediaVisibility)
    case updateHideInviteAvatars(Bool)
}

protocol AdvancedSettingsProtocol: AnyObject {
    var viewSourceEnabled: Bool { get set }
    var appAppearance: AppAppearance { get set }
    var sharePresence: Bool { get set }
    var optimizeMediaUploads: Bool { get set }
    var liveLocationMinimumDistanceUpdate: Int { get set }
}

extension AppSettings: AdvancedSettingsProtocol { }
