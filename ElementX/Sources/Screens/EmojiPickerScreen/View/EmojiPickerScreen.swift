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
    
    var body: some View {
        VStack {
            EmojiPickerSearchFieldView(searchString: $searchString)
                .padding(.horizontal, 10)
                .padding(.top, 20)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 45))], spacing: 3) {
                    ForEach(context.viewState.categories) { category in
                        Section(header: EmojiPickerHeaderView(title: category.name)
                            .padding(.horizontal, 13)
                            .padding(.top, 10)) {
                                ForEach(category.emojis) { emoji in
                                    Text(emoji.value)
                                        .frame(width: 45, height: 45)
                                        .onTapGesture {
                                            context.send(viewAction: .emojiSelected(emoji: emoji))
                                        }
                                }
                            }
                    }
                }
            }
        }
        .onChange(of: searchString) { _ in
            context.send(viewAction: .search(searchString: searchString))
        }
    }
}

// MARK: - Previews

struct EmojiPickerScreen_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerScreen(context: EmojiPickerScreenViewModel(emojiProvider: EmojiProvider()).context)
    }
}
