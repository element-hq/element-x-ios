//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct UserIndicatorPresenter: View {
    @ObservedObject var userIndicatorController: UserIndicatorController
    
    var body: some View {
        indicatorViewFor(indicator: userIndicatorController.activeIndicator)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.elementDefault, value: userIndicatorController.activeIndicator)
    }
    
    @ViewBuilder
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
        .alert(item: $userIndicatorController.alertInfo)
    }
}
