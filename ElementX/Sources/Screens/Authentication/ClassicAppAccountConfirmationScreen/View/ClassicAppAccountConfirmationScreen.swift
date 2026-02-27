//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ClassicAppAccountConfirmationScreen: View {
    @Bindable var context: ClassicAppAccountConfirmationScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            mainContent
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationTitle(UntranslatedL10n.screenOnboardingSignInWithClassic)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    var mainContent: some View {
        VStack(spacing: 24) {
            PlaceholderAvatarImage(name: context.viewState.classicAppAccount.displayName,
                                   contentID: context.viewState.classicAppAccount.userID)
                .scaledFrame(size: 72)
                .avatarShape(.circle, size: 72)
            
            VStack(spacing: 4) {
                Text(context.viewState.title)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = context.viewState.subtitle {
                    Text(subtitle)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text(UntranslatedL10n.screenClassicAppAccountConfirmationMessage)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                .multilineTextAlignment(.center)
        }
    }
    
    var buttons: some View {
        Button(L10n.actionContinue) {
            context.send(viewAction: .continue)
        }
        .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct ClassicAppAccountConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        ElementNavigationStack {
            ClassicAppAccountConfirmationScreen(context: viewModel.context)
        }
    }
    
    static func makeViewModel() -> ClassicAppAccountConfirmationScreenViewModel {
        ClassicAppAccountConfirmationScreenViewModel(classicAppAccount: .init(userID: "@alice:matrix.org",
                                                                              displayName: "Alice",
                                                                              serverName: "matrix.org",
                                                                              cryptoStoreURL: .cachesDirectory),
                                                     authenticationService: AuthenticationService.mock,
                                                     userIndicatorController: UserIndicatorControllerMock())
    }
}
