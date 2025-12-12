//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LinkNewDeviceQRCodeScreen: View {
    @ObservedObject var context: LinkNewDeviceQRCodeScreenViewModel.Context
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
            .navigationBarBackButtonHidden(!context.viewState.state.shouldDisplayBackButton)
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.state {
        case .scanInstructions:
            scanInstructionsContent
        case .scan:
            qrScanContent
        case .displayQR:
            qrShowContent
        case .checkCode:
            checkCodeContent
        case .checkCodeInvalid:
            checkCodeContent
        case .displayCode:
            displayCodeContent
        case .error(let errorState):
            QRCodeErrorView(errorState: errorState, canSignInManually: false) { action in
                switch action {
                case .openSettings:
                    context.send(viewAction: .openSettings)
                case .startScan:
                    context.send(viewAction: .startScan)
                case .signInManually:
                    break
                case .cancel:
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
    
    private var scanInstructionsContent: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            VStack(alignment: .leading, spacing: 40) {
                TitleAndIcon(title: L10n.screenQrCodeLoginInitialStateTitle(InfoPlistReader.main.productionAppName),
                             subtitle: L10n.screenQrCodeLoginInitialStateSubtitle,
                             icon: \.computer,
                             iconStyle: .default)
                
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
                    context.send(viewAction: .cancel)
                }
                .buttonStyle(.compound(.secondary))
            }
        }
    }
    
    @ViewBuilder
    private var checkCodeContent: some View {
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
                    
                    PINTextField(pinCode: $context.checkCodeInput, maxLength: 2,
                                 size: .medium)
                        .focused($checkCodeInputFocus)
                    
                    #warning("Investigate this further")
                    if case .checkCodeInvalid = context.viewState.state {
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
            Button(L10n.actionContinue) {
                context.send(viewAction: .checkCodeInput)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.checkCodeInput.count < 2)
        }
        .onAppear { checkCodeInputFocus = true }
    }
    
    @ViewBuilder
    private var qrShowContent: some View {
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
                    
                    SFNumberedListView(items: context.viewState.showQRCodeListItems)
                }
            } bottomContent: { }
        }
    }
    
    private func displayCodeHeader(state: LinkNewDeviceQRCodeState.LinkNewDeviceQRCodeDisplayCodeState) -> some View {
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
        FullscreenDialog(topPadding: 24) {
            VStack(spacing: 40) {
                TitleAndIcon(title: L10n.screenQrCodeLoginScanningStateTitle,
                             icon: \.takePhotoSolid,
                             iconStyle: .default)
                
                qrScanner
            }
        } bottomContent: {
            qrScanFooter
        }
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

struct LinkNewDeviceQRCodeScreen_Previews: PreviewProvider, TestablePreview {
    // Scanning
    static let scanningStateViewModel = LinkNewDeviceQRCodeScreenViewModel.mock(state: .scan(.scanning))
    
    static let connectingStateViewModel = LinkNewDeviceQRCodeScreenViewModel.mock(state: .scan(.connecting))
    
    static let invalidStateViewModel = LinkNewDeviceQRCodeScreenViewModel.mock(state: .scan(.scanFailed(.invalid)))
    
    // Display Code
    static let deviceCodeStateViewModel = LinkNewDeviceQRCodeScreenViewModel.mock(state: .displayCode(.deviceCode("12")))
    
    static let verificationCodeStateViewModel = LinkNewDeviceQRCodeScreenViewModel.mock(state: .displayCode(.verificationCode("123456")))
    
    // Errors (no need to test them all QRCodeErrorView covers that).
    static let errorStateViewModel = LinkNewDeviceQRCodeScreenViewModel.mock(state: .error(.deviceAlreadySignedIn))
    
    static var previews: some View {
        LinkNewDeviceQRCodeScreen(context: scanningStateViewModel.context)
            .previewDisplayName("Scanning")
        
        LinkNewDeviceQRCodeScreen(context: connectingStateViewModel.context)
            .previewDisplayName("Connecting")
        
        LinkNewDeviceQRCodeScreen(context: invalidStateViewModel.context)
            .previewDisplayName("Invalid")
        
        LinkNewDeviceQRCodeScreen(context: deviceCodeStateViewModel.context)
            .previewDisplayName("Device code")
        
        LinkNewDeviceQRCodeScreen(context: verificationCodeStateViewModel.context)
            .previewDisplayName("Verification code")
        
        LinkNewDeviceQRCodeScreen(context: errorStateViewModel.context)
            .previewDisplayName("Error")
    }
}
