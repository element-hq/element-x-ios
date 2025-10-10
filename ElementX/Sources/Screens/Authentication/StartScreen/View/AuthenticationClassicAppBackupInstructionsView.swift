//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AuthenticationClassicAppBackupInstructionsView: View {
    let context: AuthenticationStartScreenViewModel.Context
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ElementNavigationStack {
            FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
                content
            } bottomContent: {
                buttons
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .background()
            .backgroundStyle(.compound.bgSubtleSecondary)
        }
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 40) {
            TitleAndIcon(title: L10n.screenMissingKeyBackupTitle(InfoPlistReader.main.bundleDisplayName),
                         icon: \.keySolid,
                         iconStyle: .default)
            
            SFNumberedListView(items: [
                AttributedString(L10n.screenMissingKeyBackupStep1),
                AttributedString(L10n.screenMissingKeyBackupStep2Ios),
                AttributedString(L10n.screenMissingKeyBackupStep3Ios),
                AttributedString(L10n.screenMissingKeyBackupStep4),
                AttributedString(L10n.screenMissingKeyBackupStep5(InfoPlistReader.main.bundleDisplayName))
            ])
        }
    }
    
    var buttons: some View {
        Button(L10n.screenMissingKeyBackupOpenElementClassic) {
            UIApplication.shared.open("element://open")
        }
        .buttonStyle(.compound(.primary))
    }
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ToolbarButton(role: .close, action: dismiss.callAsFunction)
        }
    }
}

struct AuthenticationClassicAppBackupInstructionsView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        AuthenticationClassicAppBackupInstructionsView(context: viewModel.context)
    }
    
    static func makeViewModel() -> AuthenticationStartScreenViewModel {
        AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock,
                                           provisioningParameters: nil,
                                           isBugReportServiceEnabled: false,
                                           appSettings: ServiceLocator.shared.settings,
                                           userIndicatorController: UserIndicatorControllerMock())
    }
}
