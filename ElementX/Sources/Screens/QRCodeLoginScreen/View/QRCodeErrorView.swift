//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct QRCodeErrorView: View {
    let errorState: QRCodeLoginState.ErrorState
    let canSignInManually: Bool
    
    enum Action { case openSettings, startScan, signInManually, cancel }
    let action: (Action) -> Void
    
    var body: some View {
        FullscreenDialog {
            header
        } bottomContent: {
            footer
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var header: some View {
        switch errorState {
        case .noCameraPermission:
            VStack(spacing: 16) {
                BigIcon(icon: \.takePhotoSolid, style: .default)
                
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
                    BigIcon(icon: \.errorSolid, style: .alert)
                    
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
                    
                    SFNumberedListView(items: [
                        AttributedString(L10n.screenQrCodeLoginConnectionNoteSecureStateListItem1),
                        AttributedString(L10n.screenQrCodeLoginConnectionNoteSecureStateListItem2),
                        AttributedString(L10n.screenQrCodeLoginConnectionNoteSecureStateListItem3)
                    ])
                }
            }
        default:
            simpleErrorStack(errorState: errorState)
        }
    }
    
    @ViewBuilder
    private func simpleErrorStack(errorState: QRCodeLoginState.ErrorState) -> some View {
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
            BigIcon(icon: \.errorSolid, style: .alert)
            
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
    private var footer: some View {
        switch errorState {
        case .noCameraPermission:
            Button(L10n.screenQrCodeLoginNoCameraPermissionButton) {
                action(.openSettings)
            }
            .buttonStyle(.compound(.primary))
        case .connectionNotSecure, .unknown, .expired, .declined, .deviceNotSupported:
            Button(L10n.screenQrCodeLoginStartOverButton) {
                action(.startScan)
            }
            .buttonStyle(.compound(.primary))
        case .cancelled:
            Button(L10n.actionTryAgain) {
                action(.startScan)
            }
            .buttonStyle(.compound(.primary))
        case .linkingNotSupported:
            VStack(spacing: 16) {
                if canSignInManually {
                    Button(L10n.screenOnboardingSignInManually) {
                        action(.signInManually)
                    }
                    .buttonStyle(.compound(.primary))
                }
                
                Button(L10n.actionCancel) {
                    action(.cancel)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
    }
}

// MARK: - Previews

struct QRCodeErrorView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        QRCodeErrorViewSnapshot(errorState: .noCameraPermission, canSignInManually: false)
            .previewDisplayName("No Camera Permission")
        
        QRCodeErrorViewSnapshot(errorState: .connectionNotSecure, canSignInManually: false)
            .previewDisplayName("Connection not secure")
        
        QRCodeErrorViewSnapshot(errorState: .linkingNotSupported, canSignInManually: true)
            .previewDisplayName("Linking unsupported")
        QRCodeErrorViewSnapshot(errorState: .linkingNotSupported, canSignInManually: false)
            .previewDisplayName("Linking unsupported restricted flow")
        
        QRCodeErrorViewSnapshot(errorState: .cancelled, canSignInManually: false)
            .previewDisplayName("Cancelled")
        
        QRCodeErrorViewSnapshot(errorState: .declined, canSignInManually: false)
            .previewDisplayName("Declined")
        
        QRCodeErrorViewSnapshot(errorState: .expired, canSignInManually: false)
            .previewDisplayName("Expired")
        
        QRCodeErrorViewSnapshot(errorState: .deviceNotSupported, canSignInManually: false)
            .previewDisplayName("Device not supported")
        
        QRCodeErrorViewSnapshot(errorState: .unknown, canSignInManually: false)
            .previewDisplayName("Unknown error")
    }
}

private struct QRCodeErrorViewSnapshot: View {
    let errorState: QRCodeLoginState.ErrorState
    let canSignInManually: Bool
    
    var body: some View {
        NavigationStack {
            QRCodeErrorView(errorState: errorState, canSignInManually: canSignInManually) { _ in }
                .toolbar(.visible, for: .navigationBar)
        }
    }
}
