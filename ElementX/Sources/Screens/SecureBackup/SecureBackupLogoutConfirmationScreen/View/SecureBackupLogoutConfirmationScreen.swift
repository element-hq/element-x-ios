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
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupLogoutConfirmationScreen: View {
    @ObservedObject var context: SecureBackupLogoutConfirmationScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    content
                }
                .padding()
            }
            .toolbar { toolbar }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { footer.padding() }
            .alert(item: $context.alertInfo)
        }
    }
    
    @ViewBuilder
    private var header: some View {
        HeroImage(icon: \.keyOffSolid)
    }
    
    @ViewBuilder
    private var content: some View {
        Text(title)
            .foregroundColor(.compound.textPrimary)
            .font(.compound.headingMDBold)
            .multilineTextAlignment(.center)
        
        Text(subtitle)
            .foregroundColor(.compound.textSecondary)
            .font(.compound.bodyMD)
            .multilineTextAlignment(.center)
        
        if context.viewState.mode == .backupOngoing {
            Spacer()
            ProgressView()
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        if context.viewState.mode == .saveRecoveryKey {
            Button {
                context.send(viewAction: .settings)
            } label: {
                Text(L10n.commonSettings)
            }
            .buttonStyle(.compound(.primary))
        }
        
        Button(role: .destructive) {
            context.send(viewAction: .logout)
        } label: {
            Text(L10n.actionSignout)
        }
        .buttonStyle(.compound(.primary))
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
    
    var title: String {
        switch context.viewState.mode {
        case .saveRecoveryKey:
            return L10n.screenSignoutSaveRecoveryKeyTitle
        case .backupOngoing:
            return L10n.screenSignoutKeyBackupOngoingTitle
        case .offline:
            return L10n.screenSignoutKeyBackupOfflineTitle
        }
    }
    
    var subtitle: String {
        switch context.viewState.mode {
        case .saveRecoveryKey:
            return L10n.screenSignoutSaveRecoveryKeySubtitle
        case .backupOngoing:
            return L10n.screenSignoutKeyBackupOngoingSubtitle
        case .offline:
            return L10n.screenSignoutKeyBackupOfflineSubtitle
        }
    }
}

// MARK: - Previews

struct SecureBackupLogoutConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = buildViewModel()
    
    static var previews: some View {
        NavigationStack {
            SecureBackupLogoutConfirmationScreen(context: viewModel.context)
        }
    }
    
    static func buildViewModel() -> SecureBackupLogoutConfirmationScreenViewModelType {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        let networkMonitor = NetworkMonitorMock()
        networkMonitor.underlyingReachabilityPublisher = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable).asCurrentValuePublisher()
        
        return SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                             networkMonitor: networkMonitor)
    }
}
