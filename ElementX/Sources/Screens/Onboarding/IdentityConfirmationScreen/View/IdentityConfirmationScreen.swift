//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct IdentityConfirmationScreen: View {
    @ObservedObject var context: IdentityConfirmationScreenViewModel.Context
    
    var shouldShowSkipButton: Bool {
        #if DEBUG
        !ProcessInfo.isRunningTests
        #else
        false
        #endif
    }
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding) {
            screenHeader
        } bottomContent: {
            actionButtons
        }
        .toolbar { toolbar }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            HeroImage(icon: \.lockSolid)
                .padding(.bottom, 16)
            
            Text(L10n.screenIdentityConfirmationTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)

            Text(L10n.screenIdentityConfirmationSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
            
            Button(L10n.actionLearnMore) {
                UIApplication.shared.open(context.viewState.learnMoreURL)
            }
            .buttonStyle(.compound(.plain))
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if context.viewState.availableActions.contains(.interactiveVerification) {
                Button(L10n.screenIdentityConfirmationUseAnotherDevice) {
                    context.send(viewAction: .otherDevice)
                }
                .buttonStyle(.compound(.primary))
                
                if context.viewState.availableActions.contains(.recovery) {
                    Button(L10n.screenIdentityConfirmationUseRecoveryKey) {
                        context.send(viewAction: .recoveryKey)
                    }
                    .buttonStyle(.compound(.secondary))
                }
            } else if context.viewState.availableActions.contains(.recovery) {
                Button(L10n.screenIdentityConfirmationUseRecoveryKey) {
                    context.send(viewAction: .recoveryKey)
                }
                .buttonStyle(.compound(.primary))
            }
            
            if shouldShowSkipButton {
                Button(L10n.actionSkip) {
                    context.send(viewAction: .skip)
                }
                .buttonStyle(.compound(.plain))
            }
            
            Button(L10n.screenIdentityConfirmationCannotConfirm) {
                context.send(viewAction: .reset)
            }
            .buttonStyle(.compound(.plain))
            .padding(.vertical, 14)
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .destructiveAction) {
            Button(L10n.actionSignout) {
                context.send(viewAction: .logout)
            }
        }
    }
}

// MARK: - Previews

struct IdentityConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            IdentityConfirmationScreen(context: viewModel.context)
        }
        .snapshotPreferences(delay: 0.25)
    }
    
    private static var viewModel: IdentityConfirmationScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.sessionSecurityStatePublisher = CurrentValuePublisher<SessionSecurityState, Never>(.init(verificationState: .unverified, recoveryState: .enabled))
        
        return IdentityConfirmationScreenViewModel(userSession: userSession,
                                                   appSettings: ServiceLocator.shared.settings,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
