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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                screenHeader
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) { actionButtons.padding() }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            HeroImage(icon: \.lockSolid)
                .padding(.bottom, 16)
            
            #warning("FIXME")
            Text("Confirm that it's you")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)

            #warning("FIXME")
            Text("Verify this device to set up secure messaging.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
            
            Button {
                UIApplication.shared.open("https://element.io/help#encryption")
            } label: {
                Text(L10n.actionLearnMore)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .padding(.top, 16)
            }
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
        
        return IdentityConfirmationScreenViewModel(userSession: userSession)
    }
}
