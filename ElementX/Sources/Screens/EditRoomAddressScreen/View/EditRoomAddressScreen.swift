//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EditRoomAddressScreen: View {
    @ObservedObject var context: EditRoomAddressScreenViewModel.Context
    
    var body: some View {
        Form {
            EmptyView()
        }
        .compoundList()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct EditRoomAddressScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EditRoomAddressScreenViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                          clientProxy: ClientProxyMock(.init()),
                                                          userIndicatorController: UserIndicatorControllerMock())
    static var previews: some View {
        NavigationStack {
            EditRoomAddressScreen(context: viewModel.context)
        }
    }
}
