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
    
    @State var reason = ""
    let confirm: (String) -> Void
    
    @State private var sheetHeight: CGFloat = .zero
    private let topPadding: CGFloat = 44 // For the navigation bar
    
    var body: some View {
        ElementNavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    TextField(L10n.screenRoomConfirmRemovalReasonPlaceholder, text: $reason)
                        .textFieldStyle(.compound(labelText: L10n.screenRoomConfirmRemovalReasonLabel))
                    buttons
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .readHeight($sheetHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ToolbarButton(role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.height(sheetHeight + topPadding)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
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
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
    
    private var buttons: some View {
        ViewThatFits {
            HStack(spacing: 12) {
                cancelButton
                removeButton
            }
            
            VStack(spacing: 16) {
                removeButton
                cancelButton
            }
        }
        .padding(.top, 24)
    }
    
    private var cancelButton: some View {
        Button(L10n.actionCancel) {
            dismiss()
        }
        .buttonStyle(.compound(.secondary))
    }
    
    private var removeButton: some View {
        Button(L10n.actionRemove, role: .destructive) {
            confirm(reason)
        }
        .buttonStyle(.compound(.primary))
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
