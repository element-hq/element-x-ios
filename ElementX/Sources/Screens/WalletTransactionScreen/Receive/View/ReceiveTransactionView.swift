//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ReceiveTransactionView : View {
    @ObservedObject var context: ReceiveTransactionViewModel.Context
    
    var body: some View {
        UserWalletInfoView(context: context)
            .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
            .navigationTitle("Receive")
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $context.alertInfo)
            .toolbar { toolbar }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            CompoundIcon(\.close)
                .frame(width: 32, height: 32)
                .onTapGesture {
                    context.send(viewAction: .finish)
                }
        }
    }
}
