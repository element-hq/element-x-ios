//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct A2UISurfaceTests {
    @Test
    func contactFormResolvesBindings() throws {
        let surfaceSet = A2UISurfaceSet(messages: A2UIFixtures.contactFormMessages)
        let surface = try #require(surfaceSet["main"])
        let root = try #require(surface.resolve().root)
        
        guard case .container(let column) = root.kind else {
            Issue.record("Expected the root to be a Column")
            return
        }
        #expect(column.axis == .vertical)
        #expect(column.children.map(\.key.componentID) == ["title", "name", "subscribe", "submit"])
        
        #expect(column.children[0].kind == .text("Contact us", variant: .h2))
        #expect(column.children[1].kind == .textField(.init(label: "Name", value: "", path: "/contact/name", variant: .shortText)))
        #expect(column.children[2].kind == .checkBox(.init(label: "Subscribe to the newsletter", value: false, path: "/contact/subscribe")))
        
        guard case .button(let child, let variant, let isEnabled) = column.children[3].kind else {
            Issue.record("Expected the last child to be a Button")
            return
        }
        #expect(child?.kind == .text("Send", variant: .body))
        #expect(variant == .primary)
        #expect(isEnabled)
    }
    
    @Test
    func boundInputsWriteToTheDataModelAndActionsReadIt() throws {
        var surfaceSet = A2UISurfaceSet(messages: A2UIFixtures.contactFormMessages)
        
        surfaceSet.setInputValue("Alice", surfaceID: "main", key: .init(componentID: "name"), path: "/contact/name")
        surfaceSet.setInputValue(true, surfaceID: "main", key: .init(componentID: "subscribe"), path: "/contact/subscribe")
        
        let surface = try #require(surfaceSet["main"])
        #expect(surface.dataModel?.value(at: "/contact/name") == "Alice")
        
        let action = try #require(surface.resolveAction(for: .init(componentID: "submit")))
        #expect(action.name == "submitContactForm")
        #expect(action.sourceComponentID == "submit")
        #expect(action.context == ["formId": "contact_form_1", "contact": ["name": "Alice", "subscribe": true]])
        
        #expect(surface.resolveAction(for: .init(componentID: "title")) == nil)
    }
    
    @Test
    func unboundInputsKeepLocalValues() throws {
        var surface = A2UISurface(surfaceID: "main")
        surface.updateComponents([.init(id: "root", type: "TextField", properties: ["label": "Nickname"])])
        
        surface.setInputValue("Ally", for: .init(componentID: "root"), path: nil)
        
        let root = try #require(surface.resolve().root)
        #expect(root.kind == .textField(.init(label: "Nickname", value: "Ally", path: nil, variant: .shortText)))
        #expect(surface.dataModel == nil)
    }
    
    @Test
    func templateChildrenExpandPerListItem() throws {
        let surfaceSet = A2UISurfaceSet(messages: A2UIFixtures.templateListMessages)
        let surface = try #require(surfaceSet["main"])
        let root = try #require(surface.resolve().root)
        
        guard case .container(let list) = root.kind else {
            Issue.record("Expected the root to be a List")
            return
        }
        #expect(list.children.count == 2)
        #expect(list.children.map(\.key) == [.init(componentID: "item", scope: "/restaurants/0"),
                                             .init(componentID: "item", scope: "/restaurants/1")])
        
        guard case .container(let row) = list.children[1].kind else {
            Issue.record("Expected each item to be a Row")
            return
        }
        #expect(row.children[0].kind == .icon(.named("home")))
        #expect(row.children[1].kind == .text("Nonna's Kitchen", variant: .body))
        #expect(row.children[1].weight == 1)
        
        let action = try #require(surface.resolveAction(for: .init(componentID: "pick", scope: "/restaurants/1")))
        #expect(action.context == ["id": "r2"])
    }
    
    @Test
    func mediaURLsOnlyAllowWebAndMatrixSchemes() throws {
        var surface = A2UISurface(surfaceID: "main")
        surface.updateComponents([.init(id: "root", type: "Column", properties: ["children": ["video", "poster", "image"]]),
                                  .init(id: "video", type: "Video", properties: ["url": "https://example.com/talk.mp4",
                                                                                 "posterUrl": "mxc://example.com/poster"]),
                                  .init(id: "poster", type: "Video", properties: ["url": ["path": "/videoURL"]]),
                                  .init(id: "image", type: "Image", properties: ["url": "file:///etc/passwd"])])
        surface.updateDataModel(path: "/videoURL", value: "javascript:alert(1)")
        
        let root = try #require(surface.resolve().root)
        guard case .container(let column) = root.kind else {
            Issue.record("Expected the root to be a Column")
            return
        }
        #expect(column.children[0].kind == .video(.init(url: URL(string: "https://example.com/talk.mp4"),
                                                        posterURL: URL(string: "mxc://example.com/poster"))))
        #expect(column.children[1].kind == .video(.init(url: nil, posterURL: nil)))
        #expect(column.children[2].kind == .image(.init(url: nil, description: nil, fit: .fill, variant: .mediumFeature)))
    }
    
    @Test
    func unknownComponentsAndMissingRootsAreReported() {
        var surfaceSet = A2UISurfaceSet()
        surfaceSet.apply(.init(createSurface: .init(surfaceID: "main", sendDataModel: true)))
        #expect(surfaceSet["main"]?.resolve().root == nil)
        #expect(surfaceSet["main"]?.sendDataModel == true)
        
        surfaceSet.apply(.init(updateComponents: .init(surfaceID: "main", components: [.init(id: "root", type: "Gauge")])))
        #expect(surfaceSet["main"]?.resolve().root?.kind == .unsupported(type: "Gauge"))
        
        surfaceSet.apply(.init(deleteSurface: .init(surfaceID: "main")))
        #expect(surfaceSet.all.isEmpty)
    }
    
    @Test
    func cyclicComponentsStopResolving() throws {
        var surface = A2UISurface(surfaceID: "main")
        surface.updateComponents([.init(id: "root", type: "Column", properties: ["children": ["root"]])])
        
        let root = try #require(surface.resolve().root)
        if case .container = root.kind { } else {
            Issue.record("Expected a container even when it is cyclic")
        }
    }
    
    @Test
    func messageSurfacesApplyNewMessagesIncrementally() throws {
        let surfaces = A2UIMessageSurfaces(eventID: "$event")
        surfaces.update(messages: A2UIFixtures.contactFormMessages)
        surfaces.setInputValue("Alice", surfaceID: "main", key: .init(componentID: "name"), path: "/contact/name")
        
        // An update to a different path keeps the user's edit.
        let update = A2UIServerMessage(updateDataModel: .init(surfaceID: "main", path: "/contact/subscribe", value: true))
        surfaces.update(messages: A2UIFixtures.contactFormMessages + [update])
        #expect(surfaces.surfaceSet["main"]?.dataModel?["contact"] == ["name": "Alice", "subscribe": true])
        
        // A change to the earlier messages rebuilds the surfaces from scratch.
        surfaces.update(messages: [update])
        #expect(surfaces.surfaceSet["main"]?.dataModel == ["contact": ["subscribe": true]])
        
        let resolved = try #require(surfaces.resolveAction(surfaceID: "main", key: .init(componentID: "submit")))
        #expect(resolved.dataModel == nil, "The data model is only attached when the agent asked for it.")
    }
}

