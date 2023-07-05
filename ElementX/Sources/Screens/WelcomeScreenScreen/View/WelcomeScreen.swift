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

import SwiftUI

struct WelcomeScreen: View {
    @ObservedObject var context: WelcomeScreenScreenViewModel.Context
    
    var body: some View {
        mainContent
            .onAppear {
                context.send(viewAction: .appeared)
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        checkmarkList
    }

    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedLabelItem(title: "", listPosition: .top) {
                Text("")
            }
            RoundedLabelItem(title: "", listPosition: .middle) {
                Text("")
            }
            RoundedLabelItem(title: "", listPosition: .bottom) {
                Text("")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct WelcomeScreen_Previews: PreviewProvider {
    static let viewModel = WelcomeScreenScreenViewModel()

    static var previews: some View {
        WelcomeScreen(context: viewModel.context)
    }
}
