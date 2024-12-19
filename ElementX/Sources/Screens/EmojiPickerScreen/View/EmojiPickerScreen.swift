//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EmojiPickerScreen: View {
    @ObservedObject var context: EmojiPickerScreenViewModel.Context
    
    var selectedEmojis = Set<String>()
    @State var searchString = ""
    @State private var isSearching = false
    
    @ScaledMetric(relativeTo: .title) var minimumWidth: Double = 64
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth))], spacing: 16) {
                    ForEach(context.viewState.categories) { category in
                        Section {
                            ForEach(category.emojis) { emoji in
                                Button {
                                    feedbackGenerator.impactOccurred()
                                    context.send(viewAction: .emojiTapped(emoji: emoji))
                                } label: {
                                    Text(emoji.value)
                                        .padding(9.0)
                                        .font(.compound.headingXL)
                                        .background(Circle()
                                            .foregroundColor(emojiBackgroundColor(for: emoji.value)))
                                }
                            }
                        } header: {
                            EmojiPickerScreenHeaderView(title: category.name)
                                .padding(.horizontal, 13)
                                .padding(.top, 10)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
            .navigationTitle(L10n.commonReactions)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .isSearching($isSearching)
            .searchable(text: $searchString, placement: .navigationBarDrawer(displayMode: .always))
            .focusSearchIfHardwareKeyboardAvailable()
            .onSubmit(of: .search, sendFirstEmojiOnMac)
            .compoundSearchField()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(isSearching ? .hidden : .visible)
        .onChange(of: searchString) {
            context.send(viewAction: .search(searchString: searchString))
        }
    }
    
    private func emojiBackgroundColor(for emoji: String) -> Color {
        if selectedEmojis.contains(emoji) {
            return .compound.bgActionPrimaryRest
        } else {
            return .clear
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .dismiss) } label: {
                Text(L10n.actionCancel)
            }
        }
    }
    
    func sendFirstEmojiOnMac() {
        // No sure-fire way to detect that the submit came from a h/w keyboard on iOS/iPadOS.
        guard ProcessInfo.processInfo.isiOSAppOnMac else { return }
        
        if !searchString.isBlank, let emoji = context.viewState.categories.first?.emojis.first {
            context.send(viewAction: .emojiTapped(emoji: emoji))
        }
    }
}

// MARK: - Previews

struct EmojiPickerScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EmojiPickerScreenViewModel(emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
    
    static var previews: some View {
        EmojiPickerScreen(context: viewModel.context, selectedEmojis: ["😀", "😄"])
            .previewDisplayName("Screen")
            .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
                !state.categories.isEmpty
            })
    }
}

struct EmojiPickerScreenSheet_Previews: PreviewProvider {
    static let viewModel = EmojiPickerScreenViewModel(emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
    
    static var previews: some View {
        Text("Timeline view")
            .sheet(isPresented: .constant(true)) {
                EmojiPickerScreen(context: viewModel.context, selectedEmojis: ["😀", "😄"])
            }
            .previewDisplayName("Sheet")
    }
}
