//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension View {
    func bubbleBackground(isOutgoing: Bool,
                          insets: EdgeInsets,
                          color: Color? = nil) -> some View {
        modifier(TimelineItemBubbleBackgroundModifier(isOutgoing: isOutgoing,
                                                      insets: insets,
                                                      color: color))
    }
}

private struct TimelineItemBubbleBackgroundModifier: ViewModifier {
    @Environment(\.timelineGroupStyle) private var timelineGroupStyle
    
    let isOutgoing: Bool
    let insets: EdgeInsets
    var color: Color?
    
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .background(color)
            .cornerRadius(12, corners: roundedCorners)
    }
    
    private var roundedCorners: UIRectCorner {
        switch timelineGroupStyle {
        case .single:
            return .allCorners
        case .first:
            if isOutgoing {
                return [.topLeft, .topRight, .bottomLeft]
            } else {
                return [.topLeft, .topRight, .bottomRight]
            }
        case .middle:
            return isOutgoing ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
        case .last:
            if isOutgoing {
                return [.topLeft, .bottomLeft, .bottomRight]
            } else {
                return [.topRight, .bottomLeft, .bottomRight]
            }
        }
    }
}
