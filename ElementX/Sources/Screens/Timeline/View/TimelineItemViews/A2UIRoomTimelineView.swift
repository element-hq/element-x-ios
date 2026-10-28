//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// An A2UI message. Renders its surfaces when the feature is enabled, otherwise its plain-text fallback.
struct A2UIRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: A2UIRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            if context?.viewState.a2uiEnabled == true, let surfaces = context?.viewState.a2uiSurfacesProvider?(timelineItem) {
                A2UISurfacesView(surfaces: surfaces) { surfaceID, key in
                    context?.send(viewAction: .triggerA2UIAction(itemID: timelineItem.id, surfaceID: surfaceID, key: key))
                }
            } else {
                FormattedBodyText(text: timelineItem.body, trailingReservedSize: timelineItem.trailingReservedSize)
            }
        }
    }
}

struct A2UIRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(a2uiEnabled: true)
    static let disabledViewModel = makeViewModel(a2uiEnabled: false)
    
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                A2UIRoomTimelineView(timelineItem: .mock(messages: A2UIPreviewFixtures.contactForm))
                A2UIRoomTimelineView(timelineItem: .mock(messages: A2UIPreviewFixtures.templateList, isOutgoing: true))
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewDisplayName("Forms")
        
        VStack(alignment: .leading, spacing: 20) {
            A2UIRoomTimelineView(timelineItem: .mock(messages: A2UIPreviewFixtures.tabs))
            A2UIRoomTimelineView(timelineItem: .mock(messages: A2UIPreviewFixtures.noRootYet))
            A2UIRoomTimelineView(timelineItem: .mock(messages: []))
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewDisplayName("Tabs, waiting and empty")
        
        ScrollView {
            A2UIRoomTimelineView(timelineItem: .mock(messages: A2UIPreviewFixtures.shortcuts))
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewDisplayName("Wrapping rows")
        
        A2UIRoomTimelineView(timelineItem: .mock(messages: A2UIPreviewFixtures.contactForm))
            .environmentObject(disabledViewModel.context)
            .environment(\.timelineContext, disabledViewModel.context)
            .previewDisplayName("Disabled")
    }
    
    private static func makeViewModel(a2uiEnabled: Bool) -> TimelineViewModel {
        let userSettings = UserSettings.mock()
        userSettings.app.a2uiEnabled = a2uiEnabled
        return TimelineViewModel.mock(userSettings: userSettings)
    }
}

private extension A2UIRoomTimelineItem {
    static func mock(messages: [A2UIServerMessage], isOutgoing: Bool = false) -> A2UIRoomTimelineItem {
        A2UIRoomTimelineItem(id: .randomEvent,
                             body: "Please fill in the contact form.",
                             timestamp: .mock,
                             isOutgoing: isOutgoing,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "@agent:example.com", displayName: "Agent"),
                             content: .init(messages: messages))
    }
}

enum A2UIPreviewFixtures {
    static let contactForm = messages("""
    [
        { "version": "v0.9", "createSurface": { "surfaceId": "main" } },
        { "version": "v0.9", "updateComponents": { "surfaceId": "main", "components": [
            { "id": "root", "component": "Card", "child": "form" },
            { "id": "form", "component": "Column", "children": ["title", "intro", "name", "email", "plan", "subscribe", "actions"] },
            { "id": "title", "component": "Text", "text": "Contact us", "variant": "h2" },
            { "id": "intro", "component": "Text", "text": { "path": "/intro" }, "variant": "caption" },
            { "id": "name", "component": "TextField", "label": "Name", "value": { "path": "/contact/name" } },
            { "id": "email", "component": "TextField", "label": "Email", "value": { "path": "/contact/email" } },
            { "id": "plan", "component": "ChoicePicker", "label": "Plan", "value": { "path": "/contact/plan" },
              "options": [{ "label": "Free", "value": "free" }, { "label": "Pro", "value": "pro" }] },
            { "id": "subscribe", "component": "CheckBox", "label": "Subscribe to the newsletter", "value": { "path": "/contact/subscribe" } },
            { "id": "actions", "component": "Row", "justify": "end", "children": ["cancel", "submit"] },
            { "id": "cancel", "component": "Button", "child": "cancelLabel", "variant": "borderless", "action": { "event": { "name": "cancel" } } },
            { "id": "cancelLabel", "component": "Text", "text": "Cancel" },
            { "id": "submit", "component": "Button", "child": "submitLabel", "variant": "primary",
              "action": { "event": { "name": "submitContactForm", "context": { "formId": "contact_form_1", "contact": { "path": "/contact" } } } } },
            { "id": "submitLabel", "component": "Text", "text": "Send" }
        ] } },
        { "version": "v0.9", "updateDataModel": { "surfaceId": "main", "path": "/", "value": {
            "intro": "Tell us how to reach you.",
            "contact": { "name": "Alice", "email": "", "plan": ["free"], "subscribe": true }
        } } }
    ]
    """)
    
