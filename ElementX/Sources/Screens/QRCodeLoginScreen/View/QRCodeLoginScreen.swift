//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct QRCodeLoginScreen: View {
    @ObservedObject var context: QRCodeLoginScreenViewModel.Context
    @State private var qrFrame = CGRect.zero
    
    var body: some View {
        NavigationStack {
            mainContent
                .toolbar { toolbar }
                .toolbar(.visible, for: .navigationBar)
                .background()
                .backgroundStyle(.compound.bgSubtleSecondary)
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
        case .error:
            errorContent
        }
    }
    
    private var initialContent: some View {
        FullscreenDialog {
            VStack(alignment: .leading, spacing: 40) {
                VStack(spacing: 16) {
                    HeroImage(icon: \.computer, style: .subtle)
                    
                    Text(L10n.screenQrCodeLoginInitialStateTitle(InfoPlistReader.main.productionAppName))
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                }
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
        VStack(spacing: 16) {
            switch state {
            case .deviceCode:
                HeroImage(icon: \.computer, style: .subtle)
                
                VStack(spacing: 8) {
                    Text(L10n.screenQrCodeLoginDeviceCodeTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.screenQrCodeLoginDeviceCodeSubtitle)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            case .verificationCode:
                HeroImage(icon: \.lock, style: .subtle)
                
                VStack(spacing: 8) {
                    Text(L10n.screenQrCodeLoginVerifyCodeTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.screenQrCodeLoginVerifyCodeSubtitle)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var qrScanContent: some View {
        FullscreenDialog {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    HeroImage(icon: \.takePhotoSolid, style: .subtle)
                    
                    Text(L10n.screenQrCodeLoginScanningStateTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                }
                
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
            case .invalid:
                VStack(spacing: 16) {
                    Button(L10n.screenQrCodeLoginInvalidScanStateRetryButton) {
                        context.send(viewAction: .startScan)
                    }
                    .buttonStyle(.compound(.primary))
                    
                    VStack(spacing: 4) {
                        Label(L10n.screenQrCodeLoginInvalidScanStateSubtitle,
                              icon: \.error,
                              iconSize: .medium,
                              relativeTo: .compound.bodyMDSemibold)
                            .labelStyle(.custom(spacing: 10))
                            .font(.compound.bodyMDSemibold)
                            .foregroundColor(.compound.textCriticalPrimary)
                        
                        Text(L10n.screenQrCodeLoginInvalidScanStateDescription)
                            .foregroundColor(.compound.textSecondary)
                            .font(.compound.bodySM)
                            .multilineTextAlignment(.center)
                    }
                }
            case .deviceNotSignedIn:
                VStack(spacing: 16) {
                    Button(L10n.screenQrCodeLoginInvalidScanStateRetryButton) {
                        context.send(viewAction: .startScan)
                    }
                    .buttonStyle(.compound(.primary))
                    
                    VStack(spacing: 4) {
                        Label(L10n.screenQrCodeLoginDeviceNotSignedInScanStateSubtitle,
                              icon: \.error,
                              iconSize: .medium,
                              relativeTo: .compound.bodyMDSemibold)
                            .labelStyle(.custom(spacing: 10))
                            .font(.compound.bodyMDSemibold)
                            .foregroundColor(.compound.textCriticalPrimary)
                        
                        Text(L10n.screenQrCodeLoginDeviceNotSignedInScanStateDescription)
                            .foregroundColor(.compound.textSecondary)
                            .font(.compound.bodySM)
                            .multilineTextAlignment(.center)
                    }
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
        
    @ViewBuilder
    private var errorContent: some View {
        if case let .error(errorState) = context.viewState.state {
            FullscreenDialog {
                errorContentHeader(errorState: errorState)
            } bottomContent: {
                errorContentFooter(errorState: errorState)
            }
            .padding(.horizontal, 24)
        }
    }
    
    @ViewBuilder
    private func errorContentHeader(errorState: QRCodeLoginState.QRCodeLoginErrorState) -> some View {
        switch errorState {
        case .noCameraPermission:
            VStack(spacing: 16) {
                HeroImage(icon: \.takePhotoSolid, style: .subtle)
                
                VStack(spacing: 8) {
                    Text(L10n.screenQrCodeLoginNoCameraPermissionStateTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.screenQrCodeLoginNoCameraPermissionStateDescription(InfoPlistReader.main.productionAppName))
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            }
        case .connectionNotSecure:
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    HeroImage(icon: \.error, style: .criticalOnSecondary)
                    
                    VStack(spacing: 8) {
                        Text(L10n.screenQrCodeLoginConnectionNoteSecureStateTitle)
                            .foregroundColor(.compound.textPrimary)
                            .font(.compound.headingMDBold)
                            .multilineTextAlignment(.center)
                        
                        Text(L10n.screenQrCodeLoginConnectionNoteSecureStateDescription)
                            .foregroundColor(.compound.textSecondary)
                            .font(.compound.bodyMD)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 24) {
                    Text(L10n.screenQrCodeLoginConnectionNoteSecureStateListHeader)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.bodyLGSemibold)
                        .multilineTextAlignment(.center)
                    
                    SFNumberedListView(items: context.viewState.connectionNotSecureListItems)
                }
            }
        default:
            simpleErrorStack(errorState: errorState)
        }
    }
    
    @ViewBuilder
    private func simpleErrorStack(errorState: QRCodeLoginState.QRCodeLoginErrorState) -> some View {
        let title = switch errorState {
        case .cancelled:
            L10n.screenQrCodeLoginErrorCancelledTitle
        case .declined:
            L10n.screenQrCodeLoginErrorDeclinedTitle
        case .expired:
            L10n.screenQrCodeLoginErrorExpiredTitle
        case .linkingNotSupported:
            L10n.screenQrCodeLoginErrorLinkingNotSuportedTitle
        case .deviceNotSupported:
            L10n.screenQrCodeLoginErrorSlidingSyncNotSupportedTitle(InfoPlistReader.main.bundleDisplayName)
        case .unknown:
            L10n.commonSomethingWentWrong
        default:
            fatalError("This should not be displayed")
        }
        
        let subtitle: String = switch errorState {
        case .cancelled:
            L10n.screenQrCodeLoginErrorCancelledSubtitle
        case .declined:
            L10n.screenQrCodeLoginErrorDeclinedSubtitle
        case .expired:
            L10n.screenQrCodeLoginErrorExpiredSubtitle
        case .linkingNotSupported:
            L10n.screenQrCodeLoginErrorLinkingNotSuportedSubtitle(InfoPlistReader.main.bundleDisplayName)
        case .deviceNotSupported:
            L10n.screenQrCodeLoginErrorSlidingSyncNotSupportedSubtitle(InfoPlistReader.main.bundleDisplayName)
        case .unknown:
            L10n.screenQrCodeLoginUnknownErrorDescription
        default:
            fatalError("This should not be displayed")
        }
        
        VStack(spacing: 16) {
            HeroImage(icon: \.error, style: .criticalOnSecondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .foregroundColor(.compound.textPrimary)
                    .font(.compound.headingMDBold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyMD)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private func errorContentFooter(errorState: QRCodeLoginState.QRCodeLoginErrorState) -> some View {
        switch errorState {
        case .noCameraPermission:
            Button(L10n.screenQrCodeLoginNoCameraPermissionButton) {
                context.send(viewAction: .openSettings)
            }
            .buttonStyle(.compound(.primary))
        case .connectionNotSecure, .unknown, .expired, .declined, .deviceNotSupported:
            Button(L10n.screenQrCodeLoginStartOverButton) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
        case .cancelled:
            Button(L10n.actionTryAgain) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
        case .linkingNotSupported:
            VStack(spacing: 16) {
                Button(L10n.screenOnboardingSignInManually) {
                    context.send(viewAction: .signInManually)
                }
                .buttonStyle(.compound(.primary))
                
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .buttonStyle(.compound(.plain))
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
    
    static let invalidStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.invalid))
    
    static let deviceNotSignedInStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.deviceNotSignedIn))
    
    // Display Code
    static let deviceCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.deviceCode("12")))
    
    static let verificationCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.verificationCode("123456")))
    
    // Errors
    static let noCameraPermissionStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.noCameraPermission))
    
    static let connectionNotSecureStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.connectionNotSecure))
    
    static let linkingUnsupportedStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.linkingNotSupported))
    
    static let cancelledStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.cancelled))
    
    static let declinedStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.declined))
    
    static let expiredStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.expired))
    
    static let deviceNoSupportedViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.deviceNotSupported))
    
    static let unknownErrorStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.unknown))
    
    static var previews: some View {
        QRCodeLoginScreen(context: initialStateViewModel.context)
            .previewDisplayName("Initial")
        
        QRCodeLoginScreen(context: scanningStateViewModel.context)
            .previewDisplayName("Scanning")
        
        QRCodeLoginScreen(context: connectingStateViewModel.context)
            .previewDisplayName("Connecting")
        
        QRCodeLoginScreen(context: invalidStateViewModel.context)
            .previewDisplayName("Invalid")
        
        QRCodeLoginScreen(context: deviceNotSignedInStateViewModel.context)
            .previewDisplayName("Device not signed in")
        
        QRCodeLoginScreen(context: deviceCodeStateViewModel.context)
            .previewDisplayName("Device code")
        
        QRCodeLoginScreen(context: verificationCodeStateViewModel.context)
            .previewDisplayName("Verification code")
        
        QRCodeLoginScreen(context: noCameraPermissionStateViewModel.context)
            .previewDisplayName("No Camera Permission")
        
        QRCodeLoginScreen(context: connectionNotSecureStateViewModel.context)
            .previewDisplayName("Connection not secure")
        
        QRCodeLoginScreen(context: linkingUnsupportedStateViewModel.context)
            .previewDisplayName("Linking unsupported")
        
        QRCodeLoginScreen(context: cancelledStateViewModel.context)
            .previewDisplayName("Cancelled")
        
        QRCodeLoginScreen(context: declinedStateViewModel.context)
            .previewDisplayName("Declined")
        
        QRCodeLoginScreen(context: expiredStateViewModel.context)
            .previewDisplayName("Expired")
        
        QRCodeLoginScreen(context: deviceNoSupportedViewModel.context)
            .previewDisplayName("Device not supported")
        
        QRCodeLoginScreen(context: unknownErrorStateViewModel.context)
            .previewDisplayName("Unknown error")
    }
}
