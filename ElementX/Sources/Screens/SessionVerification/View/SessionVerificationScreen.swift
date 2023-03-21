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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    screenHeader
                    Spacer()
                    mainContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .frame(maxWidth: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
            }
            .background(Color.element.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { actionButtons.padding() }
        }
        .interactiveDismissDisabled() // Make sure dismissal goes through the state machine(s).
    }
    
    // MARK: - Private
    
    private var headerImageName: String {
        switch context.viewState.verificationState {
        case .initial:
            return "macbook.and.iphone"
        case .cancelled:
            return "exclamationmark.shield"
        case .requestingVerification:
            return "hourglass"
        case .verificationRequestAccepted:
            return "face.smiling"
        case .startingSasVerification:
            return "hourglass"
        case .sasVerificationStarted:
            return "hourglass"
        case .cancelling:
            return "hourglass"
        case .acceptingChallenge:
            return "hourglass"
        case .decliningChallenge:
            return "hourglass"
        case .showingChallenge:
            return "face.smiling"
        case .verified:
            return "checkmark.shield"
        }
    }
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            AuthenticationIconImage(image: Image(systemName: headerImageName))
                .padding(.bottom, 16)
            
            Text(context.viewState.title ?? "")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.element.primaryContent)
                .padding(.bottom, 8)

            Text(context.viewState.message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.tertiaryContent)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch context.viewState.verificationState {
        case .showingChallenge(let emojis):
            emojisPanel(with: emojis)
        case .acceptingChallenge(let emojis):
            emojisPanel(with: emojis)
        case .requestingVerification:
            ProgressView()
                .tint(.element.secondaryContent)
                .scaleEffect(2)
        default:
            // In All other cases, we just want an empty view
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func emojisPanel(with emojis: [SessionVerificationEmoji]) -> some View {
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
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch context.viewState.verificationState {
        case .initial:
            Button(ElementL10n.startVerification) {
                context.send(viewAction: .requestVerification)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.requestVerification)
        
        case .cancelled:
            Button(ElementL10n.globalRetry) {
                context.send(viewAction: .restart)
            }
            .buttonStyle(.elementAction(.xLarge))
            
        case .verificationRequestAccepted:
            Button(ElementL10n.sessionVerificationStart) {
                context.send(viewAction: .startSasVerification)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.startSasVerification)
        
        case .showingChallenge:
            VStack(spacing: 30) {
                Button { context.send(viewAction: .accept) } label: {
                    Label(L10n.commonTheyMatch, systemImage: "checkmark")
                }
                .buttonStyle(.elementAction(.xLarge))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptChallenge)
                
                Button(L10n.commonTheyDontMatch) {
                    context.send(viewAction: .decline)
                }
                .font(.element.bodyBold)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.declineChallenge)
            }
            
        case .acceptingChallenge:
            VStack(spacing: 30) {
                Button { context.send(viewAction: .accept) } label: {
                    HStack(spacing: 16) {
                        ProgressView()
                            .tint(.element.background)
                        Label(L10n.commonTheyMatch, systemImage: "checkmark")
                    }
                }
                .buttonStyle(.elementAction(.xLarge))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptChallenge)
                .disabled(true)

                Button(L10n.commonTheyDontMatch) {
                    context.send(viewAction: .decline)
                }
                .font(.element.bodyBold)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.declineChallenge)
                .disabled(true)
            }

        default:
            EmptyView()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .close)
            }
            .foregroundColor(.element.accent)
            .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.close)
        }
    }
    
    struct EmojiView: View {
        let emoji: SessionVerificationEmoji
        
        var body: some View {
            VStack(spacing: 16.0) {
                Text(emoji.symbol)
                    .font(.element.largeTitleBold)
                Text(emoji.description)
                    .font(.element.subheadline)
                    .foregroundColor(.element.secondaryContent)
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
        sessionVerificationScreen(state: .initial)
            .previewDisplayName("Initial")
        sessionVerificationScreen(state: .requestingVerification)
            .previewDisplayName("Requesting Verification")
        sessionVerificationScreen(state: .verificationRequestAccepted)
            .previewDisplayName("Request Accepted")
        sessionVerificationScreen(state: .cancelled)
            .previewDisplayName("Cancelled")
        
        sessionVerificationScreen(state: .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
            .previewDisplayName("Showing Challenge")
        sessionVerificationScreen(state: .verified)
            .previewDisplayName("Verified")
    }
    
    static func sessionVerificationScreen(state: SessionVerificationStateMachine.State) -> some View {
        let viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: SessionVerificationControllerProxyMock.configureMock(),
                                                     initialState: SessionVerificationViewState(verificationState: state))
        
        return SessionVerificationScreen(context: viewModel.context)
    }
}
