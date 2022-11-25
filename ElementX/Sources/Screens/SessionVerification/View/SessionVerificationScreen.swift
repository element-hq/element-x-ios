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

import SwiftUI

struct SessionVerificationScreen: View {
    @ObservedObject var context: SessionVerificationViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32.0) {
                    if let title = context.viewState.title {
                        Text(title)
                            .font(.element.headlineBold)
                            .foregroundColor(.element.systemPrimaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text(context.viewState.message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.element.systemPrimaryLabel)
                        .accessibilityIdentifier("titleLabel")
                    
                    mainContent
                }
                .padding()
                .padding(.top, 64)
                .frame(maxWidth: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(ElementL10n.verificationProfileVerify)
                .toolbar { toolbarContent }
            }
            .background(Color.element.systemSecondaryBackground)
            .safeAreaInset(edge: .bottom) { actionButtons.padding() }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var mainContent: some View {
        switch context.viewState.verificationState {
        case .initial:
            StateIcon(systemName: "lock.shield")
            
        case .cancelled:
            StateIcon(systemName: "xmark.shield")
                .accessibilityIdentifier("sessionVerificationFailedIcon")
            
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
            HStack(spacing: 16) {
                ForEach(emojis.prefix(4), id: \.self) { emoji in
                    EmojiView(emoji: emoji)
                }
            }
            HStack(spacing: 16) {
                ForEach(emojis.suffix(from: 4), id: \.self) { emoji in
                    EmojiView(emoji: emoji)
                }
            }
        case .verified:
            StateIcon(systemName: "checkmark.shield")
                .accessibilityIdentifier("sessionVerificationSucceededIcon")
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch context.viewState.verificationState {
        case .initial:
            Button(ElementL10n.startVerification) {
                context.send(viewAction: .start)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier("startButton")
        
        case .cancelled:
            Button(ElementL10n.globalRetry) {
                context.send(viewAction: .restart)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier("restartButton")
        
        case .showingChallenge:
            VStack(spacing: 30) {
                Button { context.send(viewAction: .accept) } label: {
                    Label(ElementL10n.actionMatch, systemImage: "checkmark")
                }
                .buttonStyle(.elementAction(.xLarge))
                .accessibilityLabel("challengeAcceptButton")
                
                Button(ElementL10n.no) {
                    context.send(viewAction: .decline)
                }
                .font(.element.bodyBold)
                .accessibilityLabel("challengeDeclineButton")
            }
        
        case .verified:
            Button(ElementL10n.finish) {
                context.send(viewAction: .close)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier("finishButton")
        
        default:
            EmptyView()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .close) } label: {
                Image(systemName: "xmark")
            }
            .font(.element.bodyBold)
            .foregroundColor(.element.systemSecondaryLabel)
            .accessibilityIdentifier("closeButton")
        }
    }
    
    struct EmojiView: View {
        let emoji: SessionVerificationEmoji
        
        var body: some View {
            VStack(spacing: 16.0) {
                Text(emoji.symbol)
                    .font(.element.largeTitleBold)
                Text(emoji.description)
                    .font(.element.caption2)
                    .foregroundColor(.element.systemSecondaryLabel)
            }
            .padding(8.0)
        }
    }
    
    struct StateIcon: View {
        let systemName: String
        
        var body: some View {
            Image(systemName: systemName)
                .resizable()
                .font(.element.body.weight(.light))
                .scaledToFit()
                .foregroundColor(.element.accent)
                .frame(width: 100, height: 100)
        }
    }
}

// MARK: - Previews

struct SessionVerification_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            sessionVerificationScreen(state: .initial)
            sessionVerificationScreen(state: .requestingVerification)
            sessionVerificationScreen(state: .cancelled)
            
            sessionVerificationScreen(state: .showingChallenge(emojis: MockSessionVerificationControllerProxy.emojis))
            sessionVerificationScreen(state: .verified)
        }
        .tint(Color.element.accent)
    }
    
    static func sessionVerificationScreen(state: SessionVerificationStateMachine.State) -> some View {
        let viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: MockSessionVerificationControllerProxy(),
                                                     initialState: SessionVerificationViewState(verificationState: state))
        
        return SessionVerificationScreen(context: viewModel.context)
    }
}
