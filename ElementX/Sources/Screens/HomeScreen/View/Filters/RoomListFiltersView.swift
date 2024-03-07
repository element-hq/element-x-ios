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
    let leadingID = "leading"
    @Binding var state: RoomListFiltersState
    @Namespace private var namespace
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    // Using an empty view makes the scroll a bit clunky, better a 0 frame spacer
                    Spacer()
                        .frame(width: 0, height: 0)
                        .id(leadingID)
                    
                    HStack(spacing: 8) {
                        if state.isFiltering {
                            clearButton(scrollViewProxy: proxy)
                        }
                        
                        ForEach(state.activeFilters) { filter in
                            RoomListFilterView(filter: filter,
                                               isActive: getBinding(for: filter, scrollViewProxy: proxy))
                                .matchedGeometryEffect(id: filter.id, in: namespace)
                                // This will make the animation always render the enabled ones on top
                                .zIndex(1)
                        }
                        ForEach(state.availableFilters) { filter in
                            RoomListFilterView(filter: filter,
                                               isActive: getBinding(for: filter, scrollViewProxy: proxy))
                                .matchedGeometryEffect(id: filter.id, in: namespace)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.leading, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func clearButton(scrollViewProxy: ScrollViewProxy) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2).disabledDuringTests()) {
                state.clearFilters()
                scrollViewProxy.scrollTo(leadingID, anchor: .leading)
            }
        }, label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.compound.bgActionPrimaryRest)
        })
    }
    
    private func getBinding(for filter: RoomListFilter, scrollViewProxy: ScrollViewProxy) -> Binding<Bool> {
        Binding<Bool>(get: {
            state.isFilterActive(filter)
        }, set: { isEnabled, _ in
            withAnimation(.easeInOut(duration: 0.2).disabledDuringTests()) {
                if isEnabled {
                    state.activateFilter(filter)
                    scrollViewProxy.scrollTo(leadingID, anchor: .leading)
                } else {
                    state.deactivateFilter(filter)
                }
            }
        })
    }
}

// MARK: - Previews

struct RoomListFiltersView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomListFiltersView(state: .constant(.init()))
        RoomListFiltersView(state: .constant(.init(activeFilters: [.rooms, .favourites])))
    }
}
