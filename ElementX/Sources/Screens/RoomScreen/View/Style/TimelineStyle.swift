//
//  TimelineStyle.swift
//  ElementX
//
//  Created by Ismail on 24.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum TimelineStyle: String, CaseIterable {
    case plain
    case bubbled

    var shortDescription: String {
        switch self {
        case .plain:
            return ElementL10n.roomTimelineStylePlainShortDescription
        case .bubbled:
            return ElementL10n.roomTimelineStyleBubbledShortDescription
        }
    }
}

extension TimelineStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .plain:
            return ElementL10n.roomTimelineStylePlainLongDescription
        case .bubbled:
            return ElementL10n.roomTimelineStyleBubbledLongDescription
        }
    }
}
