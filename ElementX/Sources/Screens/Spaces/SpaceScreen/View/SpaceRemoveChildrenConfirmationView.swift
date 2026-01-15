//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceRemoveChildrenConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let spaceName: String
    let action: () -> Void
    
    @State private var scrollViewHeight: CGFloat = .zero
    @State private var buttonsHeight: CGFloat = .zero
    private let topPadding = 19.0
    
    var body: some View {
        ScrollView {
            TitleAndIcon(title: L10n.screenSpaceRemoveRoomsConfirmationTitleIos(spaceName),
                         subtitle: L10n.screenSpaceRemoveRoomsConfirmationContent,
                         icon: \.errorSolid,
                         iconStyle: .alertSolid)
                .padding(24)
                .readHeight($scrollViewHeight)
        }
        .backportSafeAreaBar(edge: .bottom, spacing: 0) {
            buttons
                .readHeight($buttonsHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, topPadding) // For the drag indicator
        .presentationDetents([.height(scrollViewHeight + buttonsHeight + topPadding)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button(L10n.actionRemove, role: .destructive, action: action)
                .buttonStyle(.compound(.primary))
            
            Button(L10n.actionCancel, action: dismiss.callAsFunction)
                .buttonStyle(.compound(.tertiary))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Previews

struct SpaceRemoveChildrenConfirmationView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SpaceRemoveChildrenConfirmationView(spaceName: "Company") { }
    }
}
