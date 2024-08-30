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
struct ResolveVerifiedUserSendFailureView: View {
    @StateObject var viewState: ResolveVerifiedUserSendFailureViewState
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
            
            Text(viewState.title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(viewState.subtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button(viewState.primaryButtonTitle) {
                viewState.resolveAndSend()
            }
            .buttonStyle(.compound(.primary))
            
            Button(L10n.actionRetry) {
                viewState.retry()
            }
            .buttonStyle(.compound(.secondary))
            
            Button { viewState.cancel() } label: {
                Text(UntranslatedL10n.actionCancelForNow)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.compound(.plain))
        }
    }
}

// MARK: - Previews

struct TimelineSendFailureInfoView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        ResolveVerifiedUserSendFailureView(viewState: .init(info: .init(id: .random,
                                                                        failure: .hasUnsignedDevice(devices: ["@alice:matrix.org": []])),
                                                            context: viewModel.context))
            .previewDisplayName("Unsigned Device")
        
        ResolveVerifiedUserSendFailureView(viewState: .init(info: .init(id: .random,
                                                                        failure: .changedIdentity(users: ["@alice:matrix.org"])),
                                                            context: viewModel.context))
            .previewDisplayName("Identity Changed")
    }
}

struct TimelineSendFailureInfoViewSheet_Previews: PreviewProvider {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        Text("Hello")
            .sheet(isPresented: .constant(true)) {
                ResolveVerifiedUserSendFailureView(viewState: .init(info: .init(id: .random,
                                                                                failure: .changedIdentity(users: ["@alice:matrix.org"])),
                                                                    context: viewModel.context))
            }
            .previewDisplayName("Sheet")
    }
}