    static let templateList = messages("""
    [
        { "version": "v0.9", "updateComponents": { "surfaceId": "main", "components": [
            { "id": "root", "component": "Column", "children": ["heading", "list", "divider", "rating", "when"] },
            { "id": "heading", "component": "Text", "text": "Pick a restaurant", "variant": "h3" },
            { "id": "list", "component": "List", "children": { "componentId": "item", "path": "/restaurants" } },
            { "id": "item", "component": "Row", "justify": "spaceBetween", "align": "center", "children": ["itemIcon", "itemText", "itemPick"] },
            { "id": "itemIcon", "component": "Icon", "name": { "path": "/icon" } },
            { "id": "itemText", "component": "Text", "text": { "path": "/name" }, "weight": 1 },
            { "id": "itemPick", "component": "Button", "child": "pickLabel", "action": { "event": { "name": "pick", "context": { "id": { "path": "/id" } } } } },
            { "id": "pickLabel", "component": "Text", "text": "Choose" },
            { "id": "divider", "component": "Divider" },
            { "id": "rating", "component": "Slider", "label": "Minimum rating", "min": 1, "max": 5, "value": { "path": "/minRating" } },
            { "id": "when", "component": "DateTimeInput", "label": "When", "enableDate": true, "enableTime": true, "value": { "path": "/when" } }
        ] } },
        { "version": "v0.9", "updateDataModel": { "surfaceId": "main", "value": {
            "restaurants": [
                { "id": "r1", "name": "The Green Fork", "icon": "favorite" },
                { "id": "r2", "name": "Nonna's Kitchen", "icon": "home" },
                { "id": "r3", "name": "Sakura", "icon": { "svgPath": "M12 2L15 9H22L16.5 13.5L18.5 21L12 16.5L5.5 21L7.5 13.5L2 9H9Z" } }
            ],
            "minRating": 3,
            "when": "2026-10-24T19:30"
        } } }
    ]
    """)
    
    static let tabs = messages("""
    [
        { "version": "v0.9", "updateComponents": { "surfaceId": "main", "components": [
            { "id": "root", "component": "Tabs", "tabs": [{ "title": "Overview", "child": "overview" }, { "title": "Details", "child": "details" }] },
            { "id": "overview", "component": "Text", "text": "An overview." },
            { "id": "details", "component": "Column", "children": ["detailText", "video", "gauge"] },
            { "id": "detailText", "component": "Text", "text": "Some details, a video and a component this client does not support:" },
            { "id": "video", "component": "Video", "url": "https://example.com/talk.mp4", "posterUrl": "mxc://matrix.org/1234567890ImAgE" },
            { "id": "gauge", "component": "Gauge", "value": 42 }
        ] } }
    ]
    """)
    
