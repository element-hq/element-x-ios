//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        VStack(spacing: 32) {
            switch context.viewState.mode {
            case .recoveryOnly:
                Button(L10n.screenSessionVerificationEnterRecoveryKey) {
                    context.send(viewAction: .recoveryKey)
                }
                .buttonStyle(.compound(.primary))
                
            case .recoveryAndVerification:
                Button(L10n.actionStartVerification) {
                    context.send(viewAction: .otherDevice)
                }
                .buttonStyle(.compound(.primary))
                
                Button(L10n.screenSessionVerificationEnterRecoveryKey) {
                    context.send(viewAction: .recoveryKey)
                }
                .buttonStyle(.compound(.plain))
            }
            
            if shouldShowSkipButton {
                Button(L10n.actionSkip) {
                    context.send(viewAction: .skip)
                }
                .buttonStyle(.compound(.plain))
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
    }
    
    private static var viewModel: IdentityConfirmationScreenViewModel {
        let userSession = MockUserSession(clientProxy: ClientProxyMock(.init(userID: "@user:example.com",
                                                                             roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([]))))),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        
        return IdentityConfirmationScreenViewModel(userSession: userSession,
                                                   appSettings: ServiceLocator.shared.settings,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
