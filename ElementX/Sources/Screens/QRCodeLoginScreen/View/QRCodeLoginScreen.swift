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
    @FocusState private var checkCodeInputFocus
    
    var backgroundStyle: Color {
        if case .error = context.viewState.state {
            .compound.bgCanvasDefault
        } else {
            .compound.bgSubtleSecondary
        }
    }
    
    var body: some View {
        mainContent
            .toolbar { toolbar }
            .toolbar(.visible, for: .navigationBar)
            .background()
            .backgroundStyle(backgroundStyle)
            .interactiveDismissDisabled()
            .navigationBarBackButtonHidden(!context.viewState.shouldDisplayBackButton)
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.state {
        case .loginInstructions:
            loginInstructionsContent
        case .linkDesktopInstructions:
            linkDesktopInstructionsContent
        case .scan:
            qrScannerContent
        case .displayCode:
            displayCodeContent
        case .displayQR:
            displayQRContent
        case .confirmCode:
            confirmCodeContent
        case .error(let errorState):
            QRCodeErrorView(errorState: errorState, canSignInManually: context.viewState.canSignInManually) { action in
                context.send(viewAction: .errorAction(action))
            }
        }
    }
    
    private var loginInstructionsContent: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            VStack(alignment: .leading, spacing: 40) {
                TitleAndIcon(title: L10n.screenQrCodeLoginInitialStateTitle(InfoPlistReader.main.productionAppName),
                             subtitle: L10n.screenQrCodeLoginInitialStateSubtitle,
                             icon: \.computer,
                             iconStyle: .default)
                
                SFNumberedListView(items: context.viewState.instructions.loginItems)
            }
        } bottomContent: {
            Button(L10n.screenQrCodeLoginInitialStateButtonTitle) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    private var linkDesktopInstructionsContent: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            VStack(alignment: .leading, spacing: 40) {
                TitleAndIcon(title: L10n.screenLinkNewDeviceDesktopTitle(InfoPlistReader.main.productionAppName),
                             icon: \.computer,
                             iconStyle: .default)
                
                SFNumberedListView(items: context.viewState.instructions.linkDesktopItems)
            }
        } bottomContent: {
            Button(L10n.screenLinkNewDeviceDesktopSubmit) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    @ViewBuilder
    private var displayCodeContent: some View {
        if case let .displayCode(displayCodeState) = context.viewState.state {
            FullscreenDialog(topPadding: 24) {
                VStack(spacing: 32) {
                    VStack(spacing: 24) {
                        displayCodeHeader(state: displayCodeState)
                            .padding(.horizontal, 8)
                        
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
                    context.send(viewAction: .dismiss)
                }
                .buttonStyle(.compound(.secondary))
            }
        }
    }
    
    private func displayCodeHeader(state: QRCodeLoginState.DisplayCodeState) -> some View {
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
    
    private var qrScannerContent: some View {
        FullscreenDialog(topPadding: 24) {
            VStack(spacing: 40) {
                TitleAndIcon(title: L10n.screenQrCodeLoginScanningStateTitle,
                             icon: \.takePhotoSolid,
                             iconStyle: .default)
                
                qrScanner
            }
        } bottomContent: {
            qrScannerFooter
        }
    }
    
    @ViewBuilder
    private var qrScannerFooter: some View {
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
    
    @ViewBuilder
    private var displayQRContent: some View {
        if case let .displayQR(image) = context.viewState.state {
            FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
                VStack(spacing: 32) {
                    TitleAndIcon(title: L10n.screenLinkNewDeviceMobileTitle(InfoPlistReader.main.productionAppName),
                                 icon: \.takePhotoSolid,
                                 iconStyle: .default)
                    
                    Image(uiImage: image)
                        .interpolation(.none) // to stop it getting blurred
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    SFNumberedListView(items: context.viewState.instructions.linkMobileItems)
                }
            } bottomContent: { }
        }
    }
    
    @ViewBuilder
    private var confirmCodeContent: some View {
        if case let .confirmCode(confirmCode) = context.viewState.state {
            FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
                VStack(spacing: 24) {
                    TitleAndIcon(title: L10n.screenLinkNewDeviceEnterNumberTitle,
                                 subtitle: L10n.screenLinkNewDeviceEnterNumberSubtitle,
                                 icon: \.computer,
                                 iconStyle: .default)
                    
                    VStack(spacing: 10) {
                        Text(L10n.screenLinkNewDeviceEnterNumberNotice)
                            .font(.compound.bodyMDSemibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.compound.textSecondary)
                        
                        PINTextField(pinCode: $context.checkCodeInput, maxLength: 2, size: .medium)
                            .focused($checkCodeInputFocus)
                            .disabled(confirmCode.isSending)
                        
                        if case .confirmCode(.invalidCode) = context.viewState.state {
                            Label(L10n.screenLinkNewDeviceEnterNumberErrorNumbersDoNotMatch,
                                  icon: \.errorSolid,
                                  iconSize: .medium,
                                  relativeTo: .compound.bodyMDSemibold)
                                .labelStyle(.custom(spacing: 10))
                                .font(.compound.bodyMDSemibold)
                                .foregroundColor(.compound.textCriticalPrimary)
                        }
                    }
                }
            } bottomContent: {
                switch confirmCode {
                case .inputCode, .sendingCode:
                    Button(L10n.actionContinue) {
                        context.send(viewAction: .sendCheckCode)
                    }
                    .buttonStyle(.compound(.primary))
                    .disabled(context.checkCodeInput.count < 2 || confirmCode.isSending)
                case .invalidCode:
                    Button(L10n.actionStartOver) {
                        context.send(viewAction: .errorAction(.startOver))
                    }
                    .buttonStyle(.compound(.primary))
                }
            }
            .onAppear { checkCodeInputFocus = true }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if context.viewState.shouldDisplayCancelButton {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .dismiss)
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
            .stroke(.compound.textPrimary, style: StrokeStyle(lineWidth: 6.0, lineCap: .square, dash: [dashLength, emptyLength], dashPhase: dashPhase))
    }
}

// MARK: - Previews

import MatrixRustSDKMocks

struct QRCodeLoginScreen_Previews: PreviewProvider, TestablePreview {
    // Instructions
    static let loginInstructionsStateViewModel = QRCodeLoginScreenViewModel.mock(state: .loginInstructions)
    static let linkInstructionsStateViewModel = QRCodeLoginScreenViewModel.mock(state: .linkDesktopInstructions)
    
    // Scanning
    static let scanningStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanning))
    
    static let connectingStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.connecting))
    
    static let invalidStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanFailed(.invalid)))
    
    static let notAllowedStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanFailed(.notAllowed(scannedProvider: "evil.com",
                                                                                                               allowedProviders: ["example.com",
                                                                                                                                  "server.net"]))))
    
    static let deviceNotSignedInStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanFailed(.deviceNotSignedIn)))
    
    // Showing
    static let showingStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayQR(LinkNewDeviceServiceMock.mockQRCodeImage))
    
    // Displaying codes
    static let deviceCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.deviceCode("12")))
    static let verificationCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.verificationCode("123456")))
    
    static let confirmCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .confirmCode(.inputCode(CheckCodeSenderProxy(underlyingSender: CheckCodeSenderSDKMock()))))
    static let confirmCodeEnteredStateViewModel = QRCodeLoginScreenViewModel.mock(state: .confirmCode(.inputCode(CheckCodeSenderProxy(underlyingSender: CheckCodeSenderSDKMock()))), checkCodeInput: "12")
    static let confirmCodeInvalidStateViewModel = QRCodeLoginScreenViewModel.mock(state: .confirmCode(.invalidCode))
    
    // Errors (no need to test them all QRCodeErrorView covers that).
    static let errorStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.declined))
    
    static var previews: some View {
        NavigationStack { QRCodeLoginScreen(context: loginInstructionsStateViewModel.context) }
            .previewDisplayName("Login instructions")
        NavigationStack { QRCodeLoginScreen(context: linkInstructionsStateViewModel.context) }
            .previewDisplayName("Link instructions")
        
        NavigationStack { QRCodeLoginScreen(context: scanningStateViewModel.context) }
            .previewDisplayName("Scanning")
        NavigationStack { QRCodeLoginScreen(context: connectingStateViewModel.context) }
            .previewDisplayName("Connecting")
        NavigationStack { QRCodeLoginScreen(context: invalidStateViewModel.context) }
            .previewDisplayName("Invalid")
        NavigationStack { QRCodeLoginScreen(context: notAllowedStateViewModel.context) }
            .previewDisplayName("Not allowed")
        NavigationStack { QRCodeLoginScreen(context: deviceNotSignedInStateViewModel.context) }
            .previewDisplayName("Device not signed in")
        
        NavigationStack { QRCodeLoginScreen(context: showingStateViewModel.context) }
            .previewDisplayName("Showing")
        
        NavigationStack { QRCodeLoginScreen(context: deviceCodeStateViewModel.context) }
            .previewDisplayName("Device code")
        NavigationStack { QRCodeLoginScreen(context: verificationCodeStateViewModel.context) }
            .previewDisplayName("Verification code")
        
        NavigationStack { QRCodeLoginScreen(context: confirmCodeStateViewModel.context) }
            .previewDisplayName("Confirm code")
        NavigationStack { QRCodeLoginScreen(context: confirmCodeEnteredStateViewModel.context) }
            .previewDisplayName("Confirm code entered")
        NavigationStack { QRCodeLoginScreen(context: confirmCodeInvalidStateViewModel.context) }
            .previewDisplayName("Confirm code invalid")
        
        NavigationStack { QRCodeLoginScreen(context: errorStateViewModel.context) }
            .previewDisplayName("Error")
    }
}