    /// Rows of three icon buttons, more than fit across a bubble, so they must wrap.
    static let shortcuts = messages("""
    [
        { "version": "v0.9", "updateComponents": { "surfaceId": "main", "components": [
            { "id": "root", "component": "Column", "children": ["card", "intro", "row1", "row2", "row3", "hint"] },
            { "id": "card", "component": "Card", "child": "header" },
            { "id": "header", "component": "Column", "align": "start", "children": ["title", "subtitle"] },
            { "id": "title", "component": "Text", "text": "The Matrix Conference 2026", "variant": "h2" },
            { "id": "subtitle", "component": "Text", "text": "Wed 21 Oct – Thu 22 Oct · 70 sessions · 4 rooms · 13 tracks", "variant": "caption" },
            { "id": "intro", "component": "Text", "text": "Ask me anything about the schedule, or pick a shortcut:" },
            { "id": "row1", "component": "Row", "align": "center", "children": ["now", "next", "wed"] },
            { "id": "row2", "component": "Row", "align": "center", "children": ["thu", "rooms", "tracks"] },
            { "id": "row3", "component": "Row", "justify": "center", "align": "center", "children": ["speakers", "search", "favourites"] },
            { "id": "now", "component": "Button", "variant": "primary", "child": "nowLabel", "action": { "event": { "name": "showNow" } } },
            { "id": "nowLabel", "component": "Row", "align": "center", "children": ["nowIcon", "nowText"] },
            { "id": "nowIcon", "component": "Icon", "name": "play" },
            { "id": "nowText", "component": "Text", "text": "On now" },
            { "id": "next", "component": "Button", "child": "nextLabel", "action": { "event": { "name": "showNext" } } },
            { "id": "nextLabel", "component": "Row", "align": "center", "children": ["nextIcon", "nextText"] },
            { "id": "nextIcon", "component": "Icon", "name": "fastForward" },
            { "id": "nextText", "component": "Text", "text": "Up next" },
            { "id": "wed", "component": "Button", "child": "wedLabel", "action": { "event": { "name": "showDay", "context": { "date": "2026-10-21" } } } },
            { "id": "wedLabel", "component": "Row", "align": "center", "children": ["wedIcon", "wedText"] },
            { "id": "wedIcon", "component": "Icon", "name": "calendarToday" },
            { "id": "wedText", "component": "Text", "text": "Wed 21 Oct" },
            { "id": "thu", "component": "Button", "child": "thuLabel", "action": { "event": { "name": "showDay", "context": { "date": "2026-10-22" } } } },
            { "id": "thuLabel", "component": "Row", "align": "center", "children": ["thuIcon", "thuText"] },
            { "id": "thuIcon", "component": "Icon", "name": "calendarToday" },
            { "id": "thuText", "component": "Text", "text": "Thu 22 Oct" },
            { "id": "rooms", "component": "Button", "child": "roomsLabel", "action": { "event": { "name": "showRooms" } } },
            { "id": "roomsLabel", "component": "Row", "align": "center", "children": ["roomsIcon", "roomsText"] },
            { "id": "roomsIcon", "component": "Icon", "name": "locationOn" },
            { "id": "roomsText", "component": "Text", "text": "Rooms" },
            { "id": "tracks", "component": "Button", "child": "tracksLabel", "action": { "event": { "name": "showTracks" } } },
            { "id": "tracksLabel", "component": "Row", "align": "center", "children": ["tracksIcon", "tracksText"] },
            { "id": "tracksIcon", "component": "Icon", "name": "folder" },
            { "id": "tracksText", "component": "Text", "text": "Tracks" },
            { "id": "speakers", "component": "Button", "child": "speakersLabel", "action": { "event": { "name": "showSpeakers" } } },
            { "id": "speakersLabel", "component": "Row", "align": "center", "children": ["speakersIcon", "speakersText"] },
            { "id": "speakersIcon", "component": "Icon", "name": "person" },
            { "id": "speakersText", "component": "Text", "text": "Speakers" },
            { "id": "search", "component": "Button", "child": "searchLabel", "action": { "event": { "name": "showSearch" } } },
            { "id": "searchLabel", "component": "Row", "align": "center", "children": ["searchIcon", "searchText"] },
            { "id": "searchIcon", "component": "Icon", "name": "search" },
            { "id": "searchText", "component": "Text", "text": "Search" },
            { "id": "favourites", "component": "Button", "child": "favouritesLabel", "action": { "event": { "name": "showFavourites" } } },
            { "id": "favouritesLabel", "component": "Row", "align": "center", "children": ["favouritesIcon", "favouritesText"] },
            { "id": "favouritesIcon", "component": "Icon", "name": "star" },
            { "id": "favouritesText", "component": "Text", "text": "Favourites" },
            { "id": "hint", "component": "Text", "variant": "caption",
              "text": "Try: “what's on now”, “tomorrow in Sofya”, “keynotes”, “talks about encryption”, “who is Matthew Hodgson”, “rooms”." }
        ] } }
    ]
    """)
    
    static let noRootYet = messages("""
    [{ "version": "v0.9", "createSurface": { "surfaceId": "main" } }]
    """)
    
    private static func messages(_ json: String) -> [A2UIServerMessage] {
        guard let array = JSONValue(jsonString: json)?.arrayValue else {
            fatalError("Invalid A2UI preview fixture")
        }
        return array.compactMap(A2UIServerMessage.init)
    }
}
