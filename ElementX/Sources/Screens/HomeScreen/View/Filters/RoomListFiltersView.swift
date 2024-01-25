//
// Copyright 2024 New Vector Ltd
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

struct RoomListFiltersView: View {
    @StateObject var state: RoomListFiltersState
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                if state.isFiltering {
                    clearButton
                } else {
                    // This solves a weird issue withe the LazyHStack
                    // where it is resized when the button appears and disappears
                    clearButton
                        .hidden()
                        .frame(width: 0)
                }
                ForEach(state.sortedEnabledFilters) { filter in
                    RoomListFilterView(filter: filter, state: state)
                }
                ForEach(state.sortedAvailableFilters) { filter in
                    RoomListFilterView(filter: filter, state: state)
                }
            }
            .padding(.leading, state.isFiltering ? 8 : 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }
    
    private var clearButton: some View {
        Button(action: {
            withAnimation(.elementDefault) {
                state.clearFilters()
            }
        }, label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.compound.bgActionPrimaryRest)
        })
    }
}

// MARK: - Previews

struct RoomListFiltersView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomListFiltersView(state: .init())
        RoomListFiltersView(state: .init(enabledFilters: [.rooms, .favourites]))
    }
}
