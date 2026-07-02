//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import GameController
import SwiftUI
import SwiftUIIntrospect

struct SearchScreen: View {
    @Bindable var context: SearchScreenViewModel.Context
    
    @FocusState private var isSearchFieldFocused: Bool
    /// The result highlighted for hardware keyboard selection (arrow keys + return). Holds the id of a
    /// room or a message depending on the active tab.
    @State private var selectedID: String?
    /// The selection is only meaningful with a hardware keyboard, so don't highlight anything otherwise.
    @State private var isHardwareKeyboardConnected = false
    
    /// The ids of the results in the active tab, in display order.
    private var selectableIDs: [String] {
        switch context.viewState.bindings.searchMode {
        case .rooms: context.viewState.rooms.map(\.id)
        case .messages: context.viewState.messages.map(\.id)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Rendered as content rather than a navigation title so it stays visible while the search field is focused.
            Text(L10n.actionSearch)
                .font(.compound.headingXLBold)
                .foregroundStyle(.compound.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            Picker(L10n.actionSearch, selection: $context.searchMode) {
                ForEach(SearchScreenMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            switch context.viewState.bindings.searchMode {
            case .rooms:
                if context.viewState.rooms.isEmpty {
                    if context.viewState.isLoadingRooms {
                        loadingState
                    } else {
                        emptyState
                    }
                } else {
                    roomList
                }
            case .messages:
                if context.viewState.messages.isEmpty {
                    if context.viewState.isLoadingMessages {
                        loadingState
                    } else {
                        emptyState
                    }
                } else {
                    messagesList
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.compound.bgCanvasDefault)
        .searchable(text: $context.searchQuery, placement: .toolbarPrincipal)
        .searchFocused($isSearchFieldFocused)
        .autocorrectionDisabled(true)
        .background(tabShortcuts)
        .onSubmit(of: .search) {
            // A software keyboard's submit/search button just dismisses; only a hardware return selects.
            if isHardwareKeyboardConnected, selectedID != nil {
                selectCurrent()
            } else {
                isSearchFieldFocused = false
            }
        }
        .searchResultsKeyboardNavigation(moveUp: { moveSelection(backwards: true) },
                                         moveDown: { moveSelection(backwards: false) },
                                         cancel: { context.send(viewAction: .cancel) })
        // The TabView calls onAppear each time the search tab is selected, so the field re-focuses
        // and the selection resets on every switch.
        .onAppear {
            context.send(viewAction: .appeared)
            isSearchFieldFocused = true
            selectedID = selectableIDs.first
            updateHardwareKeyboardConnected()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidConnect)) { _ in
            updateHardwareKeyboardConnected()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidDisconnect)) { _ in
            updateHardwareKeyboardConnected()
        }
        // Reset to the first result when the results change (e.g. a new query), keyed on the top result
        // so pagination and background updates that leave it untouched don't clobber the selection.
        .onChange(of: selectableIDs.first) {
            selectedID = selectableIDs.first
        }
        // Reset the selection to the top when switching tabs.
        .onChange(of: context.viewState.bindings.searchMode) {
            selectedID = selectableIDs.first
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if context.viewState.isSearching {
            TitleAndIcon(title: L10n.commonNoResults,
                         subtitle: UntranslatedL10n.screenSearchNoResultsMessage(context.searchQuery),
                         icon: \.search,
                         iconStyle: .defaultSolid)
                .frame(maxWidth: .infinity)
                .padding(40)
        } else {
            TitleAndIcon(title: UntranslatedL10n.screenSearchEmptyStateTitle,
                         subtitle: UntranslatedL10n.screenSearchEmptyStateMessage,
                         icon: \.search,
                         iconStyle: .defaultSolid)
                .frame(maxWidth: .infinity)
                .padding(40)
        }
    }
    
    private var loadingState: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(40)
    }
    
    private var roomList: some View {
        List {
            ForEach(context.viewState.rooms) { room in
                SearchScreenRoomCell(room: room,
                                     context: context,
                                     isLast: room == context.viewState.rooms.last,
                                     isSelected: isHardwareKeyboardConnected && selectedID == room.id)
                    .onAppear {
                        if room == context.viewState.rooms.first {
                            context.send(viewAction: .reachedTop)
                        } else if room == context.viewState.rooms.last {
                            context.send(viewAction: .reachedBottom)
                        }
                    }
            }
        }
        .compoundList(.plain)
    }
    
    private var messagesList: some View {
        List {
            ForEach(context.viewState.messages) { message in
                SearchScreenMessageCell(message: message,
                                        context: context,
                                        isSelected: isHardwareKeyboardConnected && selectedID == message.id)
                    .onAppear {
                        if message == context.viewState.messages.last {
                            context.send(viewAction: .reachedBottom)
                        }
                    }
            }
        }
        .compoundList(.plain)
    }
    
    /// Hidden buttons that switch tabs via ⌘1/⌘2, the common shortcut for jumping to tab N.
    private var tabShortcuts: some View {
        ForEach(Array(SearchScreenMode.allCases.enumerated()), id: \.element) { index, mode in
            Button("") { context.searchMode = mode }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                .hidden()
        }
    }
    
    private func moveSelection(backwards: Bool) {
        let ids = selectableIDs
        guard let selectedID,
              let currentIndex = ids.firstIndex(of: selectedID)
        else {
            selectedID = ids.first
            return
        }
        
        let nextIndex = backwards ? currentIndex - 1 : currentIndex + 1
        guard ids.indices.contains(nextIndex) else { return }
        self.selectedID = ids[nextIndex]
    }
    
    private func selectCurrent() {
        guard let selectedID else { return }
        switch context.viewState.bindings.searchMode {
        case .rooms:
            context.send(viewAction: .selectRoom(roomID: selectedID))
        case .messages:
            guard let message = context.viewState.messages.first(where: { $0.id == selectedID }) else { return }
            context.send(viewAction: .selectMessage(roomID: message.roomID, eventID: message.id))
        }
    }
    
    private func updateHardwareKeyboardConnected() {
        isHardwareKeyboardConnected = GCKeyboard.coalesced != nil
    }
}

private struct SearchScreenRoomCell: View {
    let room: SearchScreenRoom
    let context: SearchScreenViewModel.Context
    let isLast: Bool
    let isSelected: Bool
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        Button {
            context.send(viewAction: .selectRoom(roomID: room.id))
        } label: {
            HStack(spacing: 16) {
                avatar
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.title)
                        .font(.compound.bodyLGSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .lineLimit(1)
                    
                    if !room.description.isEmpty {
                        Text(room.description)
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(SearchScreenRoomCellButtonStyle(isSelected: isSelected))
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .rowDivider()
    }
    
    @ViewBuilder
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .globalSearch),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

private struct SearchScreenRoomCellButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isSelected || configuration.isPressed ? Color.compound.bgSubtleSecondary : Color.compound.bgCanvasDefault)
            .contentShape(Rectangle())
            .animation(isSelected ? .none : .easeOut(duration: 0.1).disabledDuringTests(), value: isSelected)
    }
}

private struct SearchScreenMessageCell: View {
    let message: SearchScreenMessage
    let context: SearchScreenViewModel.Context
    let isSelected: Bool
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        Button {
            context.send(viewAction: .selectMessage(roomID: message.roomID, eventID: message.id))
        } label: {
            HStack(alignment: .top, spacing: 16) {
                avatar
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(message.roomName)
                            .font(.compound.bodyLGSemibold)
                            .foregroundStyle(.compound.textPrimary)
                            .lineLimit(3)
                        
                        Spacer()
                        
                        Text(message.timestamp.formattedMinimal())
                            .font(.compound.bodySM)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    
                    if let mediaPreview = message.mediaPreview {
                        SearchScreenMediaPreviewView(preview: mediaPreview, mediaProvider: context.mediaProvider)
                    } else if let preview = message.preview {
                        Text(preview)
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(SearchScreenRoomCellButtonStyle(isSelected: isSelected))
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .rowDivider()
    }
    
    @ViewBuilder
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: message.roomAvatar,
                            avatarSize: .room(on: .globalSearch),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

private struct SearchScreenMediaPreviewView: View {
    let preview: SearchScreenMediaPreview
    let mediaProvider: MediaProviderProtocol?
    
    private static let mediaSize: CGFloat = 36
    
    var body: some View {
        HStack(spacing: 8) {
            media
                .frame(width: Self.mediaSize, height: Self.mediaSize)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(preview.title)
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textPrimary)
                    .lineLimit(1)
                Text(preview.details)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.compound.bgSubtleSecondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var media: some View {
        switch preview.kind {
        case .file:
            icon(\.attachment)
        case .audio:
            icon(\.audio)
        case .image(let thumbnail, let blurhash):
            thumbnailView(thumbnail, blurhash: blurhash, isVideo: false)
        case .video(let thumbnail, let blurhash):
            thumbnailView(thumbnail, blurhash: blurhash, isVideo: true)
        }
    }
    
    private func icon(_ icon: KeyPath<CompoundIcons, Image>) -> some View {
        CompoundIcon(icon, size: .medium, relativeTo: .body)
            .foregroundStyle(.compound.iconPrimary)
            .frame(width: Self.mediaSize, height: Self.mediaSize)
            .background(.compound.iconOnSolidPrimary,
                        in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
    
    private func thumbnailView(_ thumbnail: ImageInfoProxy?, blurhash: String?, isVideo: Bool) -> some View {
        Color.compound.bgSubtlePrimary // Let the image aspect fill in place
            .overlay {
                if let thumbnail {
                    LoadableImage(mediaSource: thumbnail.source,
                                  blurhash: blurhash,
                                  size: thumbnail.size,
                                  mediaProvider: mediaProvider) {
                        Color.compound.bgSubtlePrimary
                    }
                    .mediaGalleryTimelineAspectRatio(imageInfo: thumbnail)
                }
            }
            .overlay {
                if isVideo {
                    CompoundIcon(\.playSolid, size: .small, relativeTo: .body)
                        .foregroundStyle(.compound.iconOnSolidPrimary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private extension View {
    /// Forwards hardware up/down arrow and escape presses from the system search field to the given closures.
    ///
    /// The `.search` role tab owns its text field, so there's no SwiftUI hook for its key presses. We reach the
    /// field through the navigation stack (as ``SearchFieldStyle`` does) and swap its class for one that overrides
    /// `pressesBegan` — the same key interception the old global search performed on its own field.
    func searchResultsKeyboardNavigation(moveUp: @escaping () -> Void, moveDown: @escaping () -> Void, cancel: @escaping () -> Void) -> some View {
        introspect(.navigationStack, on: .supportedVersions, scope: .ancestor) { navigationController in
            guard let textField = navigationController.navigationBar.topItem?.searchController?.searchBar.searchTextField else {
                return
            }
            
            if !(textField is KeyNavigatingSearchTextField) {
                object_setClass(textField, KeyNavigatingSearchTextField.self)
            }
            
            KeyNavigatingSearchTextField.keyHandler = { keyCode in
                switch keyCode {
                case .keyboardUpArrow:
                    moveUp()
                case .keyboardDownArrow:
                    moveDown()
                case .keyboardEscape:
                    cancel()
                default:
                    return false
                }
                return true
            }
        }
    }
}

/// A `UISearchTextField` whose class is installed at runtime via `object_setClass`, so it must not declare any
/// stored properties. The handler is static, which is fine as there's only ever a single search field.
private final class KeyNavigatingSearchTextField: UISearchTextField {
    static var keyHandler: ((UIKeyboardHIDUsage) -> Bool)?
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let keyCode = presses.first?.key?.keyCode, Self.keyHandler?(keyCode) == true {
            return
        }
        super.pressesBegan(presses, with: event)
    }
}

// MARK: - Previews

struct SearchScreen_Previews: PreviewProvider, TestablePreview {
    static let emptyViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([]))),
                                                      searchService: makeSearchService(),
                                                      clientProxy: makeClientProxy(),
                                                      mediaProvider: MediaProviderMock(.init()))
    static let noResultsViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([]))),
                                                          searchService: makeSearchService(),
                                                          clientProxy: makeClientProxy(),
                                                          mediaProvider: MediaProviderMock(.init()),
                                                          initialSearchQuery: "John Doe")
    static let roomsViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                      searchService: makeSearchService(),
                                                      clientProxy: makeClientProxy(),
                                                      mediaProvider: MediaProviderMock(.init()),
                                                      initialSearchQuery: "Foundation")
    static let messagesViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([]))),
                                                         searchService: makeSearchService(results: .mockResults),
                                                         clientProxy: makeClientProxy(),
                                                         mediaProvider: MediaProviderMock(.init()),
                                                         initialSearchQuery: "Foundation",
                                                         initialSearchMode: .messages)
    static let loadingMessagesViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([]))),
                                                                searchService: makeSearchService(paginationState: .loading),
                                                                clientProxy: makeClientProxy(),
                                                                mediaProvider: MediaProviderMock(.init()),
                                                                initialSearchQuery: "Foundation",
                                                                initialSearchMode: .messages)
    
    private static func makeSearchService(results: [SearchServiceResult] = [], paginationState: SearchServicePaginationState = .idle(endReached: true)) -> SearchServiceProxyMock {
        let mock = SearchServiceProxyMock()
        mock.underlyingResultsPublisher = CurrentValueSubject<[SearchServiceResult], Never>(results).asCurrentValuePublisher()
        mock.underlyingPaginationStatePublisher = CurrentValueSubject(paginationState).asCurrentValuePublisher()
        mock.setQueryReturnValue = .success(())
        return mock
    }
    
    private static func makeClientProxy() -> ClientProxyMock {
        let mock = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        let names: [String: String] = ["!room1:matrix.org": "Alice", "!room2:matrix.org": "Bob", "!room3:matrix.org": "Coline",
                                       "!room4:matrix.org": "Bob", "!room5:matrix.org": "Office", "!room6:matrix.org": "Data analytics",
                                       "!room7:matrix.org": "Alice", "!room8:matrix.org": "Bob", "!room9:matrix.org": "Coline"]
        mock.roomSummaryForIdentifierClosure = { id in .mock(id: id, name: names[id] ?? id) }
        return mock
    }
    
    static var previews: some View {
        ElementNavigationStack {
            SearchScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
        
        ElementNavigationStack {
            SearchScreen(context: noResultsViewModel.context)
        }
        .previewDisplayName("No results")
        
        ElementNavigationStack {
            SearchScreen(context: roomsViewModel.context)
        }
        .previewDisplayName("Rooms")
        
        ElementNavigationStack {
            SearchScreen(context: messagesViewModel.context)
        }
        .previewDisplayName("Messages")
        
        ElementNavigationStack {
            SearchScreen(context: loadingMessagesViewModel.context)
        }
        .previewDisplayName("Loading messages")
    }
}

