//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LinkNewDeviceScreen: View {
    @Bindable var context: LinkNewDeviceScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            mainContent
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgSubtleSecondary)
        .navigationTitle(L10n.commonLinkNewDevice)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.mode {
        case .loading, .readyToLink:
            TitleAndIcon(title: L10n.screenLinkNewDeviceRootTitle,
                         icon: \.computer,
                         iconStyle: .default)
        case .notSupported:
            TitleAndIcon(title: L10n.screenLinkNewDeviceErrorNotSupportedTitle,
                         subtitle: L10n.screenLinkNewDeviceErrorNotSupportedSubtitle,
                         icon: \.errorSolid,
                         iconStyle: .alertSolid)
        }
    }
    
    @ViewBuilder
    var buttons: some View {
        switch context.viewState.mode {
        case .loading:
            Button { } label: {
                Label {
                    Text(L10n.commonLoading)
                } icon: {
                    ProgressView()
                        .tint(.compound.iconOnSolidPrimary)
                }
            }
            .buttonStyle(.compound(.primary))
            .disabled(true)
        case .readyToLink(let isGeneratingCode):
            VStack(spacing: 16) {
                Button { context.send(viewAction: .linkMobileDevice) } label: {
                    Label {
                        Text(isGeneratingCode ? L10n.screenLinkNewDeviceRootLoadingQrCode : L10n.screenLinkNewDeviceRootMobileDevice)
                    } icon: {
                        if isGeneratingCode {
                            ProgressView()
                                .tint(.compound.iconOnSolidPrimary)
                        } else {
                            CompoundIcon(\.mobile)
                        }
                    }
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.linkNewDeviceScreen.mobileDevice)
                
                if context.viewState.showLinkDesktopComputerButton {
                    Button { context.send(viewAction: .linkDesktopComputer) } label: {
                        Label(L10n.screenLinkNewDeviceRootDesktopComputer, icon: \.computer)
                    }
                    .buttonStyle(.compound(.primary))
                    .accessibilityIdentifier(A11yIdentifiers.linkNewDeviceScreen.desktopComputer)
                }
            }
            .disabled(isGeneratingCode)
        case .notSupported:
            Button(L10n.actionDismiss) {
                context.send(viewAction: .dismiss)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .dismiss)
            }
            .accessibilityIdentifier(A11yIdentifiers.linkNewDeviceScreen.cancel)
        }
    }
}

// MARK: - Previews

struct LinkNewDeviceScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel(mode: .readyToLink(isGeneratingCode: false))
    static let generatingViewModel = makeViewModel(mode: .readyToLink(isGeneratingCode: true))
    static let loadingViewModel = makeViewModel(mode: .loading)
    static let unsupportedViewModel = makeViewModel(mode: .notSupported)
    
    static var previews: some View {
        NavigationStack {
            LinkNewDeviceScreen(context: viewModel.context)
        }
        .previewDisplayName("Ready")
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.mode).map { $0 == .readyToLink(isGeneratingCode: false) })
        
        NavigationStack {
            LinkNewDeviceScreen(context: generatingViewModel.context)
        }
        .previewDisplayName("Generating")
        .snapshotPreferences(expect: generatingViewModel.context.observe(\.viewState.mode).map { $0 == .readyToLink(isGeneratingCode: true) })
        
        NavigationStack {
            LinkNewDeviceScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
        
        NavigationStack {
            LinkNewDeviceScreen(context: unsupportedViewModel.context)
        }
        .previewDisplayName("Unsupported")
        .snapshotPreferences(expect: unsupportedViewModel.context.observe(\.viewState.mode).map { $0 == .notSupported })
    }
    
    static func makeViewModel(mode: LinkNewDeviceScreenViewState.Mode) -> LinkNewDeviceScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.isLoginWithQRCodeSupportedClosure = {
            switch mode {
            case .loading:
                try? await Task.sleep(for: .seconds(20))
                return false
            case .readyToLink:
                return true
            case .notSupported:
                return false
            }
        }
        
        let viewModel = LinkNewDeviceScreenViewModel(clientProxy: clientProxy)
        
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            if case .readyToLink(isGeneratingCode: true) = mode {
                viewModel.context.send(viewAction: .linkMobileDevice)
            }
        }
        
        return viewModel
    }
}
