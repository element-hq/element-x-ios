// 
// Copyright 2021 New Vector Ltd
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

import SwiftUI
import MatrixRustSDK

struct SessionVerification: View {
    
    @ObservedObject var context: SessionVerificationViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32.0) {
                Text(heading)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                switch context.viewState.verificationState {
                case .initial:
                    icon("lock.shield")
                    Button(ElementL10n.startVerification) {
                        context.send(viewAction: .start)
                    }
                    .buttonStyle(.elementAction(.regular))
                
                case .cancelled:
                    icon("xmark.shield")
                    
                    Button(ElementL10n.globalRetry) {
                        context.send(viewAction: .restart)
                    }
                    .buttonStyle(.elementAction(.regular))
                    
                case .requestingVerification:
                    ProgressView()
                case .cancelling:
                    ProgressView()
                case .acceptingChallenge:
                    ProgressView()
                case .decliningChallenge:
                    ProgressView()
                
                case .showingChallenge(let emojis):
                    HStack(spacing: 8.0) {
                        ForEach(emojis.prefix(4)) { emoji in
                            emojiView(emoji)
                        }
                    }
                    HStack(spacing: 8.0) {
                        ForEach(emojis.suffix(from: 4)) { emoji in
                            emojiView(emoji)
                        }
                    }
                    
                    actionButtons
                case .verified:
                    icon("checkmark.shield")
                }
                
                Spacer()
            }
            .padding()
            .padding(.top, 64)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(ElementL10n.verificationVerifyDevice)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if shouldShowDismissButton {
                        Button(ElementL10n.actionDismiss) {
                            context.send(viewAction: .dismiss)
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    if !shouldShowDismissButton {
                        Button(ElementL10n.actionCancel) {
                            context.send(viewAction: .cancel)
                        }
                    }
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
    
    private var shouldShowDismissButton: Bool {
        context.viewState.verificationState == .initial ||
        context.viewState.verificationState == .verified ||
        context.viewState.verificationState == .cancelled
    }
        
    private func icon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .foregroundColor(.element.accent)
            .frame(width: 100, height: 100)
    }
    
    private func emojiView(_ emoji: SessionVerificationEmoji) -> some View {
        VStack(spacing: 16.0) {
            Text(emoji.symbol)
                .font(.largeTitle)
            Text(emoji.description)
                .font(.body)
        }
        .padding(8.0)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16.0) {
            Button(ElementL10n.verificationSasDoNotMatch) {
                context.send(viewAction: .decline)
            }
            .tint(.red)
            .buttonStyle(.borderedProminent)
            
            Button(ElementL10n.verificationSasMatch) {
                context.send(viewAction: .approve)
            }
            .buttonStyle(.borderedProminent)
            .tint(.element.accent)
        }
        .padding(32.0)
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
            
            let emojis = [SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
                          SessionVerificationEmoji(symbol: "🐘", description: "Elephant"),
                          SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
                          SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
                          SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
                          SessionVerificationEmoji(symbol: "🏁", description: "Flag"),
                          SessionVerificationEmoji(symbol: "🌏", description: "Globe")]
             
            sessionVerificationScreen(state: .showingChallenge(emojis: emojis))
            sessionVerificationScreen(state: .verified)
        }
    }

    static func sessionVerificationScreen(state: SessionVerificationStateMachine.State) -> some View {
        let viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: MockSessionVerificationControllerProxy(),
                                                     initialState: SessionVerificationViewState(verificationState: state))

        return SessionVerification(context: viewModel.context)
    }
}