struct JSONPointerTests {
    @Test
    func readsValues() {
        let document: JSONValue = ["a": ["b": [1, 2, ["c~/d": "deep"]]]]
        #expect(document.value(at: "") == document)
        #expect(document.value(at: "/") == document)
        #expect(document.value(at: "/a/b/1") == 2)
        #expect(document.value(at: "/a/b/2/c~0~1d") == "deep")
        #expect(document.value(at: "/a/missing") == nil)
        #expect(document.value(at: "/a/b/9") == nil)
    }
    
    @Test
    func writesValues() {
        var document: JSONValue?
        document = document.setting(["name": "Alice"], at: "/contact")
        document = document.setting(true, at: "/contact/subscribe")
        document = document.setting("r1", at: "/ids/-")
        #expect(document == ["contact": ["name": "Alice", "subscribe": true], "ids": ["r1"]])
        
        document = document.setting(nil, at: "/contact/name")
        #expect(document == ["contact": ["subscribe": true], "ids": ["r1"]])
        
        document = document.setting(42, at: "/")
        #expect(document == 42)
    }
    
    @Test
    func joinsScopes() {
        #expect(JSONPointer.join(scope: nil, pointer: "/name") == "/name")
        #expect(JSONPointer.join(scope: "/", pointer: "/name") == "/name")
        #expect(JSONPointer.join(scope: "/items/0", pointer: "/name") == "/items/0/name")
        #expect(JSONPointer.join(scope: "/items/0", pointer: "name") == "/items/0/name")
        #expect(JSONPointer.join(scope: "/items/0", pointer: "/") == "/items/0")
    }
}

