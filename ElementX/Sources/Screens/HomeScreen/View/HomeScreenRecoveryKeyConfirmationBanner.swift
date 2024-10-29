//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct HomeScreenRecoveryKeyConfirmationBanner: View {
    let requiresExtraAccountSetup: Bool
    var context: HomeScreenViewModel.Context
    
    var title: String { requiresExtraAccountSetup ? L10n.bannerSetUpRecoveryTitle : L10n.confirmRecoveryKeyBannerTitle }
    var message: String { requiresExtraAccountSetup ? L10n.bannerSetUpRecoveryContent : L10n.confirmRecoveryKeyBannerMessage }
    var actionTitle: String { requiresExtraAccountSetup ? L10n.bannerSetUpRecoverySubmit : L10n.actionContinue }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Text(title)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        context.send(viewAction: .skipRecoveryKeyConfirmation)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.compound.iconSecondary)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(message)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }
            
            Button(actionTitle) {
                context.send(viewAction: .confirmRecoveryKey)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.compound(.primary, size: .medium))
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.recoveryKeyConfirmationBannerContinue)
        }
        .padding(16)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
}

struct HomeScreenRecoveryKeyConfirmationBanner_Previews: PreviewProvider, TestablePreview {
    static let viewModel = buildViewModel()
    
    static var previews: some View {
        HomeScreenRecoveryKeyConfirmationBanner(requiresExtraAccountSetup: true,
                                                context: viewModel.context)
            .previewDisplayName("Set up recovery")
        HomeScreenRecoveryKeyConfirmationBanner(requiresExtraAccountSetup: false,
                                                context: viewModel.context)
            .previewDisplayName("Out of sync")
    }
    
    static func buildViewModel() -> HomeScreenViewModel {
        let clientProxy = ClientProxyMock(.init(userID: "@alice:example.com",
                                                roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loading))))
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
