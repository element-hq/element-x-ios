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

import DesignKit
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct OnboardingScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: OnboardingViewModel.Context
    
    var body: some View {
        ZStack {
            OnboardingBackgroundView(isAnimated: !Tests.isRunningUITests)
                .accessibilityHidden(true)
            
            GeometryReader { geometry in
                VStack(alignment: .leading) {
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                    
                    content
                        .frame(width: geometry.size.width)
                        .accessibilityIdentifier(A11yIdentifiers.onboardingScreen.hidden)
                    
                    Spacer()
                    
                    buttons
                        .frame(width: geometry.size.width)
                        .padding(.bottom, UIConstants.actionButtonBottomPadding)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .frame(maxHeight: .infinity)
            }
            .navigationBarHidden(true)
        }
    }
    
    var content: some View {
        VStack {
            if verticalSizeClass == .regular {
                Spacer()
                
                Image(Asset.Images.onboardingAppLogo.name)
                    .resizable()
                    .scaledToFit()
                    .padding(60)
                    .accessibilityHidden(true)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Spacer()
                
                Text(L10n.screenOnboardingWelcomeTitle)
                    .font(.compound.headingLGBold)
                    .foregroundColor(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.screenOnboardingWelcomeSubtitle(InfoPlistReader.main.bundleDisplayName))
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 12) {
            Button { context.send(viewAction: .login) } label: {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier(A11yIdentifiers.onboardingScreen.signIn)
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }
}

// MARK: - Previews

struct OnboardingScreen_Previews: PreviewProvider {
    static let viewModel = OnboardingViewModel()
    
    static var previews: some View {
        OnboardingScreen(context: viewModel.context)
    }
}
