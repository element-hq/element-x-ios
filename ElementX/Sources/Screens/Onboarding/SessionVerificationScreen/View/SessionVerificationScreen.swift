//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SessionVerificationScreen: View {
    @ObservedObject var context: SessionVerificationScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 32) {
                screenHeader
                Spacer()
                mainContent
            }
        } bottomContent: {
            actionButtons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Private
    
    private var headerImageName: String {
        switch context.viewState.verificationState {
        case .initial:
            return "lock"
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
            if context.viewState.verificationState == .initial {
                HeroImage(icon: \.lockSolid)
                    .padding(.bottom, 16)
            } else {
                Image(systemName: headerImageName)
                    .heroImage()
                    .padding(.bottom, 16)
            }
            
            Text(context.viewState.title ?? "")
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)
                .accessibilityIdentifier(context.viewState.titleAccessibilityIdentifier)

            Text(context.viewState.message)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch context.viewState.verificationState {
        case .showingChallenge(let emojis):
            emojisPanel(with: emojis)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.emojiWrapper)
        case .acceptingChallenge(let emojis):
            emojisPanel(with: emojis)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.emojiWrapper)
        case .requestingVerification:
            ProgressView()
                .tint(.compound.textSecondary)
                .scaleEffect(2)
        default:
            // In All other cases, we just want an empty view
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func emojisPanel(with emojis: [SessionVerificationEmoji]) -> some View {
        VStack(spacing: 32) {
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
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch context.viewState.verificationState {
        case .initial:
            VStack(spacing: 32) {
                Button(L10n.actionStartVerification) {
                    context.send(viewAction: .requestVerification)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.requestVerification)
            }
        case .cancelled:
            Button(L10n.actionRetry) {
                context.send(viewAction: .restart)
            }
            .buttonStyle(.compound(.primary))
            
        case .verificationRequestAccepted:
            Button(L10n.actionStart) {
                context.send(viewAction: .startSasVerification)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.startSasVerification)
        
        case .showingChallenge:
            VStack(spacing: 32) {
                Button(L10n.screenSessionVerificationTheyMatch) {
                    context.send(viewAction: .accept)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptChallenge)
                
                Button(L10n.screenSessionVerificationTheyDontMatch) {
                    context.send(viewAction: .decline)
                }
                .font(.compound.bodyLGSemibold)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.declineChallenge)
            }
            
        case .acceptingChallenge:
            VStack(spacing: 32) {
                Button { context.send(viewAction: .accept) } label: {
                    HStack(spacing: 16) {
                        ProgressView()
                            .tint(.compound.textOnSolidPrimary)
                        Text(L10n.screenSessionVerificationTheyMatch)
                    }
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptChallenge)
                .disabled(true)

                Button(L10n.screenSessionVerificationTheyDontMatch) {
                    context.send(viewAction: .decline)
                }
                .font(.compound.bodyLGSemibold)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.declineChallenge)
                .disabled(true)
            }

        default:
            EmptyView()
        }
    }
    
    struct EmojiView: View {
        let emoji: SessionVerificationEmoji
        
        var body: some View {
            VStack(spacing: 16.0) {
                Text(emoji.symbol)
                    .font(.compound.headingXLBold)
                Text(emoji.localizedDescription)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }
            .padding(8.0)
        }
    }
}

// MARK: - Previews

struct SessionVerification_Previews: PreviewProvider, TestablePreview {
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
    
    static func sessionVerificationScreen(state: SessionVerificationScreenStateMachine.State) -> some View {
        let viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: SessionVerificationControllerProxyMock.configureMock(),
                                                           verificationState: state)
        
        return SessionVerificationScreen(context: viewModel.context)
    }
}
