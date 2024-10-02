//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// A prompt that asks the user whether they would like to enable Analytics or not.
struct NotificationPermissionsScreen: View {
    @ObservedObject var context: NotificationPermissionsScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding, background: .gradient) {
            mainContent
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.notificationsSolid)
                .padding(.bottom, 8)
            
            Text(L10n.screenNotificationOptinTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenNotificationOptinSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
            
            Asset.Images.notificationsPromptGraphic.swiftUIImage.resizable().aspectRatio(contentMode: .fit)
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            Button(L10n.actionOk) { context.send(viewAction: .enable) }
                .buttonStyle(.compound(.primary))
            
            Button { context.send(viewAction: .notNow) } label: {
                Text(L10n.actionNotNow)
                    .font(.compound.bodyLGSemibold)
                    .padding(14)
            }
        }
    }
}

// MARK: - Previews

struct NotificationPermissionsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = NotificationPermissionsScreenViewModel(notificationManager: NotificationManagerMock())
    static var previews: some View {
        NotificationPermissionsScreen(context: viewModel.context)
    }
}
