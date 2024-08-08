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

struct PinnedEventsTimelineScreen: View {
    @ObservedObject var context: PinnedEventsTimelineScreenViewModel.Context
    
    var body: some View {
        content
            .navigationTitle(context.viewState.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .background(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        // TODO: Implement switching between empty state and timeline
        VStack(spacing: 16) {
            HeroImage(icon: \.pin, style: .normal)
            Text(L10n.screenPinnedTimelineEmptyStateHeadline)
                .font(.compound.headingSMSemibold)
                .foregroundStyle(.compound.textPrimary)
                .multilineTextAlignment(.center)
            Text(L10n.screenPinnedTimelineEmptyStateDescription(L10n.actionPin))
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.top, 48)
        .padding(.horizontal, 16)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionClose) {
                context.send(viewAction: .close)
            }
        }
    }
}

// MARK: - Previews

struct PinnedEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PinnedEventsTimelineScreenViewModel()
    static var previews: some View {
        NavigationStack {
            PinnedEventsTimelineScreen(context: viewModel.context)
        }
    }
}
