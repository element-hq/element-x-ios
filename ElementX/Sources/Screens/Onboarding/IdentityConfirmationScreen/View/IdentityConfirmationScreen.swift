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
    @Bindable var context: IdentityConfirmationScreenViewModel.Context
    
    var shouldShowSkipButton: Bool {
        #if DEBUG
        !ProcessInfo.isRunningTests
        #else
        false
        #endif
    }
    
    var body: some View {
        FullscreenDialog {
            if context.viewState.isUnverified {
                screenHeader
            }
        } bottomContent: {
            if context.viewState.isUnverified {
                actionButtons
            }
        }
        .overlay {
            if !context.viewState.isUnverified {
                ProgressView()
            }
        }
        .toolbar { toolbar }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Private
    
    private var screenHeader: some View {
        VStack(spacing: 0) {
            TitleAndIcon(title: L10n.screenIdentityConfirmationTitle,
                         subtitle: L10n.screenIdentityConfirmationSubtitle,
                         icon: \.lockSolid,
                         iconStyle: .defaultSolid,
                         button: .init(title: L10n.actionLearnMore, action: {
                             UIApplication.shared.open(context.viewState.learnMoreURL)
                         }))
                         .padding(.horizontal, 8)
                         .padding(.bottom, 24)
            
            AccountInfoCardView(userProfile: context.viewState.userProfile,
                                mediaProvider: context.mediaProvider)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if let availableActions = context.viewState.availableActions {
                Button {
                    context.send(viewAction: .otherDevice)
                } label: {
                    Label(L10n.screenIdentityConfirmationUseAnotherDevice, icon: \.devices)
                }
                .buttonStyle(.compound(.primary))
                .disabled(!availableActions.contains(.interactiveVerification))
                
                Button(L10n.screenIdentityConfirmationUseRecoveryKey) {
                    context.send(viewAction: .recoveryKey)
                }
                .buttonStyle(.compound(.primary))
                .disabled(!availableActions.contains(.recovery))
                
                Button(L10n.screenIdentityConfirmationCannotConfirm) {
                    context.send(viewAction: .reset)
                }
                .buttonStyle(.compound(availableActions.isEmpty ? .primary : .secondary))
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
            Button(L10n.screenIdentityConfirmationSignOut) {
                context.send(viewAction: .logout)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
struct IdentityConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static var viewModel = makeViewModel()
    static var loadingViewModel = makeViewModel(recoveryState: .unknown)
    static var noOptionsViewModel = makeViewModel(recoveryState: .disabled, hasDevicesToVerifyAgainst: false)
    
    static var previews: some View {
        ElementNavigationStack {
            IdentityConfirmationScreen(context: viewModel.context)
        }
        .previewDisplayName("Actions")
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.availableActions).map { actions in
            actions?.contains([.interactiveVerification, .recovery]) == true
        })
        
        ElementNavigationStack {
            IdentityConfirmationScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
        
        ElementNavigationStack {
            IdentityConfirmationScreen(context: noOptionsViewModel.context)
        }
        .previewDisplayName("No options")
        .snapshotPreferences(expect: noOptionsViewModel.context.observe(\.viewState.availableActions).map { $0 != nil })
    }
    
    static func makeViewModel(recoveryState: SecureBackupRecoveryState = .enabled,
                              hasDevicesToVerifyAgainst: Bool = true) -> IdentityConfirmationScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.hasDevicesToVerifyAgainstReturnValue = .success(hasDevicesToVerifyAgainst)
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.sessionSecurityStatePublisher = CurrentValuePublisher<SessionSecurityState, Never>(.init(verificationState: .unverified, recoveryState: recoveryState))
        
        return IdentityConfirmationScreenViewModel(userSession: userSession, userSettings: .mock())
    }
}
