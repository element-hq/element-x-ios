//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RemoteLogoutScreen: View {
    @Bindable var context: RemoteLogoutScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding) {
            content
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        VStack(spacing: 24) {
            TitleAndIcon(title: L10n.screenSignedOutTitle,
                         subtitle: L10n.screenSignedOutSubtitleV2,
                         icon: \.devices,
                         iconStyle: .defaultSolid)
                .padding(.horizontal, 8)
            
            AccountInfoCardView(userProfile: context.viewState.userProfile,
                                mediaProvider: context.mediaProvider)
            
            VStack(alignment: .leading, spacing: 2) {
                reasonItem(title: L10n.screenSignedOutReason1, icon: \.userProfile, position: .top)
                reasonItem(title: L10n.screenSignedOutReason2, icon: \.lock, position: .middle)
                reasonItem(title: L10n.screenSignedOutReason3, icon: \.block, position: .bottom)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func reasonItem(title: String, icon: KeyPath<CompoundIcons, Image>, position: ListPosition) -> some View {
        VisualListItem(title: title, position: position) {
            CompoundIcon(icon)
                .foregroundColor(.compound.iconSecondary)
                .alignmentGuide(.top) { _ in 2 }
        }
    }
    
    private var buttons: some View {
        Button(L10n.actionOk) {
            context.send(viewAction: .done)
        }
        .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct RemoteLogoutScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RemoteLogoutScreenViewModel(userSession: UserSessionMock(.init()))
    
    static var previews: some View {
        RemoteLogoutScreen(context: viewModel.context)
    }
}
