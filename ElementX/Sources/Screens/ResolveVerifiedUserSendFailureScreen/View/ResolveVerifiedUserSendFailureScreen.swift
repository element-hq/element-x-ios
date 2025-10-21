//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ResolveVerifiedUserSendFailureScreen: View {
    let context: ResolveVerifiedUserSendFailureScreenViewModel.Context
    @State private var sheetFrame: CGRect = .zero
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                header
                buttons
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .padding(.horizontal, 16)
            .readFrame($sheetFrame)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.height(sheetFrame.height)])
    }
    
    var header: some View {
        VStack(spacing: 8) {
            BigIcon(icon: \.errorSolid, style: .alertSolid)
                .padding(.bottom, 8)
            
            Text(context.viewState.title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(context.viewState.subtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button(context.viewState.primaryButtonTitle) {
                context.send(viewAction: .resolveAndResend)
            }
            .buttonStyle(.compound(.primary))
            
            Button(L10n.actionRetry) {
                context.send(viewAction: .resend)
            }
            .buttonStyle(.compound(.secondary))
            
            Button { context.send(viewAction: .cancel) } label: {
                Text(L10n.actionCancelForNow)
            }
            .buttonStyle(.compound(.tertiary))
        }
    }
}

// MARK: - Previews

struct ResolveVerifiedUserSendFailureScreen_Previews: PreviewProvider, TestablePreview {
    static let unsignedDeviceViewModel = makeViewModel(failure: .hasUnsignedDevice(devices: ["@alice:matrix.org": []]))
    static let ownUnsignedDeviceViewModel = makeViewModel(failure: .hasUnsignedDevice(devices: [RoomMemberProxyMock.mockMe.userID: []]))
    static let changedIdentityViewModel = makeViewModel(failure: .changedIdentity(users: ["@alice:matrix.org"]))
    
    static var previews: some View {
        ResolveVerifiedUserSendFailureScreen(context: unsignedDeviceViewModel.context)
            .previewDisplayName("Unsigned Device")
        
        ResolveVerifiedUserSendFailureScreen(context: ownUnsignedDeviceViewModel.context)
            .previewDisplayName("Own Unsigned Device")
        
        ResolveVerifiedUserSendFailureScreen(context: changedIdentityViewModel.context)
            .previewDisplayName("Identity Changed")
    }
    
    static func makeViewModel(failure: TimelineItemSendFailure.VerifiedUser) -> ResolveVerifiedUserSendFailureScreenViewModel {
        ResolveVerifiedUserSendFailureScreenViewModel(failure: failure,
                                                      sendHandle: .mock,
                                                      roomProxy: JoinedRoomProxyMock(.init()),
                                                      userIndicatorController: UserIndicatorControllerMock())
    }
}

struct ResolveVerifiedUserSendFailureScreenSheet_Previews: PreviewProvider {
    static let viewModel = ResolveVerifiedUserSendFailureScreenViewModel(failure: .changedIdentity(users: ["@alice:matrix.org"]),
                                                                         sendHandle: .mock,
                                                                         roomProxy: JoinedRoomProxyMock(.init()),
                                                                         userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                ResolveVerifiedUserSendFailureScreen(context: viewModel.context)
            }
            .previewDisplayName("Sheet")
    }
}
