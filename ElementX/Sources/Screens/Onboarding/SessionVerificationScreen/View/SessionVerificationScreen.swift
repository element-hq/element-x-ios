//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

struct SessionVerificationScreen: View {
    @ObservedObject var context: SessionVerificationScreenViewModel.Context
    @ScaledMetric private var iconSize = 30.0
    
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
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            if context.viewState.verificationState == .initial {
                BigIcon(icon: \.lockSolid)
                    .padding(.bottom, 16)
            default:
                Image(systemName: headerImageName)
                    .bigIcon()
                    .padding(.bottom, 16)
            }

            Text(title ?? "")
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)
                .accessibilityIdentifier(titleAccessibilityIdentifier)

            Text(message)
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
            case .responder(let details):
                requestDetails(details)
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
    
    private let outerShape = RoundedRectangle(cornerRadius: 8)
    private func requestDetails(_ details: SessionVerificationRequestDetails) -> some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    CompoundIcon(\.devices)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(.compound.iconSecondary)
                        .padding(6)
                        .background(.compound.bgSubtleSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(details.displayName ?? details.senderId)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.screenSessionVerificationRequestDetailsTimestamp)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                        Text(details.firstSeenDate.formattedMinimal())
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.commonDeviceId)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                        Text(details.deviceId)
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                    }
                }
            }
            .padding(24)
            .clipShape(outerShape)
            .overlay {
                outerShape
                    .inset(by: 0.25)
                    .stroke(.compound.borderDisabled)
            }
            
            Text(L10n.screenSessionVerificationRequestFooter)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
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
            switch context.viewState.flow {
            case .initiator:
                Button(L10n.actionStartVerification) {
                    context.send(viewAction: .requestVerification)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.requestVerification)
            case .responder:
                VStack(spacing: 16) {
                    Button(L10n.actionStart) {
                        context.send(viewAction: .acceptVerificationRequest)
                    }
                    .buttonStyle(.compound(.primary))
                    .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptVerificationRequest)
                    
                    Button(L10n.actionIgnore) {
                        context.send(viewAction: .ignoreVerificationRequest)
                    }
                    .buttonStyle(.compound(.plain))
                    .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.ignoreVerificationRequest)
                }
            }
        case .cancelled:
            switch context.viewState.flow {
            case .initiator:
                Button(L10n.actionRetry) {
                    context.send(viewAction: .restart)
                }
                .buttonStyle(.compound(.primary))
            case .responder:
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
            VStack(spacing: 32) {
                Button(L10n.screenSessionVerificationTheyMatch) {
                    context.send(viewAction: .accept)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.acceptChallenge)
                
                Button(L10n.screenSessionVerificationTheyDontMatch) {
                    context.send(viewAction: .decline)
                }
                .buttonStyle(.compound(.plain))
                .accessibilityIdentifier(A11yIdentifiers.sessionVerificationScreen.declineChallenge)
            }
            
        case .acceptingVerificationRequest, .acceptingChallenge, .decliningChallenge, .requestingVerification:
            Button(L10n.screenIdentityWaitingOnOtherDevice) { }
                .buttonStyle(.compound(.primary))
                .disabled(true)

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
    
    private var headerImageName: String {
        switch context.viewState.verificationState {
        case .initial:
            return "lock"
        case .acceptingVerificationRequest:
            return "hourglass"
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
        case .cancelled:
            return "exclamationmark.shield"
        }
    }
    
    private var title: String? {
        switch context.viewState.verificationState {
        case .initial:
            switch context.viewState.flow {
            case .initiator:
                return L10n.screenSessionVerificationOpenExistingSessionTitle
            case .responder:
                return L10n.screenSessionVerificationRequestTitle
            }
        case .acceptingVerificationRequest:
            return L10n.screenSessionVerificationRequestTitle
        case .requestingVerification:
            return L10n.screenSessionVerificationWaitingToAcceptTitle
        case .verificationRequestAccepted:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .startingSasVerification:
            return nil
        case .sasVerificationStarted:
            return nil
        case .showingChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .acceptingChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .decliningChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .verified:
            return L10n.commonVerificationComplete
        case .cancelling:
            return nil
        case .cancelled:
            return L10n.commonVerificationFailed
        }
    }
    
    private var titleAccessibilityIdentifier: String {
        context.viewState.verificationState == .verified ? A11yIdentifiers.sessionVerificationScreen.verificationComplete : ""
    }
        
    private var message: String {
        switch context.viewState.verificationState {
        case .initial:
            switch context.viewState.flow {
            case .initiator:
                return L10n.screenSessionVerificationOpenExistingSessionSubtitle
            case .responder:
                return L10n.screenSessionVerificationRequestSubtitle
            }
        case .acceptingVerificationRequest:
            return L10n.screenSessionVerificationRequestSubtitle
        case .requestingVerification:
            return L10n.screenSessionVerificationWaitingToAcceptSubtitle
        case .verificationRequestAccepted:
            return L10n.screenSessionVerificationRequestAcceptedSubtitle
        case .startingSasVerification:
            return L10n.commonWaiting
        case .sasVerificationStarted:
            return L10n.commonWaiting
        case .acceptingChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .decliningChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .cancelling:
            return L10n.commonWaiting
        case .showingChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .verified:
            return L10n.screenSessionVerificationCompleteSubtitle
        case .cancelled:
            return L10n.screenSessionVerificationFailedSubtitle
        }
    }
}

extension SessionVerificationRequestDetails {
    var firstSeenDate: Date {
        Date(timeIntervalSince1970: TimeInterval(firstSeenTimestamp / 1000))
    }
}

struct SessionVerification_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        sessionVerificationScreen(state: .initial)
            .previewDisplayName("Initial - Initiator")
        
        let details = SessionVerificationRequestDetails(senderId: "@bob:matrix.org",
                                                        flowId: "123",
                                                        deviceId: "CODEMISTAKE",
                                                        displayName: "Bob's Element X iOS",
                                                        firstSeenTimestamp: 0)
        sessionVerificationScreen(state: .initial, flow: .responder(details: details))
            .previewDisplayName("Initial - Responder")
        
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
                                          flow: SessionVerificationScreenFlow = .initiator) -> some View {
        let viewModel = SessionVerificationScreenViewModel(sessionVerificationControllerProxy: SessionVerificationControllerProxyMock.configureMock(),
                                                           flow: flow,
                                                           verificationState: state)
        
        return SessionVerificationScreen(context: viewModel.context)
    }
}
