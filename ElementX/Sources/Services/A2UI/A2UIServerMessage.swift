//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A server-to-client message of the A2UI (Agent-to-User Interface) protocol, v0.9.
///
/// Only the subset of the protocol and the basic catalog that the prototype renderer understands is
/// modelled. See https://a2ui.org/ for the full specification. A message usually carries one kind,
/// but the protocol allows several, so each is optional and they are applied in declaration order.
nonisolated struct A2UIServerMessage: Hashable, Sendable {
    struct CreateSurface: Hashable, Sendable {
        let surfaceID: String
        /// Whether the agent wants the surface's data model attached to each action.
        let sendDataModel: Bool
    }
    
    struct UpdateComponents: Hashable, Sendable {
        let surfaceID: String
        let components: [A2UIComponent]
    }
    
    struct UpdateDataModel: Hashable, Sendable {
        let surfaceID: String
        /// A JSON Pointer into the data model. Defaults to the root.
        let path: String?
        /// The new value. Omitting it deletes the key.
        let value: JSONValue?
    }
    
    struct DeleteSurface: Hashable, Sendable {
        let surfaceID: String
    }
    
    let version: String?
    let createSurface: CreateSurface?
    let updateComponents: UpdateComponents?
    let updateDataModel: UpdateDataModel?
    let deleteSurface: DeleteSurface?
    
    init(version: String? = A2UIEvent.version,
         createSurface: CreateSurface? = nil,
         updateComponents: UpdateComponents? = nil,
         updateDataModel: UpdateDataModel? = nil,
         deleteSurface: DeleteSurface? = nil) {
        self.version = version
        self.createSurface = createSurface
        self.updateComponents = updateComponents
        self.updateDataModel = updateDataModel
        self.deleteSurface = deleteSurface
    }
    
    /// Parses a message, which must be a JSON object. Malformed kinds are dropped rather than failing the message.
    init?(json: JSONValue) {
        guard json.objectValue != nil else { return nil }
        
        version = json["version"]?.stringValue
        
        createSurface = json["createSurface"]?["surfaceId"]?.stringValue.map { surfaceID in
            CreateSurface(surfaceID: surfaceID, sendDataModel: json["createSurface"]?["sendDataModel"]?.boolValue == true)
        }
        
        updateComponents = json["updateComponents"]?["surfaceId"]?.stringValue.map { surfaceID in
            let components = json["updateComponents"]?["components"]?.arrayValue ?? []
            return UpdateComponents(surfaceID: surfaceID, components: components.compactMap(A2UIComponent.init))
        }
        
        updateDataModel = json["updateDataModel"]?["surfaceId"]?.stringValue.map { surfaceID in
            UpdateDataModel(surfaceID: surfaceID,
                            path: json["updateDataModel"]?["path"]?.stringValue,
                            value: json["updateDataModel"]?["value"])
        }
        
        deleteSurface = json["deleteSurface"]?["surfaceId"]?.stringValue.map(DeleteSurface.init)
    }
}

/// A component definition as sent by the agent. The properties stay untyped and are
/// interpreted by ``A2UISurface`` when the component tree is resolved.
nonisolated struct A2UIComponent: Hashable, Sendable {
    let id: String
    /// The catalog type, e.g. `Text` or `Column`.
    let type: String
    let properties: [String: JSONValue]
    
    init(id: String, type: String, properties: [String: JSONValue] = [:]) {
        self.id = id
        self.type = type
        self.properties = properties
    }
    
    init?(json: JSONValue) {
        guard let properties = json.objectValue,
              let id = properties["id"]?.stringValue,
              let type = properties["component"]?.stringValue else {
            return nil
        }
        self.init(id: id, type: type, properties: properties)
    }
    
    subscript(property: String) -> JSONValue? {
        properties[property]
    }
}
