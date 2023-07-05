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
    @ScaledMetric var iconSize = 20
    @ObservedObject var context: WelcomeScreenScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.welcomeScreenTopPadding) {
            mainContent
        } bottomContent: {
            button
        }
        .background(OnboardingBackgroundImage())
        .environment(\.backgroundStyle, AnyShapeStyle(Color.clear))
        .onAppear {
            context.send(viewAction: .appeared)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 42) {
            header
            list
        }
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 32) {
            Image(asset: Asset.Images.launchLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 118)
                .accessibilityHidden(true)
            title
        }
    }

    @ViewBuilder
    private var title: some View {
        VStack(spacing: 12) {
            Text(context.viewState.title)
                .font(Font.compound.headingLGBold)
                .foregroundColor(Color.compound.textPrimary)
                .multilineTextAlignment(.center)
            Text(context.viewState.subtitle)
                .font(Font.compound.bodyMD)
                .foregroundColor(Color.compound.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedLabelItem(title: context.viewState.bullet1, listPosition: .top) {
                Image(systemName: "exclamationmark.transmission")
            }
            RoundedLabelItem(title: context.viewState.bullet2, listPosition: .middle) {
                Image(systemName: "lock")
            }
            RoundedLabelItem(title: context.viewState.bullet3, listPosition: .bottom) {
                Image(systemName: "plus.bubble")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var button: some View {
        Button {
            context.send(viewAction: .doneTapped)
        } label: {
            Text(context.viewState.buttonTitle)
        }
        .buttonStyle(.elementAction(.xLarge))
    }
}

// MARK: - Previews

struct WelcomeScreen_Previews: PreviewProvider {
    static let viewModel = WelcomeScreenScreenViewModel()

    static var previews: some View {
        WelcomeScreen(context: viewModel.context)
    }
}
