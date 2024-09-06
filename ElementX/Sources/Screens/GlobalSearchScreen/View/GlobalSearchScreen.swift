//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct GlobalSearchScreen: View {
    @ObservedObject var context: GlobalSearchScreenViewModel.Context
    
    @State private var selectedRoom: GlobalSearchRoom?
    @FocusState private var searchFieldFocus
    
    var body: some View {
        List {
            header
            
            Section {
                ForEach(context.viewState.rooms) { room in
                    GlobalSearchScreenListRow(room: room, context: context)
                        .listRowBackground(backgroundColor(for: room))
                        .listRowInsets(.init())
                        .onTapGesture {
                            context.send(viewAction: .select(roomID: room.id))
                        }
                        .onAppear {
                            if room == context.viewState.rooms.first {
                                context.send(viewAction: .reachedTop)
                            } else if room == context.viewState.rooms.last {
                                context.send(viewAction: .reachedBottom)
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: 700, maxHeight: 800)
        .background(.compound.bgCanvasDefault)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .background { keyboardShortcuts }
        .onAppear {
            selectedRoom = context.viewState.rooms.first
            searchFieldFocus = true
        }
        .onChange(of: context.viewState.rooms) { _ in
            selectedRoom = context.viewState.rooms.first
        }
        .onTapGesture {
            context.send(viewAction: .dismiss)
        }
    }
    
    private var header: some View {
        GlobalSearchTextFieldRepresentable(placeholder: L10n.actionSearch, text: $context.searchQuery) { keyCode in
            switch keyCode {
            case .keyboardUpArrow:
                moveToNextEntry(backwards: true)
                return true
            case .keyboardDownArrow:
                moveToNextEntry()
                return true
            case .keyboardReturnOrEnter, .keyboardReturn:
                if let selectedRoom {
                    context.send(viewAction: .select(roomID: selectedRoom.id))
                }
                return true
            case .keyboardEscape:
                context.send(viewAction: .dismiss)
                return true
            default:
                return false
            }
        } endEditingHandler: {
            if let selectedRoom {
                context.send(viewAction: .select(roomID: selectedRoom.id))
            } else { // Bring the focus back to the text field
                searchFieldFocus = true
            }
        }
        .focused($searchFieldFocus)
        .autocorrectionDisabled(true)
        .autocapitalization(.none)
        .textInputAutocapitalization(.never)
    }
    
    private var keyboardShortcuts: some View {
        Group {
            Button("") {
                context.send(viewAction: .dismiss)
            }
            // Need this to enable escape on the textField and forward the presses
            .keyboardShortcut(.escape, modifiers: [])
        }
    }
    
    private func backgroundColor(for room: GlobalSearchRoom) -> Color {
        if selectedRoom == room {
            .compound.bgSubtlePrimary
        } else {
            .compound.bgCanvasDefault
        }
    }
    
    private func moveToNextEntry(backwards: Bool = false) {
        guard let selectedRoom else {
            selectedRoom = context.viewState.rooms.first
            return
        }
        
        guard let currentIndex = context.viewState.rooms.firstIndex(of: selectedRoom) else {
            return
        }
        
        let nextIndex = (backwards ? currentIndex - 1 : currentIndex + 1)
        
        guard context.viewState.rooms.indices.contains(nextIndex) else {
            return
        }
        
        self.selectedRoom = context.viewState.rooms[nextIndex]
    }
}

private struct GlobalSearchTextFieldRepresentable: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let keyPressHandler: (UIKeyboardHIDUsage) -> Bool
    let endEditingHandler: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = GlobalSearchTextField(keyPressHandler: keyPressHandler)
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.placeholder = placeholder
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, endEditingHandler: endEditingHandler)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        let endEditingHandler: () -> Void
        
        init(text: Binding<String>, endEditingHandler: @escaping () -> Void) {
            self.text = text
            self.endEditingHandler = endEditingHandler
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // pressesBegan sometimes doesn't receive return events. Handle it here instead
            if string.rangeOfCharacter(from: .newlines) != nil {
                endEditingHandler()
                return false
            }
            
            let currentText = textField.text ?? ""
            DispatchQueue.main.async {
                self.text.wrappedValue = (currentText as NSString).replacingCharacters(in: range, with: string)
            }
            return true
        }
    }
}

private class GlobalSearchTextField: UITextField {
    let keyPressHandler: (UIKeyboardHIDUsage) -> Bool
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    init(keyPressHandler: @escaping (UIKeyboardHIDUsage) -> Bool) {
        self.keyPressHandler = keyPressHandler
        super.init(frame: .zero)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        if keyPressHandler(key.keyCode) {
            return
        }
        
        super.pressesBegan(presses, with: event)
    }
}

// MARK: - Previews

struct GlobalSearchScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = GlobalSearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                       mediaProvider: MockMediaProvider())
    
    static var previews: some View {
        NavigationStack {
            GlobalSearchScreen(context: viewModel.context)
        }
    }
}
