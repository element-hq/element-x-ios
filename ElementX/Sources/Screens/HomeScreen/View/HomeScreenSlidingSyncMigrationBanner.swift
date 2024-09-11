//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct HomeScreenSlidingSyncMigrationBanner: View {
    var context: HomeScreenViewModel.Context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Text(L10n.bannerMigrateToNativeSlidingSyncTitle)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        context.send(viewAction: .skipSlidingSyncUpgrade)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.compound.iconSecondary)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(L10n.bannerMigrateToNativeSlidingSyncDescription)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }
            
            Button(L10n.bannerMigrateToNativeSlidingSyncAction) {
                context.send(viewAction: .confirmSlidingSyncUpgrade)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.compound(.primary, size: .medium))
        }
        .padding(16)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
}

struct HomeScreenSlidingSyncMigrationBanner_Previews: PreviewProvider, TestablePreview {
    static let viewModel = buildViewModel()
    
    static var previews: some View {
        HomeScreenSlidingSyncMigrationBanner(context: viewModel.context)
    }
    
    static func buildViewModel() -> HomeScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
