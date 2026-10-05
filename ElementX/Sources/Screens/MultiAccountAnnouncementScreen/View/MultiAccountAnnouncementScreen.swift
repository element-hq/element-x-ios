//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MultiAccountAnnouncementScreen: View {
    let context: MultiAccountAnnouncementScreenViewModel.Context
    
    @State private var contentHeight: CGFloat = .zero
    @State private var buttonHeight: CGFloat = .zero
    
    var body: some View {
        ScrollView {
            content
                .readHeight($contentHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .backportSafeAreaBar(edge: .bottom, spacing: 0) {
            addAccountButton
                .readHeight($buttonHeight)
        }
        .presentationDetents([.height(contentHeight + buttonHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.userProfileSolid)
            
            VStack(spacing: 8) {
                Text(L10n.screenMultiAccountAnnouncementTitle)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                
                Text(context.viewState.description)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 76)
        .padding(.bottom, 24)
    }
    
    private var closeButton: some View {
        Button {
            context.send(viewAction: .close)
        } label: {
            if #available(iOS 26, *) {
                closeIcon
                    .snapshotableGlassEffect(.regular.interactive(),
                                             snapshotBackground: .compound.bgSubtleSecondary,
                                             in: .circle)
            } else {
                closeIcon
            }
        }
        .accessibilityLabel(L10n.actionClose)
        .padding(16)
    }
    
    private var closeIcon: some View {
        CompoundIcon(\.close)
            .foregroundStyle(.compound.iconPrimary)
            .padding(10)
    }
    
    private var addAccountButton: some View {
        Button {
            context.send(viewAction: .addAccount)
        } label: {
            Label(L10n.screenMultiAccountAnnouncementAction, icon: \.plus)
        }
        .buttonStyle(.compound(.primary))
        .padding(16)
    }
}

// MARK: - Previews

struct MultiAccountAnnouncementScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = MultiAccountAnnouncementScreenViewModel()
    
    static var previews: some View {
        MultiAccountAnnouncementScreen(context: viewModel.context)
            .previewDisplayName("Default")
        
        MultiAccountAnnouncementScreen(context: viewModel.context)
            .dynamicTypeSize(.accessibility3)
            .previewDisplayName("Large text")
    }
}
