//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// Temporary: part of the widget-driver stopgap, see `WidgetDriverChannel`.

/// The JSON the widget API is spoken in: untyped objects, since the messages mirror the SDK widget
/// machine's own loosely typed envelope and only a handful of fields are ever read.
enum WidgetJSON {
    nonisolated static func parseObject(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    /// Sorted keys, deliberately: the machine's request enum is tagged on `action` with `data` as
    /// its content, and `data` arriving first makes serde buffer it, which its raw JSON fields
    /// cannot be read from. Alphabetical order puts `action` before `data` every time.
    nonisolated static func serialize(_ object: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: .sortedKeys) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
