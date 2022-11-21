//
// Copyright 2021 New Vector Ltd
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

/// A prompt that asks the user whether they would like to enable Analytics or not.
struct AnalyticsPrompt: View {
    // MARK: - Properties
    
    // MARK: Private
    
    private let horizontalPadding: CGFloat = 16
    
    // MARK: Public
    
    @ObservedObject var context: AnalyticsPromptViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
                
                mainContent
                    .readableFrame()
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, UIConstants.onboardingBreakerScreenTopPadding)
                    .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    buttons
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .padding(.top, 8)
                .background(Color.element.background.ignoresSafeArea())
            }
            .background(Color.element.background.ignoresSafeArea())
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack {
            Image(uiImage: Asset.Images.analyticsLogo.image)
                .padding(.bottom, 25)
            
            Text(ElementL10n.analyticsOptInTitle(InfoPlistReader.target.bundleDisplayName))
                .font(.element.title2Bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.primaryContent)
                .padding(.bottom, 2)
            
            Text(context.viewState.strings.optInContent)
                .font(.element.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.secondaryContent)
            
            Divider()
                .background(Color.element.quinaryContent)
                .padding(.vertical, 28)
            
            checkmarkList
        }
    }
    
    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading) {
            AnalyticsPromptCheckmarkItem(attributedString: context.viewState.strings.point1)
            AnalyticsPromptCheckmarkItem(attributedString: context.viewState.strings.point1)
            AnalyticsPromptCheckmarkItem(string: ElementL10n.analyticsOptInListItem3)
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(.element.body)
        .foregroundColor(.element.secondaryContent)
        .frame(maxWidth: .infinity)
    }
    
    /// The stack of enable/disable buttons.
    private var buttons: some View {
        VStack {
            Button { context.send(viewAction: .enable) } label: {
                Text(ElementL10n.actionEnable)
                    .font(.element.bodyBold)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier("enableButton")
            
            Button { context.send(viewAction: .disable) } label: {
                Text(ElementL10n.actionNotNow)
                    .font(.element.bodyBold)
                    .padding(12)
            }
            .accessibilityIdentifier("disableButton")
        }
    }
}

// MARK: - Previews

struct AnalyticsPrompt_Previews: PreviewProvider {
    static let viewModel = AnalyticsPromptViewModel(termsURL: BuildSettings.analyticsConfiguration.termsURL)
    static var previews: some View {
        AnalyticsPrompt(context: viewModel.context)
            .tint(.element.accent)
    }
}
