//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import SwiftUIIntrospect

struct SearchScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Bindable var context: SearchScreenViewModel.Context
    
    @FocusState private var isSearchFieldFocused: Bool
    /// The room highlighted for hardware keyboard selection (arrow keys + return).
    @State private var selectedRoomID: String?
    
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
        .searchable(text: $context.searchQuery, placement: .toolbarPrincipal)
        .searchFocused($isSearchFieldFocused)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search) {
            if let selectedRoomID {
                context.send(viewAction: .selectRoom(roomID: selectedRoomID))
            }
        }
        // The search field is owned by the system, so we reach into it to forward the arrow keys
        // to the results list (the same key handling the old global search did with its own field).
        .searchResultsKeyboardNavigation(moveUp: { moveSelection(backwards: true) },
                                         moveDown: { moveSelection(backwards: false) })
        // The TabView calls onAppear each time the search tab is selected, so the field re-focuses
        // and the selection resets on every switch.
        .onAppear {
            isSearchFieldFocused = true
            selectedRoomID = context.viewState.rooms.first?.id
        }
        // Reset to the first result when the results change (e.g. a new query), keyed on the top result
        // so pagination and background updates that leave it untouched don't clobber the selection.
        .onChange(of: context.viewState.rooms.first?.id) {
            selectedRoomID = context.viewState.rooms.first?.id
        }
    }
    
    private func moveSelection(backwards: Bool) {
        let rooms = context.viewState.rooms
        guard let selectedRoomID, let currentIndex = rooms.firstIndex(where: { $0.id == selectedRoomID }) else {
            selectedRoomID = rooms.first?.id
            return
        }
        
        let nextIndex = backwards ? currentIndex - 1 : currentIndex + 1
        guard rooms.indices.contains(nextIndex) else { return }
        self.selectedRoomID = rooms[nextIndex].id
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if context.viewState.isSearching {
            ContentUnavailableView.search
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
                roomCell(for: room)
                    .listRowInsets(.init())
                    .listRowBackground(selectionBackground(for: room))
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 64 } // Inset the separator to the text.
                    .onTapGesture { context.send(viewAction: .selectRoom(roomID: room.id)) }
                    .onAppear {
                        if room == context.viewState.rooms.first {
                            context.send(viewAction: .reachedTop)
                        } else if room == context.viewState.rooms.last {
                            context.send(viewAction: .reachedBottom)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private func roomCell(for room: SearchScreenRoom) -> some View {
        HStack(spacing: 12) {
            avatar(for: room)
            
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
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(.rect)
    }
    
    @ViewBuilder
    private func selectionBackground(for room: SearchScreenRoom) -> some View {
        if selectedRoomID == room.id {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.compound.bgSubtleSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
        }
    }
    
    @ViewBuilder
    private func avatar(for room: SearchScreenRoom) -> some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .globalSearch),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
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
            guard let textField = navigationController.navigationBar.topItem?.searchController?.searchBar.searchTextField else { return }
            
            if !(textField is KeyNavigatingSearchTextField) {
                object_setClass(textField, KeyNavigatingSearchTextField.self)
            }
            
            (textField as? KeyNavigatingSearchTextField)?.keyHandler = { keyCode in
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
/// stored properties — the key handler is kept as an associated object instead.
private final class KeyNavigatingSearchTextField: UISearchTextField {
    private static var handlerKey: UInt8 = 0
    
    var keyHandler: ((UIKeyboardHIDUsage) -> Bool)? {
        get { objc_getAssociatedObject(self, &Self.handlerKey) as? (UIKeyboardHIDUsage) -> Bool }
        set { objc_setAssociatedObject(self, &Self.handlerKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let keyCode = presses.first?.key?.keyCode, keyHandler?(keyCode) == true {
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
    
    static var previews: some View {
        ElementNavigationStack {
            SearchScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
        
        ElementNavigationStack {
            SearchScreen(context: loadedViewModel.context)
        }
        .previewDisplayName("Loaded")
    }
}
