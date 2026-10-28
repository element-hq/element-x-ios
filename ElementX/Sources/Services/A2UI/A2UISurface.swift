//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A user action resolved against the data model, ready to be reported to the agent.
nonisolated struct A2UIResolvedAction: Hashable, Sendable {
    let name: String
    let sourceComponentID: String
    let context: [String: JSONValue]
}

/// One A2UI surface: a set of component definitions plus the data model they are bound to.
///
/// The surface applies `updateComponents` and `updateDataModel` messages, records user input and
/// resolves the component graph into an ``A2UIRenderNode`` tree. It has no knowledge of where
/// messages come from.
nonisolated struct A2UISurface: Hashable, Sendable {
    /// The component ID that every surface renders from.
    static let rootComponentID = "root"
    /// Guards against cyclic component references.
    private static let maxDepth = 64
    
    let surfaceID: String
    /// Whether the agent asked for the data model to accompany each action.
    var sendDataModel = false
    private(set) var dataModel: JSONValue?
    private var components: [String: A2UIComponent] = [:]
    /// Values typed into inputs that aren't bound to the data model.
    private var localValues: [A2UINodeKey: JSONValue] = [:]
    
    init(surfaceID: String) {
        self.surfaceID = surfaceID
    }
    
    /// Adds or replaces component definitions.
    mutating func updateComponents(_ newComponents: [A2UIComponent]) {
        for component in newComponents {
            components[component.id] = component
        }
    }
    
    /// Writes `value` at `path` in the data model. A `nil` value deletes the key.
    mutating func updateDataModel(path: String?, value: JSONValue?) {
        dataModel = dataModel.setting(value, at: path ?? "/")
    }
    
    /// Records a user edit. Bound inputs write through to the data model at `path`,
    /// unbound inputs remember the value for the node.
    mutating func setInputValue(_ value: JSONValue, for key: A2UINodeKey, path: String?) {
        if let path {
            updateDataModel(path: path, value: value)
        } else {
            localValues[key] = value
        }
    }
    
    /// Resolves the tree under `root`. The root is `nil` when no root component exists yet.
    func resolve() -> A2UIRenderSurface {
        A2UIRenderSurface(surfaceID: surfaceID, root: resolveNode(id: Self.rootComponentID, scope: nil, depth: 0))
    }
    
    /// The action of the node, with any context bindings looked up in the data model.
    /// `nil` when the node isn't a button with a server event action.
    func resolveAction(for key: A2UINodeKey) -> A2UIResolvedAction? {
        guard let component = components[key.componentID], component.type == "Button",
              let event = component["action"]?["event"],
              let name = event["name"]?.stringValue else {
            return nil
        }
        
        var context: [String: JSONValue] = [:]
        for (contextKey, value) in event["context"]?.objectValue ?? [:] {
            context[contextKey] = resolveDynamic(value, scope: key.scope)
        }
        return A2UIResolvedAction(name: name, sourceComponentID: component.id, context: context)
    }
    
    // MARK: - Private
    
    private func resolveNode(id: String, scope: String?, depth: Int) -> A2UIRenderNode? {
        guard let component = components[id], depth <= Self.maxDepth else { return nil }
        let key = A2UINodeKey(componentID: id, scope: scope)
        return A2UIRenderNode(key: key,
                              weight: component["weight"]?.doubleValue,
                              kind: resolveKind(of: component, key: key, depth: depth))
    }
    
    private func resolveKind(of component: A2UIComponent, key: A2UINodeKey, depth: Int) -> A2UIRenderNode.Kind {
        let scope = key.scope
        func child(_ id: JSONValue?) -> A2UIRenderNode? {
            id?.stringValue.flatMap { resolveNode(id: $0, scope: scope, depth: depth + 1) }
        }
        
        switch component.type {
        case "Text":
            return .text(resolveString(component["text"], scope: scope) ?? "",
                         variant: enumValue(component["variant"]) ?? .body)
        case "Image":
            return .image(.init(url: resolveString(component["url"], scope: scope).flatMap(Self.mediaURL),
                                description: resolveString(component["description"], scope: scope),
                                fit: enumValue(component["fit"]) ?? .fill,
                                variant: enumValue(component["variant"]) ?? .mediumFeature))
        case "Video":
            return .video(.init(url: resolveString(component["url"], scope: scope).flatMap(Self.mediaURL),
                                posterURL: resolveString(component["posterUrl"], scope: scope).flatMap(Self.mediaURL)))
        case "Icon":
            if let svgPath = component["name"]?["svgPath"]?.stringValue {
                return .icon(.svgPath(svgPath))
            }
            return .icon(.named(resolveString(component["name"], scope: scope)))
        case "Row", "Column":
            return .container(.init(axis: component.type == "Row" ? .horizontal : .vertical,
                                    children: resolveChildren(component["children"], scope: scope, depth: depth),
                                    justify: enumValue(component["justify"]) ?? .start,
                                    align: enumValue(component["align"]) ?? .stretch))
        case "List":
            return .container(.init(axis: component["direction"]?.stringValue == "horizontal" ? .horizontal : .vertical,
                                    children: resolveChildren(component["children"], scope: scope, depth: depth),
                                    justify: .start,
                                    align: enumValue(component["align"]) ?? .stretch))
        case "Card":
            return .card(child: child(component["child"]))
        case "Tabs":
            let tabs = (component["tabs"]?.arrayValue ?? []).map { tab in
                A2UITab(title: resolveString(tab["title"], scope: scope) ?? "", child: child(tab["child"]))
            }
            return .tabs(tabs)
        case "Divider":
            return .divider(axis: component["axis"]?.stringValue == "vertical" ? .vertical : .horizontal)
        case "Button":
            return .button(child: child(component["child"]),
                           variant: enumValue(component["variant"]) ?? .default,
                           isEnabled: component["action"]?["event"]?["name"]?.stringValue != nil)
        case "TextField":
            let input = inputValue(for: key, binding: component["value"])
            return .textField(.init(label: resolveString(component["label"], scope: scope) ?? "",
                                    value: Self.string(from: input.value) ?? "",
                                    path: input.path,
                                    variant: enumValue(component["variant"]) ?? .shortText))
        case "CheckBox":
            let input = inputValue(for: key, binding: component["value"])
            return .checkBox(.init(label: resolveString(component["label"], scope: scope) ?? "",
                                   value: input.value == .bool(true),
                                   path: input.path))
        case "ChoicePicker":
            let input = inputValue(for: key, binding: component["value"])
            let options = (component["options"]?.arrayValue ?? []).compactMap { option -> A2UIChoicePicker.Option? in
                guard let value = Self.string(from: option["value"]) else { return nil }
                return .init(label: resolveString(option["label"], scope: scope) ?? value, value: value)
            }
            return .choicePicker(.init(label: resolveString(component["label"], scope: scope),
                                       options: options,
                                       value: (input.value?.arrayValue ?? []).compactMap(Self.string),
                                       path: input.path,
                                       variant: enumValue(component["variant"]) ?? .mutuallyExclusive))
        case "Slider":
            let input = inputValue(for: key, binding: component["value"])
            let min = component["min"]?.doubleValue ?? 0
            return .slider(.init(label: resolveString(component["label"], scope: scope),
                                 value: input.value?.doubleValue ?? min,
                                 min: min,
                                 max: component["max"]?.doubleValue ?? 100,
                                 path: input.path))
        case "DateTimeInput":
            let input = inputValue(for: key, binding: component["value"])
            return .dateTimeInput(.init(label: resolveString(component["label"], scope: scope),
                                        value: input.value?.stringValue ?? "",
                                        path: input.path,
                                        enableDate: component["enableDate"]?.boolValue ?? false,
                                        enableTime: component["enableTime"]?.boolValue ?? false))
        default:
            return .unsupported(type: component.type)
        }
    }
    
    /// Static child IDs resolve in the current scope. A template (`componentId` + `path`) renders
    /// its component once per item of the list at `path`, scoped to that item.
    private func resolveChildren(_ children: JSONValue?, scope: String?, depth: Int) -> [A2UIRenderNode] {
        if let ids = children?.arrayValue {
            return ids.compactMap(\.stringValue).compactMap { resolveNode(id: $0, scope: scope, depth: depth + 1) }
        }
        
        guard let componentID = children?["componentId"]?.stringValue,
              let path = children?["path"]?.stringValue else {
            return []
        }
        let listPath = JSONPointer.join(scope: scope, pointer: path)
        let items = dataModel?.value(at: listPath)?.arrayValue ?? []
        return items.indices.compactMap { resolveNode(id: componentID, scope: "\(listPath)/\($0)", depth: depth + 1) }
    }
    
    /// A `{ "path": … }` binding looked up in the data model, otherwise the literal itself.
    private func resolveDynamic(_ value: JSONValue?, scope: String?) -> JSONValue? {
        guard let path = bindingPath(value, scope: scope) else { return value }
        return dataModel?.value(at: path)
    }
    
    private func resolveString(_ value: JSONValue?, scope: String?) -> String? {
        Self.string(from: resolveDynamic(value, scope: scope))
    }
    
    private func bindingPath(_ value: JSONValue?, scope: String?) -> String? {
        guard let path = value?["path"]?.stringValue else { return nil }
        return JSONPointer.join(scope: scope, pointer: path)
    }
    
    private func inputValue(for key: A2UINodeKey, binding: JSONValue?) -> (path: String?, value: JSONValue?) {
        if let path = bindingPath(binding, scope: key.scope) {
            return (path, dataModel?.value(at: path))
        }
        if let localValue = localValues[key] {
            return (nil, localValue)
        }
        return (nil, binding)
    }
    
    private func enumValue<T: RawRepresentable>(_ value: JSONValue?) -> T? where T.RawValue == String {
        value?.stringValue.flatMap(T.init(rawValue:))
    }
    
    /// Text for a value the agent meant to be displayed. Numbers drop a redundant `.0`.
    private static func string(from value: JSONValue?) -> String? {
        switch value {
        case .none, .null:
            nil
        case .string(let string):
            string
        case .number(let number):
            number == number.rounded() && abs(number) < 1e15 ? String(Int(number)) : String(number)
        case .bool(let bool):
            bool ? "true" : "false"
        default:
            value?.jsonString
        }
    }
    
    private static func mediaURL(_ string: String) -> URL? {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "mxc"].contains(scheme) else {
            return nil
        }
        return url
    }
}
