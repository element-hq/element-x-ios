//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public enum CompoundListKind {
    /// The default style for `List` or `Form`.
    case inset
    /// The `.plain` style when using a `List`.
    case plain
}

public extension View {
    /// Styles a list using the Compound design tokens.
    @ViewBuilder
    func compoundList(_ kind: CompoundListKind = .inset) -> some View {
        switch kind {
        case .inset:
            environment(\.defaultMinListRowHeight, 48)
                .scrollContentBackground(.hidden)
                .background(Color.compound.bgSubtleSecondaryLevel0.ignoresSafeArea())
        case .plain:
            listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 48)
                .scrollContentBackground(.hidden)
                .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        }
    }
    
    /// Styles a list section header using the Compound design tokens.
    func compoundListSectionHeader() -> some View {
        font(headerFont)
            .foregroundColor(.compound.textSecondary)
            .listRowInsets(EdgeInsets(top: 15,
                                      leading: ListRowPadding.horizontal,
                                      bottom: 8,
                                      trailing: ListRowPadding.horizontal))
    }
    
    /// Styles a list section footer using the Compound design tokens.
    func compoundListSectionFooter() -> some View {
        font(.compound.bodySM)
            .foregroundColor(.compound.textSecondary)
            .listRowInsets(EdgeInsets(top: 8,
                                      leading: ListRowPadding.horizontal,
                                      bottom: 10,
                                      trailing: ListRowPadding.horizontal))
    }
    
    // MARK: - Private
    
    private var headerFont: Font {
        if #available(iOS 26.0, *) {
            .compound.bodyMDSemibold
        } else {
            .compound.bodySM
        }
    }
}

struct ListTextStyles_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            Section {
                ListRow(label: .plain(title: "Hi!"), kind: .label)
            } footer: {
                Text("This is a footer down ere")
                    .compoundListSectionFooter()
            }
            
            Section {
                ListRow(label: .plain(title: "Second!"), kind: .label)
            } header: {
                Text("Section Title")
                    .compoundListSectionHeader()
            }
            
            Section {
                ListRow(label: .plain(title: "Third!"), kind: .label)
            } header: {
                Text("Section Title")
                    .compoundListSectionHeader()
            }
            
            Section {
                ListRow(label: .plain(title: "I was slow, I'm last."), kind: .label)
            } footer: {
                Text("This is a footer down ere")
                    .compoundListSectionFooter()
            }
        }
        .compoundList()
        .previewDisplayName("Form")
        
        List {
            Section {
                ListRow(label: .plain(title: "Hello"), kind: .label)
                ListRow(label: .plain(title: "World!"), kind: .label)
            } header: {
                Text("Section Title")
                    .compoundListSectionHeader()
            } footer: {
                Text("Section footer")
                    .compoundListSectionFooter()
            }
        }
        .compoundList()
        .previewDisplayName("List")
    }
}
