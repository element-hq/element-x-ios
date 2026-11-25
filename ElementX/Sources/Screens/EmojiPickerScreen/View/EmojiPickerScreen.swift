//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct EmojiPickerScreen: View {
    let context: EmojiPickerScreenViewModel.Context
    
    @State var searchString = ""
    @State private var isSearching = false
    
    @ScaledMetric(relativeTo: .title) var minimumWidth: Double = 64
    @ScaledMetric(relativeTo: .compound.headingXL) private var imageSize: Double = 32
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        ElementNavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth))], spacing: 16) {
                    ForEach(context.viewState.categories) { category in
                        Section {
                            ForEach(category.emojis) { emoji in
                                Button {
                                    feedbackGenerator.impactOccurred()
                                    context.send(viewAction: .emojiTapped(emoji: emoji))
                                } label: {
                                    Group {
                                        switch emoji.item {
                                        case .emoji(let value):
                                            Text(value)
                                                .font(.compound.headingXL)
                                        case .customImage(let image):
                                            LoadableImage(mediaSource: image.mediaSource,
                                                          mediaProvider: context.mediaProvider,
                                                          transformer: { $0.scaledToFit() },
                                                          placeholder: { Color.clear })
                                                .frame(width: imageSize, height: imageSize)
                                        }
                                    }
                                    .padding(9.0)
                                    .background(emojiBackgroundColor(for: emoji.item.key), in: .circle)
                                }
                                .accessibilityLabel(accessibilityLabel(for: emoji.item))
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
            .navigationTitle(context.viewState.title)
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
    
    private func accessibilityLabel(for item: EmojiPickerItem) -> String {
        let name = switch item {
        case .emoji(let emoji): emoji
        case .customImage(let image): image.body
        }
        
        if context.viewState.selectedEmojis.contains(item.key) {
            return L10n.a11yRemoveReaction(name)
        } else {
            return L10n.a11yAddReaction(name)
        }
    }
    
    private func emojiBackgroundColor(for emoji: String) -> Color {
        if context.viewState.selectedEmojis.contains(emoji) {
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

@available(iOS 26.0, *)
struct EmojiPickerScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EmojiPickerScreenViewModel(selectedEmojis: ["😀", "😄"],
                                                      emojiProvider: EmojiProvider(userSettings: .mock()),
                                                      continuation: AsyncStream<EmojiPickerItem>.makeStream().continuation)
    
    static let emoticonsViewModel = {
        let emoticons = (1...5).map { ImagePack.Image(shortcode: "windmill\($0)", body: "Windmill \($0)", mediaSource: ImageInfoProxy.mockImage.source) }
        let imagePackProvider = ImagePackProviderMock()
        imagePackProvider.imagePacksReturnValue = .success([ImagePack(id: "windmills", displayName: "Windmills",
                                                                      isEmoticonPack: true, isStickerPack: false, images: emoticons)])
        return EmojiPickerScreenViewModel(selectedEmojis: [],
                                          emojiProvider: EmojiProvider(userSettings: .mock()),
                                          imagePackProvider: imagePackProvider,
                                          mediaProvider: MediaProviderMock(.init()),
                                          continuation: AsyncStream<EmojiPickerItem>.makeStream().continuation)
    }()
    
    static var previews: some View {
        EmojiPickerScreen(context: viewModel.context)
            .previewDisplayName("Screen")
            .snapshotPreferences(expect: viewModel.context.observe(\.viewState.categories).map { !$0.isEmpty })
        
        EmojiPickerScreen(context: emoticonsViewModel.context)
            .previewDisplayName("Emoticons")
            .snapshotPreferences(expect: emoticonsViewModel.context.observe(\.viewState.categories).map { $0.first?.id == "windmills" })
    }
}

struct EmojiPickerScreenSheet_Previews: PreviewProvider {
    static let viewModel = EmojiPickerScreenViewModel(selectedEmojis: ["😀", "😄"],
                                                      emojiProvider: EmojiProvider(userSettings: .mock()),
                                                      continuation: AsyncStream<EmojiPickerItem>.makeStream().continuation)
    
    static var previews: some View {
        Text("Timeline view")
            .sheet(isPresented: .constant(true)) {
                EmojiPickerScreen(context: viewModel.context)
            }
            .previewDisplayName("Sheet")
    }
}
