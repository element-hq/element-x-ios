//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Compound
import SwiftUI

struct ResolveVerifiedUserSendFailureScreen: View {
    @ObservedObject var context: ResolveVerifiedUserSendFailureScreenViewModel.Context
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
            HeroImage(icon: \.error, style: .critical)
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
                    .padding(.vertical, 14)
            }
            .buttonStyle(.compound(.plain))
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
                                                      itemID: .random,
                                                      roomProxy: JoinedRoomProxyMock(.init()))
    }
}

struct ResolveVerifiedUserSendFailureScreenSheet_Previews: PreviewProvider {
    static let viewModel = ResolveVerifiedUserSendFailureScreenViewModel(failure: .changedIdentity(users: ["@alice:matrix.org"]),
                                                                         itemID: .random,
                                                                         roomProxy: JoinedRoomProxyMock(.init()))
    
    static var previews: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                ResolveVerifiedUserSendFailureScreen(context: viewModel.context)
            }
            .previewDisplayName("Sheet")
    }
}