private extension [SearchServiceResult] {
    static var mockResults: [SearchServiceResult] {
        [
            SearchServiceResult(roomID: "!room1:matrix.org",
                                eventID: "$1",
                                sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                content: .message(.text(.init(body: "Have you read the Foundation series?"))),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room2:matrix.org",
                                eventID: "$2",
                                sender: .init(id: "@bob:matrix.org", displayName: "Bob"),
                                content: .message(.text(.init(body: "The Second Foundation was hidden at the other end of the galaxy."))),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room3:matrix.org",
                                eventID: "$3",
                                sender: .init(id: "@coline:matrix.org", displayName: "Coline"),
                                content: .message(.file(.init(filename: "Foundation.pdf",
                                                              caption: nil,
                                                              source: nil,
                                                              fileSize: 4 * 1024 * 1024,
                                                              thumbnailSource: nil,
                                                              contentType: nil))),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room4:matrix.org",
                                eventID: "$4",
                                sender: .init(id: "@bob:matrix.org", displayName: "Bob"),
                                content: .message(.audio(.init(filename: "Foundation.mp3",
                                                               caption: nil,
                                                               duration: 42,
                                                               waveform: nil,
                                                               source: nil,
                                                               fileSize: 4 * 1024 * 1024,
                                                               contentType: nil))),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room5:matrix.org",
                                eventID: "$5",
                                sender: .init(id: "@office:matrix.org", displayName: "Office"),
                                content: .message(.image(.init(filename: "Foundation.jpg",
                                                               caption: nil,
                                                               imageInfo: .mockImage,
                                                               thumbnailInfo: .mockThumbnail,
                                                               blurhash: nil,
                                                               contentType: nil))),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room6:matrix.org",
                                eventID: "$6",
                                sender: .init(id: "@data:matrix.org", displayName: "Data analytics"),
                                content: .message(.video(.init(filename: "Foundation.mp4",
                                                               caption: nil,
                                                               videoInfo: .mockVideo,
                                                               thumbnailInfo: .mockThumbnail,
                                                               blurhash: nil,
                                                               contentType: nil))),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room7:matrix.org",
                                eventID: "$7",
                                sender: .init(id: "@alice:matrix.org", displayName: "Alice"),
                                content: .poll(question: "What's your favourite Foundation book?"),
                                timestamp: .now),
            SearchServiceResult(roomID: "!room8:matrix.org",
                                eventID: "$8",
                                sender: .init(id: "@bob:matrix.org", displayName: "Bob"),
                                content: .liveLocation,
                                timestamp: .now),
            SearchServiceResult(roomID: "!room9:matrix.org",
                                eventID: "$9",
                                sender: .init(id: "@coline:matrix.org", displayName: "Coline"),
                                content: .redacted,
                                timestamp: .now)
        ]
    }
}
