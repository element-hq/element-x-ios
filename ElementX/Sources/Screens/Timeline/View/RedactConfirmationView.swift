//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Asks the user to confirm removing a message, letting them give an optional reason.
struct RedactConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let confirm: (String) -> Void
    
    @State private var reason: String
    @State private var sheetHeight: CGFloat = .zero
    
    init(reason: String = "", confirm: @escaping (String) -> Void) {
        _reason = State(initialValue: reason)
        self.confirm = confirm
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                closeButton
                header
                RedactionReasonTextField(reason: $reason)
                buttons
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .readHeight($sheetHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var closeButton: some View {
        Button { dismiss() } label: {
            CompoundIcon(\.close, size: .medium, relativeTo: .compound.bodyLG)
                .foregroundStyle(.compound.iconPrimary)
                .padding(8)
                .background(.compound.bgSubtleSecondary, in: Circle())
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 16)
        .accessibilityLabel(L10n.actionClose)
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text(L10n.screenRoomConfirmRemovalTitle)
                .font(.compound.headingMDBold)
                .foregroundStyle(.compound.textPrimary)
            
            Text(L10n.screenRoomConfirmRemovalMessage)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
    
    private var buttons: some View {
        HStack(spacing: 12) {
            Button(L10n.actionCancel) {
                dismiss()
            }
            .buttonStyle(.compound(.secondary))
            
            Button(L10n.actionRemove, role: .destructive) {
                confirm(reason)
            }
            .buttonStyle(.compound(.primary))
        }
        .padding(.top, 24)
    }
}

// MARK: - Previews

struct RedactConfirmationView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RedactConfirmationView { _ in }
            .previewDisplayName("Empty")
        
        RedactConfirmationView(reason: "Posted in the wrong room.") { _ in }
            .previewDisplayName("Reason")
    }
}
