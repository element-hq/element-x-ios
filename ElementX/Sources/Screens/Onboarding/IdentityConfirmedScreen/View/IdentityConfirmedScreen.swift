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

struct IdentityConfirmedScreen: View {
    @ObservedObject var context: IdentityConfirmedScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding) {
            screenHeader
        } bottomContent: {
            actionButtons
        }
        .background()
        .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgCanvasDefault))
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            HeroImage(icon: \.checkCircle, style: .positive)
                .padding(.bottom, 16)
            
            Text(L10n.screenIdentityConfirmedTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)

            Text(L10n.screenIdentityConfirmedSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        Button(L10n.actionContinue) {
            context.send(viewAction: .done)
        }
        .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct IdentityConfirmedScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = IdentityConfirmedScreenViewModel()
    static var previews: some View {
        NavigationStack {
            IdentityConfirmedScreen(context: viewModel.context)
        }
    }
}
