//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

struct HomeScreenRecoveryKeyConfirmationBanner: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Text(L10n.confirmRecoveryKeyBannerTitle)
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
                Text(L10n.confirmRecoveryKeyBannerMessage)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }
            
            Button(L10n.actionContinue) {
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
        HomeScreenRecoveryKeyConfirmationBanner(context: viewModel.context)
    }
    
    static func buildViewModel() -> HomeScreenViewModel {
        let clientProxy = MockClientProxy(userID: "@alice:example.com",
                                          roomSummaryProvider: MockRoomSummaryProvider(state: .loading))
        
        let userSession = MockUserSession(clientProxy: clientProxy,
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        
        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
