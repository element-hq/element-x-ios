//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public extension View {
    /// Styles a list using the Compound design tokens.
    func compoundList() -> some View {
        environment(\.defaultMinListRowHeight, 48)
            .scrollContentBackground(.hidden)
            .background(Color.compound.bgSubtleSecondaryLevel0.ignoresSafeArea())
    }
    
    /// Styles a list section header using the Compound design tokens.
    func compoundListSectionHeader() -> some View {
        font(.compound.bodySM)
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
