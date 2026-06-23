//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A prompt that asks the user whether they would like to enable Analytics or not.
struct AnalyticsPromptScreen: View {
    let context: AnalyticsPromptScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding, background: .gradient) {
            mainContent
        } bottomContent: {
            EmptyView()
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
            buttons
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            BigIcon(icon: \.chart)
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
        VisualListItem(title: title, position: position) {
            CompoundIcon(\.checkCircle, size: .small, relativeTo: .body)
                .foregroundColor(.compound.iconAccentPrimary)
        }
    }
    
    /// The enable/disable buttons. Rendered in the main (white) content area rather than over the
    /// bottom gradient, so the dark filled buttons stay high-contrast. Both share the same filled
    /// style so neither choice is visually weaker (no nudge towards sharing analytics).
    private var buttons: some View {
        VStack(spacing: 12) {
            Button(L10n.actionOk) { context.send(viewAction: .enable) }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.analyticsPromptScreen.enable)

            Button(L10n.actionNotNow) { context.send(viewAction: .disable) }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.analyticsPromptScreen.notNow)
        }
    }
}

// MARK: - Previews

struct AnalyticsPromptScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let noTermsViewModel = makeViewModel(showTerms: false)
    
    static var previews: some View {
        AnalyticsPromptScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AnalyticsPromptScreen(context: noTermsViewModel.context)
            .previewDisplayName("No terms")
    }
    
    static func makeViewModel(showTerms: Bool = true) -> AnalyticsPromptScreenViewModel {
        AnalyticsPromptScreenViewModel(termsURL: showTerms ? ServiceLocator.shared.settings.analyticsTermsURL : nil)
    }
}
