//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EditRoomAddressListRow: View {
    @Binding var aliasLocalPart: String
    var serverName: String
    var shouldDisplayError: Bool
    
    private var fullAddress: String {
        "#\(aliasLocalPart):\(serverName)"
    }
    
    var body: some View {
        ListRow(kind: .custom {
            HStack(spacing: 0) {
                Text("#")
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textSecondary)
                    .accessibilityHidden(true)
                TextField("", text: $aliasLocalPart)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    .tint(.compound.iconAccentTertiary)
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textPrimary)
                    .padding(.horizontal, 8)
                    .accessibilityHint(L10n.a11yEditRoomAddressHint(fullAddress))
                Text(":\(serverName)")
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(ListRowPadding.textFieldInsets)
            .environment(\.layoutDirection, .leftToRight)
            .errorBackground(shouldDisplayError)
        })
    }
}

private extension View {
    func errorBackground(_ shouldDisplay: Bool) -> some View {
        listRowBackground(shouldDisplay ? AnyView(RoundedRectangle(cornerRadius: 10)
                .inset(by: 1)
                .fill(.compound.bgCriticalSubtleHovered)
                .stroke(Color.compound.borderCriticalPrimary)) : AnyView(Color.compound.bgCanvasDefaultLevel1))
    }
}

enum EditRoomAddressErrorState {
    case alreadyExists
    case invalidSymbols
}

extension Set<EditRoomAddressErrorState> {
    var errorDescription: String? {
        if contains(.alreadyExists) {
            return L10n.errorRoomAddressAlreadyExists
        } else if contains(.invalidSymbols) {
            return L10n.errorRoomAddressInvalidSymbols
        }
        return nil
    }
}
