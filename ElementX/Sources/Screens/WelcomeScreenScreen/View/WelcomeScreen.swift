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
        FullscreenDialog(topPadding: UIConstants.welcomeScreenTopPadding) {
            mainContent
        } bottomContent: {
            button
        }
        .background(OnboardingScreenBackgroundImage())
        .environment(\.backgroundStyle, AnyShapeStyle(Color.clear))
        .onAppear {
            context.send(viewAction: .appeared)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 80) {
            header
            list
        }
    }
    
    private var header: some View {
        VStack(spacing: 32) {
            OnboardingLogo(isOnGradient: true)
                .scaleEffect(x: 0.75, y: 0.75)
                .padding(.vertical, -20)
            
            Text(L10n.screenWelcomeTitle(InfoPlistReader.main.bundleDisplayName))
                .font(Font.compound.headingLGBold)
                .foregroundColor(Color.compound.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedLabelItem(title: L10n.screenWelcomeBullet2, listPosition: .top) {
                Image(systemName: "lock")
                    .foregroundColor(.compound.iconSecondaryAlpha)
            }
            RoundedLabelItem(title: L10n.screenWelcomeBullet3, listPosition: .bottom) {
                Image(systemName: "exclamationmark.bubble")
                    .padding(.horizontal, -3)
                    .foregroundColor(.compound.iconSecondaryAlpha)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .environment(\.backgroundStyle, AnyShapeStyle(.compound.bgCanvasDefaultLevel1))
    }

    @ViewBuilder
    private var button: some View {
        Button {
            context.send(viewAction: .doneTapped)
        } label: {
            Text(L10n.screenWelcomeButton)
        }
        .buttonStyle(.compound(.primary))
        .accessibilityIdentifier(A11yIdentifiers.welcomeScreen.letsGo)
    }
}

// MARK: - Previews

struct WelcomeScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = WelcomeScreenScreenViewModel()

    static var previews: some View {
        WelcomeScreen(context: viewModel.context)
    }
}
