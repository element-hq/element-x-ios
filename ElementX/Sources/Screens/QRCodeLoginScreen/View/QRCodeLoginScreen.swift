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
// WITHOUT WARRANTIES OR CONnDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
            Button(L10n.actionContinue) {
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
                    
                    VStack(spacing: 0) {
                        Label(L10n.screenQrCodeLoginInvalidScanStateSubtitle, icon: \.error, iconSize: .medium, relativeTo: .compound.bodyMDSemibold)
                            .labelStyle(.custom(spacing: 10))
                            .font(.compound.bodyMDSemibold)
                            .foregroundColor(.compound.textCriticalPrimary)
                        
                        Text(L10n.screenQrCodeLoginInvalidScanStateDescription)
                            .foregroundColor(.compound.textSecondary)
                            .font(.compound.bodySM)
                    }
                }
            }
        }
    }
    
    private var qrScanner: some View {
        QRCodeScannerView(result: $context.qrResult)
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
            if !context.viewState.state.isDisplayingCode {
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
                    
                    Text(L10n.screenQrCodeLoginNoCameraPermissionStateDescription)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            }
        case .connectionNotSecure:
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    HeroImage(icon: \.error, style: .critical)
                    
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
        case .unknown:
            VStack(spacing: 16) {
                HeroImage(icon: \.error, style: .critical)
                
                VStack(spacing: 8) {
                    Text(L10n.commonSomethingWentWrong)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.screenQrCodeLoginUnknownErrorDescription)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private func errorContentFooter(errorState: QRCodeLoginState.QRCodeLoginErrorState) -> some View {
        switch errorState {
        case .noCameraPermission:
            Button(L10n.screenQrCodeLoginNoCameraPermissionButton) {
                context.send(viewAction: .openSettings)
            }
            .buttonStyle(.compound(.primary))
        case .connectionNotSecure, .unknown:
            Button(L10n.screenQrCodeLoginStartOverButton) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
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
    static let initialStateViewModel = QRCodeLoginScreenViewModel.mock(state: .initial)
    
    static let scanningStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanning))
    
    static let connectingStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.connecting))
    
    static let invalidStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.invalid))
    
    static let noCameraPermissionStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.noCameraPermission))
    
    static let connectionNotSecureStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.connectionNotSecure))
    
    static let unknownErrorStateViewModel = QRCodeLoginScreenViewModel.mock(state: .error(.unknown))
    
    static let deviceCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.deviceCode("12")))
    
    static let verificationCodeStateViewModel = QRCodeLoginScreenViewModel.mock(state: .displayCode(.verificationCode("123456")))
    
    static var previews: some View {
        QRCodeLoginScreen(context: initialStateViewModel.context)
            .previewDisplayName("Initial")
        
        QRCodeLoginScreen(context: scanningStateViewModel.context)
            .previewDisplayName("Scanning")
        
        QRCodeLoginScreen(context: connectingStateViewModel.context)
            .previewDisplayName("Connecting")
        
        QRCodeLoginScreen(context: invalidStateViewModel.context)
            .previewDisplayName("Invalid")
        
        QRCodeLoginScreen(context: noCameraPermissionStateViewModel.context)
            .previewDisplayName("No Camera Permission")
        
        QRCodeLoginScreen(context: connectionNotSecureStateViewModel.context)
            .previewDisplayName("Connection not secure")
        
        QRCodeLoginScreen(context: unknownErrorStateViewModel.context)
            .previewDisplayName("Unknown error")
        
        QRCodeLoginScreen(context: deviceCodeStateViewModel.context)
            .previewDisplayName("Device code")
        
        QRCodeLoginScreen(context: verificationCodeStateViewModel.context)
            .previewDisplayName("Verification code")
    }
}
