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
        ScrollView {
            VStack(spacing: 32) {
                screenHeader
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) { actionButtons.padding() }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 0) {
            HeroImage(icon: \.checkCircle)
                .padding(.bottom, 16)
            
            #warning("FIXME")
            Text("Device verified")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.bottom, 8)

            #warning("FIXME")
            Text("Now you can read or send messages securely, and anyone you chat with can also trust this device.")
                .font(.subheadline)
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
