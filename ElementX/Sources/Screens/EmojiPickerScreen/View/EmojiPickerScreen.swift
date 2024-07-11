//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
            .compoundSearchField()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(isSearching ? .hidden : .visible)
        .onChange(of: searchString) { _ in
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
}

// MARK: - Previews

struct EmojiPickerScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EmojiPickerScreenViewModel(emojiProvider: EmojiProvider())
    
    static var previews: some View {
        EmojiPickerScreen(context: viewModel.context, selectedEmojis: ["😀", "😄"])
            .previewDisplayName("Screen")
            .snapshot(delay: 0.5)
    }
}

struct EmojiPickerScreenSheet_Previews: PreviewProvider {
    static let viewModel = EmojiPickerScreenViewModel(emojiProvider: EmojiProvider())
    
    static var previews: some View {
        Text("Timeline view")
            .sheet(isPresented: .constant(true)) {
                EmojiPickerScreen(context: viewModel.context, selectedEmojis: ["😀", "😄"])
            }
            .previewDisplayName("Sheet")
    }
}
