//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

struct SessionVerificationScreen: View {
    enum AccessibilityFocus {
        case title
    }
    
    @ObservedObject var context: SessionVerificationScreenViewModel.Context
    @AccessibilityFocusState private var accessibilityFocus: AccessibilityFocus?
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 32) {
                screenHeader
                mainContent
            }
        } bottomContent: {
            actionButtons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
        .navigationBarBackButtonHidden(context.viewState.verificationState == .verified)
        .toolbar { toolbar }
        .onAppear {
            var announcement = AttributedString(L10n.a11ySessionVerificationTimeLimitedActionRequired)
            announcement.accessibilitySpeechAnnouncementPriority = .high
            AccessibilityNotification.Announcement(announcement).post()
        }
    }
    
    // MARK: - Private
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            switch context.viewState.flow {
            case .userInitiator, .userResponder:
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            default:
                EmptyView()
            }
        }
    }
    
    private var screenHeader: some View {
        VStack(spacing: 0) {
            BigIcon(icon: context.viewState.headerIcon.keyPath,
                    style: context.viewState.headerIcon.style)
                .padding(.bottom, 16)
            
            Text(context.viewState.title ?? "")
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)
                .accessibilityIdentifier(context.viewState.titleAccessibilityIdentifier)
                .onChange(of: context.viewState.title) { _, _ in
                    accessibilityFocus = .title
                }
                .accessibilityFocused($accessibilityFocus, equals: .title)

            Text(context.viewState.message)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch context.viewState.verificationState {
        case .initial:
            switch context.viewState.flow {
            case .deviceResponder(let details):
                SessionVerificationRequestDetailsView(details: details,
                                                      isUserVerification: false,
                                                      mediaProvider: context.mediaProvider)
            case .userResponder(let details):
                SessionVerificationRequestDetailsView(details: details,
                                                      isUserVerification: true,
                                                      mediaProvider: context.mediaProvider)
            case .userInitiator:
                Button(L10n.actionLearnMore) {
                    UIApplication.shared.open(context.viewState.learnMoreURL)
                }
                .buttonStyle(.compound(.tertiary, size: .small))
            default:
                EmptyView()
            }
            
        case .showingChallenge(let emojis), .acceptingChallenge(let emojis), .decliningChallenge(let emojis):
            emojisPanel(with: emojis)
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.emojiWrapper)
        default:
            EmptyView()
        }
    }
    
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
            switch context.viewState.flow {
            case .deviceInitiator, .userInitiator:
                Button(L10n.actionStartVerification) {
                    context.send(viewAction: .requestVerification)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.requestVerification)
            case .deviceResponder, .userResponder:
                VStack(spacing: 16) {
                    Button(L10n.actionStartVerification) {
                        context.send(viewAction: .acceptVerificationRequest)
                    }
                    .buttonStyle(.compound(.primary))
                    .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptVerificationRequest)
                    
                    Button(L10n.actionIgnore) {
                        context.send(viewAction: .ignoreVerificationRequest)
                    }
                    .buttonStyle(.compound(.tertiary))
                    .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.ignoreVerificationRequest)
                }
            }
        case .cancelled:
            switch context.viewState.flow {
            case .deviceInitiator, .userInitiator:
                Button(L10n.actionRetry) {
                    context.send(viewAction: .restart)
                }
                .buttonStyle(.compound(.primary))
            case .deviceResponder, .userResponder:
                Button(L10n.actionDone) {
                    context.send(viewAction: .done)
                }
                .buttonStyle(.compound(.primary))
            }
            
        case .verificationRequestAccepted:
            Button(L10n.actionStart) {
                context.send(viewAction: .startSasVerification)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.startSasVerification)
        
        case .showingChallenge:
            VStack(spacing: 16) {
                Button(L10n.screenSessionVerificationTheyMatch) {
                    context.send(viewAction: .accept)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptChallenge)
                
                Button(L10n.screenSessionVerificationTheyDontMatch) {
                    context.send(viewAction: .decline)
                }
                .buttonStyle(.compound(.tertiary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.declineChallenge)
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
                    .accessibilityHidden(true)
                Text(emoji.localizedDescription.capitalized)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .padding(8.0)
        }
    }
}

struct SessionVerification_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        sessionVerificationScreen(state: .initial, flow: .deviceInitiator)
            .previewDisplayName("Initial - Device Initiator")
        
        sessionVerificationScreen(state: .initial, flow: .userInitiator(userID: "@bob:matrix.org"))
            .previewDisplayName("Initial - User Initiator")
        
        let details = SessionVerificationRequestDetails(senderProfile: UserProfileProxy(userID: "@bob:matrix.org",
                                                                                        displayName: "Billy Bob",
                                                                                        avatarURL: .mockMXCUserAvatar),
                                                        flowID: "123",
                                                        deviceID: "CODEMISTAKE",
                                                        deviceDisplayName: "Bob's Element X iOS",
                                                        firstSeenDate: .init(timeIntervalSince1970: 0))
        
        sessionVerificationScreen(state: .initial, flow: .deviceResponder(requestDetails: details))
            .previewDisplayName("Initial - Device Responder")
        
        sessionVerificationScreen(state: .initial, flow: .userResponder(requestDetails: details))
            .previewDisplayName("Initial - User Responder")
        
        sessionVerificationScreen(state: .acceptingVerificationRequest)
            .previewDisplayName("Accepting Verification Request")
        
        sessionVerificationScreen(state: .requestingVerification)
            .previewDisplayName("Requesting Verification")
        sessionVerificationScreen(state: .verificationRequestAccepted)
            .previewDisplayName("Request Accepted")
        
        sessionVerificationScreen(state: .startingSasVerification)
            .previewDisplayName("Starting SAS Verification")
        sessionVerificationScreen(state: .sasVerificationStarted)
            .previewDisplayName("SAS Verification started")
        
        sessionVerificationScreen(state: .showingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
            .previewDisplayName("Showing Challenge")
        sessionVerificationScreen(state: .acceptingChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
            .previewDisplayName("Accepting Challenge")
        sessionVerificationScreen(state: .decliningChallenge(emojis: SessionVerificationControllerProxyMock.emojis))
            .previewDisplayName("Declining Challenge")
        
        sessionVerificationScreen(state: .verified)
            .previewDisplayName("Verified")
        
        sessionVerificationScreen(state: .cancelled)
            .previewDisplayName("Cancelled")
    }
    
    static func sessionVerificationScreen(state: SessionVerificationScreenStateMachine.State,
                                          flow: SessionVerificationScreenFlow = .deviceInitiator) -> some View {
        let viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: SessionVerificationControllerProxyMock.configureMock(),
                                                           flow: flow,
                                                           appSettings: AppSettings(),
                                                           mediaProvider: MediaProviderMock(configuration: .init()),
                                                           verificationState: state)
        
        return SessionVerificationScreen(context: viewModel.context)
    }
}
