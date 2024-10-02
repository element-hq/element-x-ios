//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EncryptionResetScreen: View {
    @ObservedObject var context: EncryptionResetScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            mainContent
        } bottomContent: {
            Button(L10n.screenEncryptionResetActionContinueReset, role: .destructive) {
                context.send(viewAction: .reset)
            }
            .buttonStyle(.compound(.primary))
        }
        .background()
        .backgroundStyle(.compound.bgSubtleSecondary)
        .interactiveDismissDisabled()
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .alert(item: $context.alertInfo)
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 24) {
            header
            checkmarkList
            footer
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.error, style: .criticalOnSecondary)
                .padding(.bottom, 8)
            
            Text(L10n.screenEncryptionResetTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
        }
    }
    
    private var footer: some View {
        Text(L10n.screenEncryptionResetFooter)
            .font(.compound.bodyMDSemibold)
            .multilineTextAlignment(.center)
            .foregroundColor(.compound.textPrimary)
    }
    
    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading, spacing: 4) {
            checkMarkItem(title: L10n.screenEncryptionResetBullet1, position: .top, positive: true)
            checkMarkItem(title: L10n.screenEncryptionResetBullet2, position: .middle, positive: false)
            checkMarkItem(title: L10n.screenEncryptionResetBullet3, position: .bottom, positive: false)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .environment(\.backgroundStyle, AnyShapeStyle(.compound.bgSubtleSecondary))
    }

    @ViewBuilder
    private func checkMarkItem(title: String, position: ListPosition, positive: Bool) -> some View {
        RoundedLabelItem(title: title, listPosition: position) {
            if positive {
                CompoundIcon(\.check)
                    .foregroundColor(.compound.iconAccentPrimary)
            } else {
                CompoundIcon(\.close)
                    .foregroundColor(.compound.iconCriticalPrimary)
            }
        }
        .backgroundStyle(.compound.bgCanvasDefault)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct EncryptionResetScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EncryptionResetScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                                          userIndicatorController: UserIndicatorControllerMock())
    static var previews: some View {
        NavigationStack {
            EncryptionResetScreen(context: viewModel.context)
        }
    }
}
