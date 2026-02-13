//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct LinkNewDeviceScreen: View {
    @Bindable var context: LinkNewDeviceScreenViewModel.Context
    
    var body: some View {
        switch context.viewState.mode {
        case .error(let errorState):
            QRCodeErrorView(errorState: errorState, canSignInManually: false) { action in
                context.send(viewAction: .errorAction(action))
            }
            .backgroundStyle(.compound.bgCanvasDefault)
        default:
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
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.mode {
        case .loading, .readyToLink:
            TitleAndIcon(title: L10n.screenLinkNewDeviceRootTitle,
                         icon: \.computer,
                         iconStyle: .default)
        case .error:
            EmptyView() // Not reachable.
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
        case .error:
            EmptyView() // Not reachable.
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
    static let unsupportedViewModel = makeViewModel(mode: .error(.notSupported))
    static let unknownErrorViewModel = makeViewModel(mode: .error(.unknown))
    
    static var previews: some View {
        ElementNavigationStack {
            LinkNewDeviceScreen(context: viewModel.context)
        }
        .previewDisplayName("Ready")
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.mode).map { $0 == .readyToLink(isGeneratingCode: false) })
        
        ElementNavigationStack {
            LinkNewDeviceScreen(context: generatingViewModel.context)
        }
        .previewDisplayName("Generating")
        .snapshotPreferences(expect: generatingViewModel.context.observe(\.viewState.mode).map { $0 == .readyToLink(isGeneratingCode: true) })
        
        ElementNavigationStack {
            LinkNewDeviceScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
        
        ElementNavigationStack {
            LinkNewDeviceScreen(context: unsupportedViewModel.context)
        }
        .previewDisplayName("Unsupported")
        .snapshotPreferences(expect: unsupportedViewModel.context.observe(\.viewState.mode).map { $0 == .error(.notSupported) })
        
        ElementNavigationStack {
            LinkNewDeviceScreen(context: unknownErrorViewModel.context)
        }
        .previewDisplayName("Unknown error")
        .snapshotPreferences(expect: unknownErrorViewModel.context.observe(\.viewState.mode).map { $0 == .error(.unknown) })
    }
    
    static func makeViewModel(mode: LinkNewDeviceScreenViewState.Mode) -> LinkNewDeviceScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.isLoginWithQRCodeSupportedClosure = {
            switch mode {
            case .loading:
                try? await Task.sleep(for: .seconds(20))
                return false
            case .error(.notSupported):
                return false
            case .readyToLink, .error:
                return true
            }
        }
        
        let linkMobileProgressSubject = CurrentValueSubject<LinkNewDeviceService.LinkMobileProgress, QRCodeLoginError>(.starting)
        clientProxy.linkNewDeviceServiceReturnValue = LinkNewDeviceServiceMock(.init(linkMobileProgressPublisher: linkMobileProgressSubject.asCurrentValuePublisher()))
        
        let viewModel = LinkNewDeviceScreenViewModel(clientProxy: clientProxy)
        
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            if case .readyToLink(isGeneratingCode: true) = mode {
                viewModel.context.send(viewAction: .linkMobileDevice)
            } else if case .error = mode {
                viewModel.context.send(viewAction: .linkMobileDevice)
                linkMobileProgressSubject.send(completion: .failure(.unknown))
            }
        }
        
        return viewModel
    }
}
