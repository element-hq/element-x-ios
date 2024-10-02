//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

final class LegalInformationScreenCoordinator: CoordinatorProtocol {
    private let viewModel: LegalInformationScreenViewModel
    
    init(appSettings: AppSettings) {
        viewModel = LegalInformationScreenViewModel(appSettings: appSettings)
    }
    
    func toPresentable() -> AnyView {
        AnyView(LegalInformationScreen(context: viewModel.context))
    }
}
