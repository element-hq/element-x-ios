//
// Copyright 2024 New Vector Ltd
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

import SwiftUI

@MainActor
struct ResolveTimelineItemSendFailureView: View {
    @Environment(\.dismiss) private var dismiss
    
    let info: TimelineItemSendFailureInfo
    let context: TimelineViewModel.Context
    
    private let names: String
    @State private var sheetFrame: CGRect = .zero
    
    init(info: TimelineItemSendFailureInfo, context: TimelineViewModel.Context) {
        self.info = info
        self.context = context
        
        let userIDs = info.failure.affectedUserIDs
        names = userIDs.map { context.viewState.members[$0]?.displayName ?? $0 }.formatted(.list(type: .and))
    }
    
    var title: String {
        switch info.failure {
        case .verifiedUserHasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolveTitle(names)
        case .verifiedUserChangedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolveTitle(names)
        case .unknown: ""
        }
    }
    
    var subtitle: String {
        switch info.failure {
        case .verifiedUserHasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolveSubtitle(names, names)
        case .verifiedUserChangedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolveSubtitle(names)
        case .unknown: ""
        }
    }
    
    var primaryButtonTitle: String {
        switch info.failure {
        case .verifiedUserHasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolvePrimaryButtonTitle
        case .verifiedUserChangedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolvePrimaryButtonTitle
        case .unknown: ""
        }
    }
    
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
            
            Text(title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(subtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button(primaryButtonTitle) {
                send(.resolveAndSend(info))
            }
            .buttonStyle(.compound(.primary))
            
            Button(L10n.actionRetry) {
                send(.retry(info))
            }
            .buttonStyle(.compound(.secondary))
            
            Button { send(.cancel) } label: {
                Text(UntranslatedL10n.actionCancelForNow)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.compound(.plain))
        }
    }
    
    private func send(_ action: TimelineSendFailureAction) {
        context.send(viewAction: .handleTimelineSendFailureAction(action))
        dismiss()
    }
}

// MARK: - Previews

struct TimelineSendFailureInfoView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        ResolveTimelineItemSendFailureView(info: .init(id: .random, failure: .verifiedUserHasUnsignedDevice(devices: ["@alice:matrix.org": []])),
                                           context: viewModel.context)
            .previewDisplayName("Unsigned Device")
        
        ResolveTimelineItemSendFailureView(info: .init(id: .random, failure: .verifiedUserChangedIdentity(users: ["@alice:matrix.org"])),
                                           context: viewModel.context)
            .previewDisplayName("Identity Changed")
    }
}

struct TimelineSendFailureInfoViewSheet_Previews: PreviewProvider {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                ResolveTimelineItemSendFailureView(info: .init(id: .random, failure: .verifiedUserChangedIdentity(users: ["@alice:matrix.org"])),
                                                   context: viewModel.context)
            }
            .previewDisplayName("Sheet")
    }
}
