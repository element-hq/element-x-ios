//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SettingsScreenUserStatusPickerView: View {
    let action: (SettingsScreenViewAction.UserStatusAction) -> Void
    
    @State private var selection: UserStatusPreset?
    
    var body: some View {
        ElementNavigationStack {
            list
                .navigationTitle(L10n.screenSettingsUserStatusPlaceholder)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
        }
    }
    
    var list: some View {
        List {
            ListRow(label: .plain(title: ""),
                    kind: .inlinePicker(selection: $selection,
                                        items: UserStatusPreset.allCases.map { (title: "\($0.rawStatus.emoji)  \($0.rawStatus.text)", tag: $0) }))
            
            ListRow(label: .plain(title: "✍️  \(L10n.screenSettingsUserStatusCustom)"),
                    kind: .button { action(.customStatus) })
        }
        .compoundList(.plain)
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .cancel) { action(.cancel) }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .save) {
                if let selection {
                    action(.set(selection.rawStatus))
                }
            }
            .disabled(selection == nil)
        }
    }
}

private enum UserStatusPreset: CaseIterable {
    case inAMeeting
    case focusTime
    case onTheRoad
    case beRightBack
    case away
    
    var rawStatus: UserStatus.Raw {
        switch self {
        case .inAMeeting: .init(text: L10n.screenSettingsUserStatusInAMeeting, emoji: "💬")
        case .focusTime: .init(text: L10n.screenSettingsUserStatusFocusTime, emoji: "💡")
        case .onTheRoad: .init(text: L10n.screenSettingsUserStatusOnTheRoad, emoji: "🚙")
        case .beRightBack: .init(text: L10n.screenSettingsUserStatusBeRightBack, emoji: "☕️")
        case .away: .init(text: L10n.screenSettingsUserStatusAway, emoji: "🌴")
        }
    }
}

// MARK: - Previews

struct SettingsScreenUserStatusPickerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SettingsScreenUserStatusPickerView { _ in }
    }
}
