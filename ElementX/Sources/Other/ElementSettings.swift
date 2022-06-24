//
//  ElementSettings.swift
//  ElementX
//
//  Created by Ismail on 24.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

/// Store Element specific app settings.
final class ElementSettings {

    // MARK: - Constants

    public enum UserDefaultsKeys: String {
        case timelineStyle
    }

    static let shared = ElementSettings()

    /// UserDefaults to be used on reads and writes.
    static var store: UserDefaults {
        .standard
    }

    private init() {
        // no-op
    }

    // MARK: -

    @AppStorage(wrappedValue: BuildSettings.defaultRoomTimelineStyle.rawValue,
                UserDefaultsKeys.timelineStyle.rawValue,
                store: store)
    private var timelineStyleRaw

    /// Computed timeline style
    var timelineStyle: TimelineStyle {
        get {
            TimelineStyle(rawValue: timelineStyleRaw) ?? BuildSettings.defaultRoomTimelineStyle
        } set {
            timelineStyleRaw = newValue.rawValue
        }
    }
}
