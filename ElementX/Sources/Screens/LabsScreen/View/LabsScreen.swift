//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LabsScreen: View {
    @Bindable var context: LabsScreenViewModel.Context
    
    var body: some View {
        Form {
            header
            settingsSection
        }
        .compoundList()
        .navigationTitle(L10n.screenLabsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        Section {
            EmptyView()
        } header: {
            VStack(spacing: 16) {
                BigIcon(icon: \.labs, style: .default)
                
                VStack(spacing: 8) {
                    Text(L10n.screenLabsHeaderTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.screenLabsHeaderDescription)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.compound.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var settingsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenLabsEnableThreads,
                                    icon: \.threads),
                    kind: .toggle($context.threadsEnabled))
        }
    }
}

// MARK: - Previews

struct LabsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LabsScreenViewModel(labsOptions: ServiceLocator.shared.settings)
    
    static var previews: some View {
        NavigationStack {
            LabsScreen(context: viewModel.context)
        }
    }
}
