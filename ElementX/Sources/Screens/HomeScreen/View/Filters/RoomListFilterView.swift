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

struct RoomListFilterView: View {
    let filter: RoomListFilter
    @StateObject var state: RoomListFiltersState

    var body: some View {
        let binding = Binding<Bool>(get: {
            state.isFilterActive(filter)
        }, set: { isEnabled, _ in
            isEnabled ? state.activateFilter(filter) : state.deactivateFilter(filter)
        })
        Toggle(isOn: binding) {
            Text(filter.localizedName)
        }
        .toggleStyle(FilterToggleStyle())
    }
}

struct RoomListFilterView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomListFilterView(filter: .people, state: .init())
        RoomListFilterView(filter: .people, state: .init(activeFilters: [.people]))
    }
}

private struct FilterToggleStyle: ToggleStyle {
    private func strokeColor(isOn: Bool) -> Color {
        isOn ? .compound.bgActionPrimaryRest : .compound.borderInteractiveSecondary
    }
    
    private func backgroundColor(isOn: Bool) -> Color {
        isOn ? .compound.bgActionPrimaryRest : .compound.bgCanvasDefault
    }
    
    private func foregroundColor(isOn: Bool) -> Color {
        isOn ? .compound.textOnSolidPrimary : .compound.textPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20)
        configuration.label
            .font(.compound.bodyLG)
            .foregroundColor(foregroundColor(isOn: configuration.isOn))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(shape.fill(backgroundColor(isOn: configuration.isOn)))
            .overlay {
                shape
                    .inset(by: 0.5)
                    .stroke(strokeColor(isOn: configuration.isOn))
            }
            .drawingGroup()
            // The button breaks the animation for some reason, so better to use the label directly with an onTapGesture
            .onTapGesture {
                withAnimation(.elementDefault) {
                    configuration.isOn.toggle()
                }
            }
    }
}
