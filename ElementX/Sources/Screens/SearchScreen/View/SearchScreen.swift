//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import GameController
import SwiftUI
import SwiftUIIntrospect

struct SearchScreen: View {
    @Bindable var context: SearchScreenViewModel.Context
    
    @FocusState private var isSearchFieldFocused: Bool
    /// The room highlighted for hardware keyboard selection (arrow keys + return).
    @State private var selectedRoomID: String?
    /// The selection is only meaningful with a hardware keyboard, so don't highlight anything otherwise.
    @State private var isHardwareKeyboardConnected = false
    
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
            
            if context.viewState.rooms.isEmpty {
                emptyState
            } else {
                roomList
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.compound.bgCanvasDefault)
        .searchable(text: $context.searchQuery, placement: .toolbarPrincipal)
        .searchFocused($isSearchFieldFocused)
        .autocorrectionDisabled(true)
        .onSubmit(of: .search) {
            if let selectedRoomID {
                context.send(viewAction: .selectRoom(roomID: selectedRoomID))
            }
        }
        .searchResultsKeyboardNavigation(moveUp: { moveSelection(backwards: true) },
                                         moveDown: { moveSelection(backwards: false) })
        // The TabView calls onAppear each time the search tab is selected, so the field re-focuses
        // and the selection resets on every switch.
        .onAppear {
            context.send(viewAction: .appeared)
            isSearchFieldFocused = true
            selectedRoomID = context.viewState.rooms.first?.id
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
        .onChange(of: context.viewState.rooms.first?.id) {
            selectedRoomID = context.viewState.rooms.first?.id
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
    
    private var roomList: some View {
        List {
            ForEach(context.viewState.rooms) { room in
                SearchScreenRoomCell(room: room,
                                     context: context,
                                     isLast: room == context.viewState.rooms.last,
                                     isSelected: isHardwareKeyboardConnected && selectedRoomID == room.id)
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
    
    private func moveSelection(backwards: Bool) {
        let rooms = context.viewState.rooms
        guard let selectedRoomID,
              let currentIndex = rooms.firstIndex(where: { $0.id == selectedRoomID })
        else {
            selectedRoomID = rooms.first?.id
            return
        }
        
        let nextIndex = backwards ? currentIndex - 1 : currentIndex + 1
        guard rooms.indices.contains(nextIndex) else { return }
        self.selectedRoomID = rooms[nextIndex].id
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
            HStack(spacing: 12) {
                avatar
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(room.title)
                        .font(.compound.bodyLG)
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
            .padding(.vertical, 8)
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

private extension View {
    /// Forwards hardware up/down arrow presses from the system search field to the given closures.
    ///
    /// The `.search` role tab owns its text field, so there's no SwiftUI hook for its key presses. We reach the
    /// field through the navigation stack (as ``SearchFieldStyle`` does) and swap its class for one that overrides
    /// `pressesBegan` — the same key interception the old global search performed on its own field.
    func searchResultsKeyboardNavigation(moveUp: @escaping () -> Void, moveDown: @escaping () -> Void) -> some View {
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
                                                      mediaProvider: MediaProviderMock(.init()))
    static let loadedViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                       mediaProvider: MediaProviderMock(.init()),
                                                       initialSearchQuery: "Foundation")
    static let noResultsViewModel = SearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([]))),
                                                          mediaProvider: MediaProviderMock(.init()),
                                                          initialSearchQuery: "John Doe")
    
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
            SearchScreen(context: loadedViewModel.context)
        }
        .previewDisplayName("Loaded")
    }
}
