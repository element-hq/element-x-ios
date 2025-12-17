//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct QRCodeLoginScreen: View {
    @ObservedObject var context: QRCodeLoginScreenViewModel.Context
    @State private var qrFrame = CGRect.zero
    
    var backgroundStyle: Color {
        if case .error = context.viewState.state {
            .compound.bgCanvasDefault
        } else {
            .compound.bgSubtleSecondary
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .toolbar { toolbar }
                .toolbar(.visible, for: .navigationBar)
                .background()
                .backgroundStyle(backgroundStyle)
                .interactiveDismissDisabled()
        }
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.state {
        case .initial:
            initialContent
        case .scan:
            qrScanContent
        case .displayCode:
            displayCodeContent
        case .error(let errorState):
            QRCodeErrorView(errorState: errorState, canSignInManually: context.viewState.canSignInManually) { action in
                context.send(viewAction: .errorAction(action))
            }
        }
    }
    
    private var initialContent: some View {
        FullscreenDialog {
            VStack(alignment: .leading, spacing: 40) {
                TitleAndIcon(title: L10n.screenQrCodeLoginInitialStateTitle(InfoPlistReader.main.productionAppName),
                             subtitle: L10n.screenQrCodeLoginInitialStateSubtitle,
                             icon: \.computer,
                             iconStyle: .default)
                    .padding(.horizontal, 24)
                
                SFNumberedListView(items: context.viewState.initialStateListItems)
            }
        } bottomContent: {
            Button(L10n.screenQrCodeLoginInitialStateButtonTitle) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    @ViewBuilder
    private var displayCodeContent: some View {
        if case let .displayCode(displayCodeState) = context.viewState.state {
            FullscreenDialog {
                VStack(spacing: 32) {
                    VStack(spacing: 40) {
                        displayCodeHeader(state: displayCodeState)
                        PINTextField(pinCode: .constant(displayCodeState.code),
                                     maxLength: displayCodeState.code.count,
                                     size: .small)
                            .disabled(true)
                    }
                    VStack(spacing: 4) {
                        ProgressView()
                        Text(L10n.screenQrCodeLoginVerifyCodeLoading)
                            .foregroundColor(.compound.textSecondary)
                            .font(.compound.bodySM)
                            .multilineTextAlignment(.center)
                    }
                }
            } bottomContent: {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
                .buttonStyle(.compound(.secondary))
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func displayCodeHeader(state: QRCodeLoginState.QRCodeLoginDisplayCodeState) -> some View {
        switch state {
        case .deviceCode:
            TitleAndIcon(title: L10n.screenQrCodeLoginDeviceCodeTitle,
                         subtitle: L10n.screenQrCodeLoginDeviceCodeSubtitle,
                         icon: \.computer,
                         iconStyle: .default)
        case .verificationCode:
            TitleAndIcon(title: L10n.screenQrCodeLoginVerifyCodeTitle,
                         subtitle: L10n.screenQrCodeLoginVerifyCodeSubtitle,
                         icon: \.lock,
                         iconStyle: .default)
        }
    }
    
    private var qrScanContent: some View {
        FullscreenDialog {
            VStack(spacing: 40) {
                TitleAndIcon(title: L10n.screenQrCodeLoginScanningStateTitle,
                             icon: \.takePhotoSolid,
                             iconStyle: .default)
                
                qrScanner
            }
        } bottomContent: {
            qrScanFooter
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var qrScanFooter: some View {
        if case let .scan(scanState) = context.viewState.state {
            switch scanState {
            case .connecting:
                VStack(spacing: 4) {
                    ProgressView()
                    Text(L10n.screenQrCodeLoginConnectingSubtitle)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodySM)
                        .multilineTextAlignment(.center)
                }
            case .scanning:
                // To keep the spacing consistent between states
                Button("") { }
                    .buttonStyle(.compound(.primary))
                    .hidden()
            case .scanFailed(let error):
                VStack(spacing: 16) {
                    Button(L10n.screenQrCodeLoginInvalidScanStateRetryButton) {
                        context.send(viewAction: .startScan)
                    }
                    .buttonStyle(.compound(.primary))
                    
                    VStack(spacing: 4) {
                        Label(error.title,
                              icon: \.errorSolid,
                              iconSize: .medium,
                              relativeTo: .compound.bodyMDSemibold)
                            .labelStyle(.custom(spacing: 10))
                            .font(.compound.bodyMDSemibold)
                            .foregroundColor(.compound.textCriticalPrimary)
                        
                        Text(error.description)
                            .foregroundColor(.compound.textSecondary)
                            .font(.compound.bodySM)
                            .multilineTextAlignment(.center)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var qrScanner: some View {
        QRCodeScannerView(result: $context.qrResult, isScanning: context.viewState.state.isScanning)
            .aspectRatio(1.0, contentMode: .fill)
            .frame(maxWidth: 312)
            .readFrame($qrFrame)
            .background(.compound.bgCanvasDefault)
            .overlay(
                QRScannerViewOverlay(length: qrFrame.height)
            )
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if context.viewState.state.shouldDisplayCancelButton {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
}

private struct QRScannerViewOverlay: View {
    let length: CGFloat
    
    private let dashRatio: CGFloat = 80.0 / 312.0
    private let emptyRatio: CGFloat = 232.0 / 312.0
    private let dashPhaseRatio: CGFloat = 40.0 / 312.0
    
    private var dashLength: CGFloat {
        length * dashRatio
    }
    
    private var emptyLength: CGFloat {
        length * emptyRatio
    }
    
    private var dashPhase: CGFloat {
        length * dashPhaseRatio
    }
    
    var body: some View {
        Rectangle()
            .stroke(.compound.textPrimary, style: StrokeStyle(lineWidth: 4.0, lineCap: .square, dash: [dashLength, emptyLength], dashPhase: dashPhase))
    }
}

// MARK: - Previews

struct QRCodeLoginScreen_Previews: PreviewProvider, TestablePreview {
    // Initial
    static let initialStateViewModel = QRCodeLoginScreenViewModel.mock(state: .initial)
    
    // Scanning
    static let scanningStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanning))
    
    static let connectingStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.connecting))
    
    static let invalidStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanFailed(.invalid)))
    
    static let notAllowedStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanFailed(.notAllowed(scannedProvider: "evil.com",
                                                                                                               allowedProviders: ["example.com",
                                                                                                                                  "server.net"]))))
    
    static let deviceNotSignedInStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanFailed(.deviceNotSignedIn)))
    
    // Display Code
    static let deviceCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.deviceCode("12")))
    
    static let verificationCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.verificationCode("123456")))
    
    // Errors (no need to test them all QRCodeErrorView covers that).
    static let errorStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.declined))
    
    static var previews: some View {
        QRCodeLoginScreen(context: initialStateViewModel.context)
            .previewDisplayName("Initial")
        
        QRCodeLoginScreen(context: scanningStateViewModel.context)
            .previewDisplayName("Scanning")
        
        QRCodeLoginScreen(context: connectingStateViewModel.context)
            .previewDisplayName("Connecting")
        
        QRCodeLoginScreen(context: invalidStateViewModel.context)
            .previewDisplayName("Invalid")
        
        QRCodeLoginScreen(context: notAllowedStateViewModel.context)
            .previewDisplayName("Not allowed")
        
        QRCodeLoginScreen(context: deviceNotSignedInStateViewModel.context)
            .previewDisplayName("Device not signed in")
        
        QRCodeLoginScreen(context: deviceCodeStateViewModel.context)
            .previewDisplayName("Device code")
        
        QRCodeLoginScreen(context: verificationCodeStateViewModel.context)
            .previewDisplayName("Verification code")
        
        QRCodeLoginScreen(context: errorStateViewModel.context)
            .previewDisplayName("Error")
    }
}
