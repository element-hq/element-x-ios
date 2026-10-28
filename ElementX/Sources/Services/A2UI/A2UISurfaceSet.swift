//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import OrderedCollections

/// The surfaces belonging to one A2UI source, in creation order, with routing of server messages to them.
nonisolated struct A2UISurfaceSet: Hashable, Sendable {
    private var surfaces = OrderedDictionary<String, A2UISurface>()
    
    var all: [A2UISurface] {
        Array(surfaces.values)
    }
    
    init(messages: [A2UIServerMessage] = []) {
        for message in messages {
            apply(message)
        }
    }
    
    subscript(surfaceID: String) -> A2UISurface? {
        surfaces[surfaceID]
    }
    
    /// Applies one server message. Surfaces are created on first use if the agent skipped `createSurface`.
    mutating func apply(_ message: A2UIServerMessage) {
        if let createSurface = message.createSurface {
            surfaces[createSurface.surfaceID, default: .init(surfaceID: createSurface.surfaceID)].sendDataModel = createSurface.sendDataModel
        }
        if let update = message.updateComponents {
            surfaces[update.surfaceID, default: .init(surfaceID: update.surfaceID)].updateComponents(update.components)
        }
        if let update = message.updateDataModel {
            surfaces[update.surfaceID, default: .init(surfaceID: update.surfaceID)].updateDataModel(path: update.path, value: update.value)
        }
        if let deleteSurface = message.deleteSurface {
            surfaces.removeValue(forKey: deleteSurface.surfaceID)
        }
    }
    
    mutating func setInputValue(_ value: JSONValue, surfaceID: String, key: A2UINodeKey, path: String?) {
        surfaces[surfaceID]?.setInputValue(value, for: key, path: path)
    }
    
    func resolveAction(surfaceID: String, key: A2UINodeKey) -> A2UIResolvedAction? {
        surfaces[surfaceID]?.resolveAction(for: key)
    }
}
