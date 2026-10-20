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
    
    @State private var navigationBarHeight: CGFloat = .zero
    @State private var contentHeight: CGFloat = .zero
    @State private var buttonsHeight: CGFloat = .zero
    
    private let topPadding = UIConstants.titleTopPaddingToNavigationBar
    private let spacing = 16.0
    
    private var mode: SecureBackupLogoutConfirmationScreenViewMode {
        context.viewState.mode
    }
    
    /// The height of the sheet when it is only as tall as its content, which is how the question is shown.
    private var fittedSheetHeight: CGFloat {
        navigationBarHeight + topPadding + contentHeight + spacing + buttonsHeight + UIConstants.actionButtonBottomPadding
    }
    
    var body: some View {
        FullscreenDialog(topPadding: topPadding, spacing: spacing) {
            if mode.isInitial {
                initialContent
            } else {
                progressContent
            }
        } bottomContent: {
            if mode.isInitial {
                initialButtons
            } else {
                progressButtons
            }
        }
        .toolbar { toolbar }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { navigationBarHeight = $0 }
        .presentationDetents(mode.isInitial ? [.height(fittedSheetHeight)] : [.large])
        .alert(item: $context.alertInfo)
    }
    
    // MARK: - Initial
    
    private var initialContent: some View {
        Group {
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
        .padding(.horizontal, 8)
        .readHeight($contentHeight)
    }
    
    private var initialButtons: some View {
        VStack(spacing: 16) {
            switch mode {
            case .noRecovery:
                Button(L10n.actionSignoutAnyway, role: .destructive) {
                    context.send(viewAction: .logout)
                }
                .buttonStyle(.compound(.tertiary))
            default:
                Button(UntranslatedL10n.screenSignoutSaveRecoveryKeyActionContinue, role: .destructive) {
                    context.send(viewAction: .logout)
                }
                .buttonStyle(.compound(.primary))
            }
        }
        .readHeight($buttonsHeight)
    }
    
    // MARK: - Progress
    
    /// What is shown while waiting for the keys to be backed up before removing the device.
    private var progressContent: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.keyOffSolid)
            progressDetails
        }
        .padding()
    }
    
    @ViewBuilder
    private var progressDetails: some View {
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
    
    private var progressButtons: some View {
        VStack(spacing: 16.0) {
            Button(role: .destructive) {
                context.send(viewAction: .logout)
            } label: {
                Text(L10n.actionSignout)
            }
            .buttonStyle(.compound(.primary))
        }
        .padding()
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
