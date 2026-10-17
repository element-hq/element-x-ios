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
    
    @State private var contentHeight: CGFloat = .zero
    @State private var buttonsHeight: CGFloat = .zero
    
    private var mode: SecureBackupLogoutConfirmationScreenViewMode {
        context.viewState.mode
    }
    
    var body: some View {
        // The container stays the same when moving from the question to the progress, as replacing the root
        // of the screen makes the navigation stack lay it out differently on iPad.
        ZStack {
            if mode.isInitial {
                initialBody
            } else {
                progressBody
            }
        }
        .toolbar { toolbar }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .alert(item: $context.alertInfo)
    }
    
    // MARK: - Initial
    
    /// The question shown first, in a sheet that is as tall as its content.
    private var initialBody: some View {
        ScrollView {
            initialHeader
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .readHeight($contentHeight)
        }
        .backportSafeAreaBar(edge: .bottom, spacing: 0) {
            initialButtons
                .readHeight($buttonsHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.height(contentHeight + buttonsHeight + Self.navigationBarHeight)])
    }
    
    private var initialHeader: some View {
        switch mode {
        case .noRecovery:
            TitleAndIcon(title: L10n.screenSignoutRecoveryDisabledTitle,
                         subtitle: L10n.screenSignoutRecoveryDisabledSubtitle,
                         icon: \.errorSolid,
                         iconStyle: .alertSolid,
                         button: .init(title: L10n.actionLearnMore) { UIApplication.shared.open(context.viewState.learnMoreURL) })
        default:
            TitleAndIcon(title: L10n.screenSignoutSaveRecoveryKeyTitle,
                         subtitle: L10n.screenSignoutSaveRecoveryKeySubtitle,
                         icon: \.info,
                         iconStyle: .defaultSolid)
        }
    }
    
    private var initialButtons: some View {
        VStack(spacing: 16) {
            switch mode {
            case .noRecovery:
                Button {
                    context.send(viewAction: .generateRecoveryKey)
                } label: {
                    Label(L10n.screenChatBackupRecoveryActionSetup, icon: \.key)
                }
                .buttonStyle(.compound(.primary))
                
                Button(L10n.actionSignoutAnyway, role: .destructive) {
                    context.send(viewAction: .logout)
                }
                .buttonStyle(.compound(.tertiary))
            default:
                Button(UntranslatedL10n.screenSignoutSaveRecoveryKeyActionContinue, role: .destructive) {
                    context.send(viewAction: .logout)
                }
                .buttonStyle(.compound(.primary))
                
                Button(UntranslatedL10n.screenSignoutSaveRecoveryKeyActionCheck) {
                    context.send(viewAction: .checkRecoveryKey)
                }
                .buttonStyle(.compound(.secondary))
                
                Button(UntranslatedL10n.screenSignoutSaveRecoveryKeyActionGenerate) {
                    context.send(viewAction: .generateRecoveryKey)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Progress
    
    /// The screen shown while waiting for the keys to be backed up before removing the device.
    private var progressBody: some View {
        FullscreenDialog {
            VStack(spacing: 16) {
                BigIcon(icon: \.keyOffSolid)
                progressContent
            }
            .padding()
        } bottomContent: {
            progressFooter.padding()
        }
    }
    
    @ViewBuilder
    private var progressContent: some View {
        Text(progressTitle)
            .foregroundColor(.compound.textPrimary)
            .font(.compound.headingMDBold)
            .multilineTextAlignment(.center)
        
        Text(progressSubtitle)
            .foregroundColor(.compound.textSecondary)
            .font(.compound.bodyMD)
            .multilineTextAlignment(.center)
        
        if case let .waitingToStart(hasStalled) = mode {
            Spacer()
            ProgressView()
            
            if hasStalled {
                Text(L10n.commonPleaseCheckInternetConnection)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textPrimary)
            }
        } else if case let .backupOngoing(progress) = mode {
            Spacer()
            ProgressView(value: progress)
        }
    }
    
    private var progressFooter: some View {
        VStack(spacing: 16.0) {
            Button(role: .destructive) {
                context.send(viewAction: .logout)
            } label: {
                Text(L10n.actionSignout)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    private var progressTitle: String {
        switch mode {
        case .offline:
            L10n.screenSignoutKeyBackupOfflineTitle
        default:
            L10n.screenSignoutKeyBackupOngoingTitle
        }
    }
    
    private var progressSubtitle: String {
        switch mode {
        case .offline:
            L10n.screenSignoutKeyBackupOfflineSubtitle
        default:
            L10n.screenSignoutKeyBackupOngoingSubtitle
        }
    }
    
    // MARK: - Shared
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if mode.isInitial {
                ToolbarButton(role: .close) { context.send(viewAction: .cancel) }
            } else {
                Button(L10n.actionCancel) { context.send(viewAction: .cancel) }
            }
        }
    }
    
    /// The height of the navigation bar the sheet's content is shown below.
    private static let navigationBarHeight = 56.0
}

// MARK: - Previews

@available(iOS 26.0, *)
struct SecureBackupLogoutConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(mode: .saveRecoveryKey)
    static let noRecoveryViewModel = makeViewModel(mode: .noRecovery)
    static let waitingViewModel = makeViewModel(mode: .waitingToStart(hasStalled: false))
    static let ongoingViewModel = makeViewModel(mode: .backupOngoing(progress: 0.5))
    static let offlineViewModel = makeViewModel(mode: .offline)
    
    static var previews: some View {
        ElementNavigationStack {
            SecureBackupLogoutConfirmationScreen(context: viewModel.context)
        }
        .previewDisplayName("Confirmation")
        
        ElementNavigationStack {
            SecureBackupLogoutConfirmationScreen(context: noRecoveryViewModel.context)
        }
        .previewDisplayName("No recovery")
        
        ElementNavigationStack {
            SecureBackupLogoutConfirmationScreen(context: waitingViewModel.context)
        }
        .previewDisplayName("Waiting")
        .snapshotPreferences(expect: waitingViewModel.context.observe(\.viewState.mode).map { $0 == .waitingToStart(hasStalled: false) })
        
        ElementNavigationStack {
            SecureBackupLogoutConfirmationScreen(context: ongoingViewModel.context)
        }
        .previewDisplayName("Ongoing")
        .snapshotPreferences(expect: ongoingViewModel.context.observe(\.viewState.mode).map { $0 == .backupOngoing(progress: 0.5) })
        
        // Uses the same view model as Waiting but with a different expectation.
        ElementNavigationStack {
            SecureBackupLogoutConfirmationScreen(context: waitingViewModel.context)
        }
        .previewDisplayName("Stalled")
        .snapshotPreferences(expect: waitingViewModel.context.observe(\.viewState.mode).map { $0 == .waitingToStart(hasStalled: true) })
        
        ElementNavigationStack {
            SecureBackupLogoutConfirmationScreen(context: offlineViewModel.context)
        }
        .previewDisplayName("Offline")
        .snapshotPreferences(expect: offlineViewModel.context.observe(\.viewState.mode).map { $0 == .offline })
    }
    
    static func makeViewModel(mode: SecureBackupLogoutConfirmationScreenViewMode) -> SecureBackupLogoutConfirmationScreenViewModel {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.keyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { uploadStateSubject in
            if case .backupOngoing = mode {
                uploadStateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
            }
            
            return .success(())
        }
        
        let reachability: HomeserverReachability = mode == .offline ? .unreachable : .reachable
        
        // The later modes are reached by attempting to log out from the first one.
        let viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                      homeserverReachabilityPublisher: .init(reachability),
                                                                      learnMoreURL: UserSettings.mock().app.encryptionURL,
                                                                      mode: mode.isInitial ? mode : .saveRecoveryKey)
        
        if !mode.isInitial {
            viewModel.context.send(viewAction: .logout)
        }
        
        return viewModel
    }
}
