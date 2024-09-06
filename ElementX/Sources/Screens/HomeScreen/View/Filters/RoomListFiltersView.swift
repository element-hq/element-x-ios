//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
