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
            content
        } bottomContent: {
            buttons
        }
        .toolbar { toolbar }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { navigationBarHeight = $0 }
        .presentationDetents(mode.isInitial ? [.height(fittedSheetHeight)] : [.large])
        .alert(item: $context.alertInfo)
    }
    
    private var content: some View {
        VStack(spacing: 16) {
            TitleAndIcon(title: context.viewState.title,
                         subtitle: context.viewState.subtitle,
                         icon: context.viewState.icon.keyPath,
                         iconStyle: context.viewState.icon.style,
                         button: learnMoreButton)
                .padding(.horizontal, 8)
                .readHeight($contentHeight)
            
            backupProgress
        }
    }
    
    private var learnMoreButton: TitleAndIcon.ButtonDetails? {
        guard mode == .noRecovery else { return nil }
        return .init(title: L10n.actionLearnMore) { UIApplication.shared.open(context.viewState.learnMoreURL) }
    }
    
    @ViewBuilder
    private var backupProgress: some View {
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
    
    private var buttons: some View {
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
            case .saveRecoveryKey:
                Button(L10n.screenSignoutSaveRecoveryKeyActionContinue, role: .destructive) {
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
            case .waitingToStart, .backupOngoing, .offline:
                Button(L10n.actionSignout, role: .destructive) {
                    context.send(viewAction: .logout)
                }
                .buttonStyle(.compound(.primary))
            }
        }
        .readHeight($buttonsHeight)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .close) { context.send(viewAction: .cancel) }
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
