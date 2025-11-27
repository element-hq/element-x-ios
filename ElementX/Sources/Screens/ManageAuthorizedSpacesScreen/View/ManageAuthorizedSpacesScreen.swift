//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageAuthorizedSpacesScreen: View {
    @Bindable var context: ManageAuthorizedSpacesScreenViewModel.Context
    
    var body: some View {
        Form { }
            .compoundList()
            .navigationTitle("Manage spaces")
    }
}

// MARK: - Previews

struct ManageAuthorizedSpacesScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ManageAuthorizedSpacesScreenViewModel(authorizedSpacesSelection: .init(joinedParentSpaces: .mockJoinedSpaces,
                                                                                                  unknownSpacesIDs: ["!unknown-space-id-1",
                                                                                                                     "!unknown-space-id-2",
                                                                                                                     "!unknown-space-id-3"],
                                                                                                  selectedIDs: ["space1",
                                                                                                                "space3",
                                                                                                                "!unknown-space-id-2"]),
                                                                 mediaProvider: MediaProviderMock(configuration: .init()))
    
    static var previews: some View {
        ManageAuthorizedSpacesScreen(context: viewModel.context)
    }
}
