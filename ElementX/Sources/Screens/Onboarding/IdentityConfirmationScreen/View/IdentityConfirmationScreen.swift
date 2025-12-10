//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct IdentityConfirmationScreen: View {
    let context: IdentityConfirmationScreenViewModel.Context
    
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
            BigIcon(icon: \.lockSolid)
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
            .buttonStyle(.compound(.tertiary, size: .small))
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if let availableActions = context.viewState.availableActions {
                if availableActions.contains(.interactiveVerification) {
                    Button(L10n.screenIdentityConfirmationUseAnotherDevice) {
                        context.send(viewAction: .otherDevice)
                    }
                    .buttonStyle(.compound(.primary))
                }
                
                if availableActions.contains(.recovery) {
                    Button(L10n.screenIdentityConfirmationUseRecoveryKey) {
                        context.send(viewAction: .recoveryKey)
                    }
                    .buttonStyle(.compound(.primary))
                }
                
                Button(L10n.screenIdentityConfirmationCannotConfirm) {
                    context.send(viewAction: .reset)
                }
                .buttonStyle(.compound(.secondary))
            } else {
                Button { /* Placeholder button, there is no action */ } label: {
                    Label {
                        Text(L10n.commonLoading)
                    } icon: {
                        ProgressView()
                            .tint(.compound.iconOnSolidPrimary)
                    }
                }
                .buttonStyle(.compound(.primary))
                .disabled(true)
            }
            
            if shouldShowSkipButton {
                Button("\(L10n.actionSkip) 🙉") {
                    context.send(viewAction: .skip)
                }
                .buttonStyle(.compound(.tertiary))
            }
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
    static var viewModel = makeViewModel()
    static var loadingViewModel = makeViewModel(recoveryState: .unknown)
    
    static var previews: some View {
        NavigationStack {
            IdentityConfirmationScreen(context: viewModel.context)
        }
        .previewDisplayName("Actions")
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.availableActions).map { actions in
            actions?.contains([.interactiveVerification, .recovery]) == true
        })
        
        NavigationStack {
            IdentityConfirmationScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
    }
    
    static func makeViewModel(recoveryState: SecureBackupRecoveryState = .enabled) -> IdentityConfirmationScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.sessionSecurityStatePublisher = CurrentValuePublisher<SessionSecurityState, Never>(.init(verificationState: .unverified, recoveryState: recoveryState))
        
        return IdentityConfirmationScreenViewModel(userSession: userSession,
                                                   appSettings: ServiceLocator.shared.settings,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
