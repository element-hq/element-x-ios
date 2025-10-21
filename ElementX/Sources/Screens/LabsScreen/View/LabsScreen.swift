//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LabsScreen: View {
    @Bindable var context: LabsScreenViewModel.Context
    
    var body: some View {
        Form {
            header
            threadsSection
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
                .compoundListSectionHeader()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var threadsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenLabsEnableThreads,
                                    icon: \.threads),
                    kind: .toggle($context.threadsEnabled))
        } footer: {
            Text(L10n.screenLabsEnableThreadsDescription)
                .compoundListSectionFooter()
        }
        .onChange(of: context.threadsEnabled) { _, _ in
            context.send(viewAction: .clearCache)
        }
    }
}

// MARK: - Previews

struct LabsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        AppSettings.resetAllSettings()
        return LabsScreenViewModel(labsOptions: AppSettings())
    }()
    
    static var previews: some View {
        NavigationStack {
            LabsScreen(context: viewModel.context)
        }
    }
}
