//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct IdentityConfirmedScreen: View {
    @ObservedObject var context: IdentityConfirmedScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding) {
            screenHeader
        } bottomContent: {
            actionButtons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            HeroImage(icon: \.checkCircle, style: .success)
                .padding(.bottom, 16)
            
            Text(L10n.screenIdentityConfirmedTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)

            Text(L10n.screenIdentityConfirmedSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        Button(L10n.actionContinue) {
            context.send(viewAction: .done)
        }
        .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct IdentityConfirmedScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = IdentityConfirmedScreenViewModel()
    static var previews: some View {
        NavigationStack {
            IdentityConfirmedScreen(context: viewModel.context)
        }
    }
}
