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

struct EncryptionResetScreen: View {
    @ObservedObject var context: EncryptionResetScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            mainContent
        } bottomContent: {
            Button(L10n.actionContinue, role: .destructive) {
                context.send(viewAction: .reset)
            }
            .buttonStyle(.compound(.primary))
        }
        .background()
        .backgroundStyle(.compound.bgSubtleSecondary)
        .interactiveDismissDisabled()
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .alert(item: $context.alertInfo)
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 24) {
            header
            checkmarkList
            footer
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.error, style: .critical)
                .padding(.bottom, 8)
            
            Text(L10n.screenEncryptionResetTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenEncryptionResetSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    private var footer: some View {
        Text(L10n.screenEncryptionResetFooter)
            .font(.compound.bodyMDSemibold)
            .multilineTextAlignment(.center)
            .foregroundColor(.compound.textPrimary)
    }
    
    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading, spacing: 4) {
            checkMarkItem(title: L10n.screenEncryptionResetBullet1, position: .top, positive: true)
            checkMarkItem(title: L10n.screenEncryptionResetBullet2, position: .middle, positive: false)
            checkMarkItem(title: L10n.screenEncryptionResetBullet3, position: .bottom, positive: false)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .environment(\.backgroundStyle, AnyShapeStyle(.compound.bgSubtleSecondary))
    }

    @ViewBuilder
    private func checkMarkItem(title: String, position: ListPosition, positive: Bool) -> some View {
        RoundedLabelItem(title: title, listPosition: position) {
            if positive {
                CompoundIcon(\.check)
                    .foregroundColor(.compound.iconAccentPrimary)
            } else {
                CompoundIcon(\.close)
                    .foregroundColor(.compound.iconCriticalPrimary)
            }
        }
        .backgroundStyle(.compound.bgCanvasDefault)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct EncryptionResetScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EncryptionResetScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                                          userIndicatorController: UserIndicatorControllerMock())
    static var previews: some View {
        NavigationStack {
            EncryptionResetScreen(context: viewModel.context)
        }
    }
}
