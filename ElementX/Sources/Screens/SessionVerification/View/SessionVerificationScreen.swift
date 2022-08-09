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

import MatrixRustSDK
import SwiftUI

struct SessionVerificationScreen: View {
    @ObservedObject var context: SessionVerificationViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32.0) {
                Text(heading)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.element.primaryContent)
                    .accessibilityIdentifier("titleLabel")
                
                switch context.viewState.verificationState {
                case .initial:
                    StateIcon(systemName: "lock.shield")
                    Button(ElementL10n.startVerification) {
                        context.send(viewAction: .start)
                    }
                    .buttonStyle(.elementAction(.regular))
                    .accessibilityIdentifier("startButton")
                    
                case .cancelled:
                    StateIcon(systemName: "xmark.shield")
                        .accessibilityIdentifier("sessionVerificationFailedIcon")
                    
                    Button(ElementL10n.globalRetry) {
                        context.send(viewAction: .restart)
                    }
                    .buttonStyle(.elementAction(.regular))
                    .accessibilityIdentifier("restartButton")
                    
                case .requestingVerification:
                    ProgressView()
                        .accessibilityIdentifier("requestingVerificationProgressView")
                case .cancelling:
                    ProgressView()
                        .accessibilityIdentifier("cancellingVerificationProgressView")
                case .acceptingChallenge:
                    ProgressView()
                        .accessibilityIdentifier("acceptingChallengeProgressView")
                case .decliningChallenge:
                    ProgressView()
                        .accessibilityIdentifier("decliningChallengeProgressView")
                    
                case .showingChallenge(let emojis):
                    HStack(spacing: 8.0) {
                        ForEach(emojis.prefix(4), id: \.self) { emoji in
                            EmojiView(emoji: emoji)
                        }
                    }
                    HStack(spacing: 8.0) {
                        ForEach(emojis.suffix(from: 4), id: \.self) { emoji in
                            EmojiView(emoji: emoji)
                        }
                    }
                    
                    actionButtons
                case .verified:
                    StateIcon(systemName: "checkmark.shield")
                        .accessibilityIdentifier("sessionVerificationSucceededIcon")
                }
                
                Spacer()
            }
            .padding()
            .padding(.top, 64)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(ElementL10n.verificationVerifyDevice)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ElementL10n.done) {
                        context.send(viewAction: .dismiss)
                    }
                    .disabled(context.viewState.shouldDisableDismissButton)
                    .accessibilityIdentifier("dismissButton")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(ElementL10n.actionCancel) {
                        context.send(viewAction: .cancel)
                    }
                    .disabled(context.viewState.shouldDisableCancelButton)
                    .accessibilityIdentifier("cancelButton")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Private
    
    private var heading: String {
        switch context.viewState.verificationState {
        case .initial:
            return ElementL10n.verificationOpenOtherToVerify
        case .requestingVerification:
            return ElementL10n.verificationRequestWaiting
        case .acceptingChallenge:
            return ElementL10n.verificationRequestWaiting
        case .decliningChallenge:
            return ElementL10n.verificationRequestWaiting
        case .cancelling:
            return ElementL10n.verificationRequestWaiting
        case .showingChallenge:
            return ElementL10n.verificationEmojiNotice
        case .verified:
            return ElementL10n.verificationConclusionOkSelfNotice
        case .cancelled:
            return ElementL10n.verificationCancelled
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16.0) {
            Button(ElementL10n.verificationSasDoNotMatch) {
                context.send(viewAction: .decline)
            }
            .buttonStyle(.elementAction(.regular, color: .red))
            .accessibilityLabel("challengeDeclineButton")
            
            Button(ElementL10n.verificationSasMatch) {
                context.send(viewAction: .accept)
            }
            .buttonStyle(.elementAction(.regular))
            .accessibilityLabel("challengeAcceptButton")
        }
        .padding(32.0)
    }
    
    struct EmojiView: View {
        let emoji: SessionVerificationEmoji
        
        var body: some View {
            VStack(spacing: 16.0) {
                Text(emoji.symbol)
                    .font(.largeTitle)
                Text(emoji.description)
                    .font(.body)
            }
            .padding(8.0)
        }
    }
    
    struct StateIcon: View {
        let systemName: String
        
        var body: some View {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .foregroundColor(.element.accent)
                .frame(width: 100, height: 100)
        }
    }
}

// MARK: - Previews

struct SessionVerification_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        Group {
            sessionVerificationScreen(state: .initial)
            sessionVerificationScreen(state: .requestingVerification)
            sessionVerificationScreen(state: .cancelled)
             
            sessionVerificationScreen(state: .showingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
            sessionVerificationScreen(state: .verified)
        }
    }

    static func sessionVerificationScreen(state: SessionVerificationStateMachine.State) -> some View {
        let viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: MockSessionVerificationControllerProxy(),
                                                     initialState: SessionVerificationViewState(verificationState: state))

        return SessionVerificationScreen(context: viewModel.context)
    }
}
