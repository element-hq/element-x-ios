//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupLogoutConfirmationScreen: View {
    @ObservedObject var context: SecureBackupLogoutConfirmationScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 16) {
                HeroImage(icon: \.keyOffSolid)
                content
            }
            .padding()
        } bottomContent: {
            footer.padding()
        }
        .toolbar { toolbar }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .alert(item: $context.alertInfo)
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
        VStack(spacing: 16.0) {
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
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
    
    private var title: String {
        switch context.viewState.mode {
        case .saveRecoveryKey:
            return L10n.screenSignoutSaveRecoveryKeyTitle
        case .backupOngoing:
            return L10n.screenSignoutKeyBackupOngoingTitle
        case .offline:
            return L10n.screenSignoutKeyBackupOfflineTitle
        }
    }
    
    private var subtitle: String {
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
        
        let appMediator = AppMediatorMock()
        appMediator.underlyingNetworkMonitor = networkMonitor
        
        return SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                             appMediator: appMediator)
    }
}
