//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupLogoutConfirmationScreen: View {
    @Bindable var context: SecureBackupLogoutConfirmationScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 16) {
                BigIcon(icon: \.keyOffSolid)
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
        
        if case let .waitingToStart(hasStalled) = context.viewState.mode {
            Spacer()
            ProgressView()
            
            if hasStalled {
                Text(L10n.commonPleaseCheckInternetConnection)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textPrimary)
            }
        } else if case let .backupOngoing(progress) = context.viewState.mode {
            Spacer()
            ProgressView(value: progress)
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 16.0) {
            if case .saveRecoveryKey = context.viewState.mode {
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
        case .waitingToStart, .backupOngoing:
            return L10n.screenSignoutKeyBackupOngoingTitle
        case .offline:
            return L10n.screenSignoutKeyBackupOfflineTitle
        }
    }
    
    private var subtitle: String {
        switch context.viewState.mode {
        case .saveRecoveryKey:
            return L10n.screenSignoutSaveRecoveryKeySubtitle
        case .waitingToStart, .backupOngoing:
            return L10n.screenSignoutKeyBackupOngoingSubtitle
        case .offline:
            return L10n.screenSignoutKeyBackupOfflineSubtitle
        }
    }
}

// MARK: - Previews

struct SecureBackupLogoutConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(mode: .saveRecoveryKey)
    static let waitingViewModel = makeViewModel(mode: .waitingToStart(hasStalled: false))
    static let ongoingViewModel = makeViewModel(mode: .backupOngoing(progress: 0.5))
    static let offlineViewModel = makeViewModel(mode: .offline)
    
    static var previews: some View {
        NavigationStack {
            SecureBackupLogoutConfirmationScreen(context: viewModel.context)
        }
        .previewDisplayName("Confirmation")
        
        NavigationStack {
            SecureBackupLogoutConfirmationScreen(context: waitingViewModel.context)
        }
        .previewDisplayName("Waiting")
        .snapshotPreferences(expect: waitingViewModel.context.observe(\.viewState.mode).map { $0 == .waitingToStart(hasStalled: false) })
        
        NavigationStack {
            SecureBackupLogoutConfirmationScreen(context: ongoingViewModel.context)
        }
        .previewDisplayName("Ongoing")
        .snapshotPreferences(expect: ongoingViewModel.context.observe(\.viewState.mode).map { $0 == .backupOngoing(progress: 0.5) })
        
        // Uses the same view model as Waiting but with a different expectation.
        NavigationStack {
            SecureBackupLogoutConfirmationScreen(context: waitingViewModel.context)
        }
        .previewDisplayName("Stalled")
        .snapshotPreferences(expect: waitingViewModel.context.observe(\.viewState.mode).map { $0 == .waitingToStart(hasStalled: true) })
        
        NavigationStack {
            SecureBackupLogoutConfirmationScreen(context: offlineViewModel.context)
        }
        .previewDisplayName("Offline")
        .snapshotPreferences(expect: offlineViewModel.context.observe(\.viewState.mode).map { $0 == .offline })
    }
    
    static func makeViewModel(mode: SecureBackupLogoutConfirmationScreenViewMode) -> SecureBackupLogoutConfirmationScreenViewModel {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { uploadStateSubject in
            if case .backupOngoing = mode {
                uploadStateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
            }
            
            return .success(())
        }
        
        let reachability: NetworkMonitorReachability = mode == .offline ? .unreachable : .reachable
        
        let viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                      homeserverReachabilityPublisher: .init(reachability))
        
        if mode != .saveRecoveryKey {
            viewModel.context.send(viewAction: .logout)
        }
        
        return viewModel
    }
}
