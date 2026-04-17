//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AuthenticationClassicAppBackupInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let classicAppAccount: ClassicAppAccount
    let openClassicAppAction: () -> Void
    
    private var isRefreshingSecrets: Bool {
        classicAppAccount.state.availableSecrets == nil
    }
    
    private var buttonTitle: String {
        isRefreshingSecrets ? L10n.screenOnboardingCheckingAccount : L10n.screenMissingKeyBackupOpenElementClassic
    }
    
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
                .frame(maxWidth: .infinity)
            
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
        Button(action: openClassicAppAction) {
            Label {
                Text(buttonTitle)
            } icon: {
                if isRefreshingSecrets {
                    ProgressView()
                        .tint(.compound.iconOnSolidPrimary)
                }
            }
        }
        .buttonStyle(.compound(.primary))
        .disabled(isRefreshingSecrets)
    }
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ToolbarButton(role: .close, action: dismiss.callAsFunction)
        }
    }
}

struct AuthenticationClassicAppBackupInstructionsView_Previews: PreviewProvider, TestablePreview {
    static let loadedAccount = {
        let account = ClassicAppAccount.mockDan
        account.state.availableSecrets = .requiresBackup
        return account
    }()
    
    static var previews: some View {
        AuthenticationClassicAppBackupInstructionsView(classicAppAccount: loadedAccount) { }
            .previewDisplayName("Initial")
        
        AuthenticationClassicAppBackupInstructionsView(classicAppAccount: .mockAlice) { }
            .previewDisplayName("Refreshing")
    }
}
