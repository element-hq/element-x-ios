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

import SwiftUI

struct EmojiPickerScreen: View {
    @ObservedObject var context: EmojiPickerScreenViewModel.Context
    @State var searchString = ""
    @ScaledMetric(relativeTo: .title) var minimumWidth: Double = 50
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth))], spacing: 16) {
                ForEach(context.viewState.categories) { category in
                    Section(header: EmojiPickerHeaderView(title: category.name)
                        .padding(.horizontal, 13)
                        .padding(.top, 10)) {
                            ForEach(category.emojis) { emoji in
                                Button {
                                    context.send(viewAction: .emojiTapped(emoji: emoji))
                                } label: {
                                    Text(emoji.value)
                                        .font(.element.title1)
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle(L10n.commonReactions)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .searchable(text: $searchString)
        .searchableStyle(.list)
        .onChange(of: searchString) { _ in
            context.send(viewAction: .search(searchString: searchString))
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

struct EmojiPickerScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmojiPickerScreen(context: EmojiPickerScreenViewModel(emojiProvider: EmojiProvider()).context)
        }
    }
}
