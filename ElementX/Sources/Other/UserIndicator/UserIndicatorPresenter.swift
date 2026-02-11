//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserIndicatorPresenter: View {
    @ObservedObject var userIndicatorController: UserIndicatorController
    
    var body: some View {
        indicatorViewFor(indicator: userIndicatorController.activeIndicator)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.elementDefault, value: userIndicatorController.activeIndicator)
    }
    
    private func indicatorViewFor(indicator: UserIndicator?) -> some View {
        ZStack { // Need a container to properly animate transitions
            if let indicator {
                switch indicator.type {
                case .toast:
                    UserIndicatorToastView(indicator: indicator)
                case .modal:
                    UserIndicatorModalView(indicator: indicator)
                }
            }
        }
    }
}
