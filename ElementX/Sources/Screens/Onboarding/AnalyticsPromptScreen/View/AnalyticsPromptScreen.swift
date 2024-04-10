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
struct AnalyticsPromptScreen: View {
    @ObservedObject var context: AnalyticsPromptScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding, background: .gradient) {
            mainContent
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 40) {
            header
            checkmarkList
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.chart)
                .padding(.bottom, 8)
            
            Text(L10n.screenAnalyticsPromptTitle(InfoPlistReader.main.bundleDisplayName))
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.analyticsPromptScreen.title)
            
            Text(context.viewState.strings.optInContent)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }

    @ViewBuilder
    private var checkMark: some View {
        Image(systemName: "checkmark.circle")
            .symbolVariant(.fill)
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color.compound.iconAccentTertiary, Color.compound.textOnSolidPrimary)
    }
    
    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading, spacing: 4) {
            checkMarkItem(title: context.viewState.strings.point1, position: .top)
            checkMarkItem(title: context.viewState.strings.point2, position: .middle)
            checkMarkItem(title: context.viewState.strings.point3, position: .bottom)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .environment(\.backgroundStyle, AnyShapeStyle(.compound.bgSubtleSecondary))
    }

    @ViewBuilder
    private func checkMarkItem(title: String, position: ListPosition) -> some View {
        RoundedLabelItem(title: title, listPosition: position) {
            checkMark
        }
    }
    
    /// The stack of enable/disable buttons.
    private var buttons: some View {
        VStack(spacing: 16) {
            Button(L10n.actionOk) { context.send(viewAction: .enable) }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.analyticsPromptScreen.enable)
            
            Button { context.send(viewAction: .disable) } label: {
                Text(L10n.actionNotNow)
                    .font(.compound.bodyLGSemibold)
                    .padding(14)
            }
            .accessibilityIdentifier(A11yIdentifiers.analyticsPromptScreen.notNow)
        }
    }
}

// MARK: - Previews

struct AnalyticsPromptScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = AnalyticsPromptScreenViewModel(termsURL: ServiceLocator.shared.settings.analyticsConfiguration.termsURL)
    static var previews: some View {
        AnalyticsPromptScreen(context: viewModel.context)
    }
}
