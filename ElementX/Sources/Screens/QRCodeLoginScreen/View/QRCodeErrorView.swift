//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct QRCodeErrorView: View {
    let errorState: QRCodeLoginState.ErrorState
    let canSignInManually: Bool
    
    enum Action { case openSettings, startOver, signInManually, dismiss }
    let action: (Action) -> Void
    
    var title: String {
        switch errorState {
        case .noCameraPermission:
            L10n.screenQrCodeLoginNoCameraPermissionStateTitle
        case .connectionNotSecure:
            L10n.screenQrCodeLoginConnectionNoteSecureStateTitle
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
        case .deviceAlreadySignedIn:
            L10n.screenQrCodeLoginErrorDeviceAlreadySignedInTitle
        case .unknown:
            L10n.commonSomethingWentWrong
        }
    }
    
    var subtitle: String {
        switch errorState {
        case .noCameraPermission:
            L10n.screenQrCodeLoginNoCameraPermissionStateDescription(InfoPlistReader.main.productionAppName)
        case .connectionNotSecure:
            L10n.screenQrCodeLoginConnectionNoteSecureStateDescription
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
        case .deviceAlreadySignedIn:
            L10n.screenQrCodeLoginErrorDeviceAlreadySignedInSubtitle
        case .unknown:
            L10n.screenQrCodeLoginUnknownErrorDescription
        }
    }
    
    var icon: KeyPath<CompoundIcons, Image> {
        switch errorState {
        case .noCameraPermission: \.takePhotoSolid
        case .deviceAlreadySignedIn: \.checkCircleSolid
        default: \.errorSolid
        }
    }
    
    var iconStyle: BigIcon.Style {
        switch errorState {
        case .noCameraPermission: .defaultSolid
        case .deviceAlreadySignedIn: .successSolid
        default: .alertSolid
        }
    }
    
    var body: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            mainContent
        } bottomContent: {
            buttons
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch errorState {
        case .connectionNotSecure:
            VStack(spacing: 40) {
                header
                
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
            header
        }
    }
    
    var header: some View {
        TitleAndIcon(title: title,
                     subtitle: subtitle,
                     icon: icon,
                     iconStyle: iconStyle)
    }
    
    @ViewBuilder
    private var buttons: some View {
        switch errorState {
        case .noCameraPermission:
            Button(L10n.screenQrCodeLoginNoCameraPermissionButton) {
                action(.openSettings)
            }
            .buttonStyle(.compound(.primary))
        case .connectionNotSecure, .unknown, .expired, .declined, .deviceNotSupported:
            Button(L10n.screenQrCodeLoginStartOverButton) {
                action(.startOver)
            }
            .buttonStyle(.compound(.primary))
        case .cancelled:
            Button(L10n.actionTryAgain) {
                action(.startOver)
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
                    action(.dismiss)
                }
                .buttonStyle(.compound(.tertiary))
            }
        case .deviceAlreadySignedIn:
            Button(L10n.actionContinue) {
                action(.dismiss)
            }
            .buttonStyle(.compound(.primary))
        }
    }
}

// MARK: - Previews

struct QRCodeErrorView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ForEach(QRCodeLoginState.ErrorState.allCases, id: \.self) { errorState in
            NavigationStack {
                QRCodeErrorView(errorState: errorState, canSignInManually: true) { _ in }
                    .toolbar(.visible, for: .navigationBar)
            }
            .previewDisplayName(errorState.previewDisplayName)
        }
        
        NavigationStack {
            QRCodeErrorView(errorState: .linkingNotSupported, canSignInManually: false) { _ in }
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Linking unsupported restricted flow")
    }
}

private extension QRCodeLoginState.ErrorState {
    var previewDisplayName: String {
        switch self {
        case .noCameraPermission: "No Camera Permission"
        case .connectionNotSecure: "Connection not secure"
        case .linkingNotSupported: "Linking unsupported"
        case .cancelled: "Cancelled"
        case .declined: "Declined"
        case .expired: "Expired"
        case .deviceNotSupported: "Device not supported"
        case .deviceAlreadySignedIn: "Device already signed in"
        case .unknown: "Unknown error"
        }
    }
}
