//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The spacing used inside of a ListRow
enum ListRowTrailingSectionSpacing {
    static let horizontal = 8.0
}

/// The style applied to the details label in a list row's trailing section.
private struct ListRowDetailsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: ListRowTrailingSectionSpacing.horizontal) {
            configuration.title
                .foregroundColor(.compound.textSecondary)
            configuration.icon
                .foregroundColor(.compound.iconPrimary)
        }
        .font(.compound.bodyLG)
    }
}

/// The view shown to the right of the `ListRowLabel` inside of a `ListRow`.
/// This consists of both the `ListRowDetails` and the `ListRowAccessory`.
public struct ListRowTrailingSection<Icon: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    private var title: String?
    private var icon: Icon?
    private var counter: Int?
    private var isWaiting = false
    private var accessory: ListRowAccessory?
    
    @ScaledMetric private var iconSize = 24
    private var hideAccessory: Bool { isWaiting && accessory?.kind == .unselected }
    
    init(_ details: ListRowDetails<Icon>?, accessory: ListRowAccessory? = nil) {
        title = details?.title
        icon = details?.icon
        isWaiting = details?.isWaiting ?? false
        counter = details?.counter
        self.accessory = accessory
    }
    
    public var body: some View {
        HStack(spacing: ListRowTrailingSectionSpacing.horizontal) {
            if isWaiting {
                ProgressView()
            }
            
            if title != nil || icon != nil {
                Label {
                    title.map(Text.init)
                } icon: {
                    icon
                }
                .labelStyle(ListRowDetailsLabelStyle())
            }
            
            if let counter {
                Text("\(counter)")
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textOnSolidPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background { Capsule().fill(isEnabled ? .compound.iconSuccessPrimary : .compound.iconDisabled) }
            }
            
            if let accessory, !hideAccessory {
                accessory
            }
        }
        .frame(minWidth: iconSize)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

struct ListRowTrailingSection_Previews: PreviewProvider, TestablePreview {
    static let someCondition = true
    static let otherCondition = true
    
    static var previews: some View {
        VStack(spacing: 40) {
            details
            withAccessory
        }
    }
    
    static var details: some View {
        VStack(spacing: 20) {
            ListRowTrailingSection(.label(title: "Content", icon: Image(systemName: "square.dashed")))
            ListRowTrailingSection(.label(title: "Content", systemIcon: .squareDashed))
            ListRowTrailingSection(.title("Content"))
            ListRowTrailingSection(.icon(Image(systemName: "square.dashed")))
            ListRowTrailingSection(.systemIcon(.squareDashed))
            ListRowTrailingSection(.isWaiting(true))
            
            ListRowTrailingSection(.systemIcon(.checkmark))
            ListRowTrailingSection(.title("Hello"))
            
            ListRowTrailingSection(someCondition ? .isWaiting(true) : otherCondition ? .systemIcon(.checkmark) : .title("Hello"))
            
            ListRowTrailingSection(.title("Hello", counter: 1))
            ListRowTrailingSection(.title("Hello", counter: 1))
                .disabled(true)
        }
    }
    
    static var withAccessory: some View {
        VStack(spacing: 20) {
            ListRowTrailingSection(.isWaiting(true), accessory: .selection(true))
                .border(.purple)
            
            // The checkmark should be hidden.
            ListRowTrailingSection(.isWaiting(true), accessory: .selection(false))
                .border(.purple)
            
            // The checkmark's space should be reserved.
            ListRowTrailingSection(.isWaiting(false), accessory: .selection(false))
                .border(.purple)
            
            ListRowTrailingSection(.counter(1), accessory: .navigationLink)
                .border(.purple)
        }
    }
}
