//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct JoinRoomByAddressView: View {
    @ObservedObject var context: StartChatScreenViewModel.Context
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var sheetHeight: CGFloat = .zero
    @FocusState private var textFieldFocus
    private let topPadding: CGFloat = 22
    
    private var footerText: String {
        switch context.viewState.joinByAddressState {
        case .example:
            L10n.screenStartChatJoinRoomByAddressSupportingText
        case .addressNotFound:
            L10n.screenStartChatJoinRoomByAddressRoomNotFound
        case .addressFound:
            L10n.screenStartChatJoinRoomByAddressRoomFound
        case .invalidAddress:
            L10n.screenStartChatJoinRoomByAddressInvalidAddress
        }
    }
    
    private var textFieldState: ElementTextFieldStyle.State {
        switch context.viewState.joinByAddressState {
        case .addressFound:
            .success
        case .example:
            .default
        case .addressNotFound, .invalidAddress:
            .error
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField(L10n.screenStartChatJoinRoomByAddressPlaceholder,
                          text: $context.roomAddress)
                    .textFieldStyle(.element(labelText: L10n.screenStartChatJoinRoomByAddressAction,
                                             footerText: footerText,
                                             state: textFieldState))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    .focused($textFieldFocus)
                    .onChange(of: context.roomAddress) { _, newValue in
                        context.roomAddress = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                
                Button(L10n.actionContinue) {
                    context.send(viewAction: .joinRoomByAddress)
                }
                .buttonStyle(.compound(.primary))
            }
            .padding(.horizontal, 16)
            .readHeight($sheetHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, topPadding) // For the drag indicator
        .presentationDetents([.height(sheetHeight + topPadding)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.compound.bgCanvasDefault)
        .onAppear {
            textFieldFocus = true
        }
    }
}

struct JoinRoomByAddressView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        let userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        return StartChatScreenViewModel(userSession: userSession,
                                        analytics: ServiceLocator.shared.analytics,
                                        userIndicatorController: UserIndicatorControllerMock(),
                                        userDiscoveryService: userDiscoveryService,
                                        appSettings: ServiceLocator.shared.settings)
    }()
    
    static var previews: some View {
        JoinRoomByAddressView(context: viewModel.context)
    }
}
