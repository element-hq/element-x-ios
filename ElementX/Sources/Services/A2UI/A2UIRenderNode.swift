//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A resolved surface: its ID and the tree under the `root` component, or `nil` before a root has been defined.
nonisolated struct A2UIRenderSurface: Hashable, Sendable, Identifiable {
    let surfaceID: String
    let root: A2UIRenderNode?
    
    var id: String {
        surfaceID
    }
}

/// Identifies a rendered node within a surface. The same component renders once per item
/// of a template list, so the scope (the list item's data model path) is part of the key.
nonisolated struct A2UINodeKey: Hashable, Sendable {
    let componentID: String
    let scope: String?
    
    init(componentID: String, scope: String? = nil) {
        self.componentID = componentID
        self.scope = scope
    }
}

/// A node of the resolved component tree, ready for a view to render.
///
/// Every data binding has been looked up in the data model and template children have been
/// expanded, so a view only needs to walk the tree. Input nodes keep the absolute data model
/// `path` they are bound to so the view can report edits back.
nonisolated struct A2UIRenderNode: Hashable, Sendable, Identifiable {
    let key: A2UINodeKey
    /// Relative size within a Row or Column.
    let weight: Double?
    let kind: Kind
    
    var id: A2UINodeKey {
        key
    }
    
    indirect enum Kind: Hashable, Sendable {
        case text(String, variant: A2UITextVariant)
        case image(A2UIImage)
        case video(A2UIVideo)
        case icon(A2UIIcon)
        case container(A2UIContainer)
        case card(child: A2UIRenderNode?)
        case tabs([A2UITab])
        case divider(axis: A2UIAxis)
        case button(child: A2UIRenderNode?, variant: A2UIButtonVariant, isEnabled: Bool)
        case textField(A2UITextField)
        case checkBox(A2UICheckBox)
        case choicePicker(A2UIChoicePicker)
        case slider(A2UISlider)
        case dateTimeInput(A2UIDateTimeInput)
        /// A component type this renderer doesn't know.
        case unsupported(type: String)
    }
}

nonisolated enum A2UITextVariant: String, Hashable, Sendable {
    case h1, h2, h3, h4, h5, caption, body
}

nonisolated struct A2UIImage: Hashable, Sendable {
    enum Fit: String, Hashable, Sendable {
        case contain, cover, fill, none, scaleDown
    }
    
    enum Variant: String, Hashable, Sendable {
        case icon, avatar, smallFeature, mediumFeature, largeFeature, header
    }
    
    /// An `http(s)` or `mxc` URL, or `nil` when the agent's URL can't be loaded.
    let url: URL?
    let description: String?
    let fit: Fit
    let variant: Variant
}

nonisolated struct A2UIVideo: Hashable, Sendable {
    /// An `http(s)` or `mxc` URL, or `nil` when the agent's URL can't be loaded.
    let url: URL?
    /// A preview image shown until playback starts.
    let posterURL: URL?
}

nonisolated enum A2UIIcon: Hashable, Sendable {
    /// A catalog icon name, when the icon is named.
    case named(String?)
    /// SVG path data in a 24x24 viewBox, when the agent supplied its own icon.
    case svgPath(String)
}

nonisolated enum A2UIAxis: String, Hashable, Sendable {
    case horizontal, vertical
}

nonisolated struct A2UIContainer: Hashable, Sendable {
    enum Justify: String, Hashable, Sendable {
        case start, center, end, spaceBetween, spaceAround, spaceEvenly, stretch
    }
    
    enum Align: String, Hashable, Sendable {
        case start, center, end, stretch
    }
    
    let axis: A2UIAxis
    let children: [A2UIRenderNode]
    let justify: Justify
    let align: Align
}

nonisolated struct A2UITab: Hashable, Sendable {
    let title: String
    let child: A2UIRenderNode?
}

nonisolated enum A2UIButtonVariant: String, Hashable, Sendable {
    case `default`, primary, borderless
}

nonisolated struct A2UITextField: Hashable, Sendable {
    enum Variant: String, Hashable, Sendable {
        case longText, number, shortText, obscured
    }
    
    let label: String
    let value: String
    let path: String?
    let variant: Variant
}

nonisolated struct A2UICheckBox: Hashable, Sendable {
    let label: String
    let value: Bool
    let path: String?
}

nonisolated struct A2UIChoicePicker: Hashable, Sendable {
    struct Option: Hashable, Sendable {
        let label: String
        let value: String
    }
    
    enum Variant: String, Hashable, Sendable {
        case multipleSelection, mutuallyExclusive
    }
    
    let label: String?
    let options: [Option]
    let value: [String]
    let path: String?
    let variant: Variant
}

nonisolated struct A2UISlider: Hashable, Sendable {
    let label: String?
    let value: Double
    let min: Double
    let max: Double
    let path: String?
}

nonisolated struct A2UIDateTimeInput: Hashable, Sendable {
    let label: String?
    /// An ISO 8601 date, time or local date-time, matching what the enabled parts allow.
    let value: String
    let path: String?
    let enableDate: Bool
    let enableTime: Bool
}