enum A2UIFixtures {
    static let contactFormEventJSON = """
    {
        "type": "m.room.message",
        "event_id": "$surface_event_id",
        "sender": "@agent:example.com",
        "origin_server_ts": 1700000000000,
        "content": {
            "msgtype": "io.element.a2ui",
            "body": "Please fill in the contact form.",
            "messages": [
                { "version": "v0.9", "createSurface": { "surfaceId": "main" } },
                {
                    "version": "v0.9",
                    "updateComponents": {
                        "surfaceId": "main",
                        "components": [
                            { "id": "root", "component": "Column", "children": ["title", "name", "subscribe", "submit"] },
                            { "id": "title", "component": "Text", "text": "Contact us", "variant": "h2" },
                            { "id": "name", "component": "TextField", "label": "Name", "value": { "path": "/contact/name" } },
                            { "id": "subscribe", "component": "CheckBox", "label": "Subscribe to the newsletter", "value": { "path": "/contact/subscribe" } },
                            {
                                "id": "submit",
                                "component": "Button",
                                "child": "submitLabel",
                                "variant": "primary",
                                "action": {
                                    "event": {
                                        "name": "submitContactForm",
                                        "context": { "formId": "contact_form_1", "contact": { "path": "/contact" } }
                                    }
                                }
                            },
                            { "id": "submitLabel", "component": "Text", "text": "Send" }
                        ]
                    }
                },
                {
                    "version": "v0.9",
                    "updateDataModel": { "surfaceId": "main", "path": "/", "value": { "contact": { "name": "", "subscribe": false } } }
                },
                "not a message"
            ]
        }
    }
    """
    
    static let contactFormMessages = A2UIEvent.messages(in: A2UIEvent.content(ofEventJSON: contactFormEventJSON) ?? .null)
    
    static let templateListMessages: [A2UIServerMessage] = [
        .init(updateComponents: .init(surfaceID: "main", components: [
            .init(id: "root", type: "List", properties: ["children": ["componentId": "item", "path": "/restaurants"]]),
            .init(id: "item", type: "Row", properties: ["children": ["icon", "name", "pick"]]),
            .init(id: "icon", type: "Icon", properties: ["name": ["path": "/icon"]]),
            .init(id: "name", type: "Text", properties: ["text": ["path": "/name"], "weight": 1]),
            .init(id: "pick", type: "Button", properties: ["child": "pickLabel",
                                                           "action": ["event": ["name": "pick", "context": ["id": ["path": "/id"]]]]]),
            .init(id: "pickLabel", type: "Text", properties: ["text": "Choose"])
        ])),
        .init(updateDataModel: .init(surfaceID: "main", path: nil, value: [
            "restaurants": [["id": "r1", "name": "The Green Fork", "icon": "favorite"],
                            ["id": "r2", "name": "Nonna's Kitchen", "icon": "home"]]
        ]))
    ]
}
