//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct HomeScreenRecoveryKeyConfirmationBanner: View {
    enum State { case setUpRecovery, recoveryOutOfSync }
    let state: State
    var context: HomeScreenViewModel.Context
    
    var title: String {
        switch state {
        case .setUpRecovery: L10n.bannerSetUpRecoveryTitle
        case .recoveryOutOfSync: L10n.confirmRecoveryKeyBannerTitle
        }
    }

    var message: String {
        switch state {
        case .setUpRecovery: L10n.bannerSetUpRecoveryContent
        case .recoveryOutOfSync: L10n.confirmRecoveryKeyBannerMessage
        }
    }

    var actionTitle: String {
        switch state {
        case .setUpRecovery: L10n.bannerSetUpRecoverySubmit
        case .recoveryOutOfSync: L10n.confirmRecoveryKeyBannerPrimaryButtonTitle
        }
    }

    var primaryAction: HomeScreenViewAction {
        switch state {
        case .setUpRecovery: .setupRecovery
        case .recoveryOutOfSync: .confirmRecoveryKey
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            content
            buttons
        }
        .padding(16)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(title)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if state == .setUpRecovery {
                    Button {
                        context.send(viewAction: .skipRecoveryKeyConfirmation)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.compound.iconSecondary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            
            Text(message)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button {
                context.send(viewAction: primaryAction)
            } label: {
                Text(actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.recoveryKeyConfirmationBannerContinue)
            
            if state == .recoveryOutOfSync {
                Button {
                    context.send(viewAction: .resetEncryption)
                } label: {
                    Text(L10n.confirmRecoveryKeyBannerSecondaryButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.compound(.tertiary, size: .medium))
            }
        }
    }
}

struct HomeScreenRecoveryKeyConfirmationBanner_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static var previews: some View {
        HomeScreenRecoveryKeyConfirmationBanner(state: .setUpRecovery,
                                                context: viewModel.context)
            .previewDisplayName("Set up recovery")
        HomeScreenRecoveryKeyConfirmationBanner(state: .recoveryOutOfSync,
                                                context: viewModel.context)
            .previewDisplayName("Out of sync")
    }
    
    static func makeViewModel() -> HomeScreenViewModel {
        let clientProxy = ClientProxyMock(.init(userID: "@alice:example.com",
                                                roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loading))))
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return HomeScreenViewModel(userSession: userSession,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   appSettings: ServiceLocator.shared.settings,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   notificationManager: NotificationManagerMock(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
