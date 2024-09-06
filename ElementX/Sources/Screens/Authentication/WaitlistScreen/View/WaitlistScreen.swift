//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct WaitlistScreen: View {
    @ObservedObject var context: WaitlistScreenViewModel.Context
    
    var body: some View {
        WaitingDialog {
            content
        } bottomContent: {
            buttons
        }
        .navigationBarBackButtonHidden()
        .toolbar { toolbar }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var content: some View {
        VStack(spacing: 16) {
            Text(context.viewState.title.tinting(".", color: Asset.Colors.brandColor.swiftUIColor))
                .font(.compound.headingXLBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(context.viewState.message)
                .font(.compound.bodyLG)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    @ViewBuilder
    var buttons: some View {
        if let userSession = context.viewState.userSession {
            Button { context.send(viewAction: .continue(userSession)) } label: {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if context.viewState.isWaiting {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct WaitlistScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
    static let successViewModel = {
        let viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
        viewModel.update(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@alice:matrix.org")))))
        return viewModel
    }()
    
    static var previews: some View {
        NavigationStack {
            WaitlistScreen(context: viewModel.context)
        }
        .previewDisplayName("Waiting")
        
        NavigationStack {
            WaitlistScreen(context: successViewModel.context)
        }
        .previewDisplayName("Success")
    }
}
