//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TransferTokenView: View {
    @ObservedObject var context: TransferTokenViewModel.Context
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    var navigationTitle: String {
        switch context.viewState.transferTokenFlowState {
        case .asset: "Select Asset"
        case .completed: "Sent"
        default: "Send"
        }
    }
    
    var body: some View {
        let flowState = context.viewState.transferTokenFlowState
        let isNavigatingForward: Bool = context.viewState.isNavigatingForward
        
        ZStack {
            if flowState == .recipient {
                SearchRecipientView(context: context, scrollViewAdapter: scrollViewAdapter)
            }
            
            if flowState == .asset {
                SelectTokenAssetView(context: context, scrollViewAdapter: scrollViewAdapter)
                    .transition(
                        .asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .identity,
                            removal: isNavigatingForward ? .identity : .move(edge: .trailing)
                        )
                    )
            }
            
            if flowState == .confirmation {
                ConfirmTransactionView(context: context)
                    .transition(
                        .asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .identity,
                            removal: isNavigatingForward ? .identity : .move(edge: .trailing)
                        )
                    )
            }
            
            if flowState == .inProgress {
                TransactionInProgressView(
                    size: 80,
                    color: .zero.bgAccentRest,
                    message: "Sending"
                )
                    .transition(
                        .asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .identity,
                            removal: isNavigatingForward ? .identity : .move(edge: .trailing)
                        )
                    )
            }
            
            if flowState == .completed {
                CompletedTransactionView(context: context)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: context.viewState.transferTokenFlowState)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
        .toolbar { toolbar }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        let flowState = context.viewState.transferTokenFlowState
        
        if context.viewState.showTopBarBackButton {
            ToolbarItem(placement: .navigationBarLeading) {
                CompoundIcon(\.chevronLeft)
                    .frame(width: 32, height: 32)
                    .onTapGesture {
                        let flowState = context.viewState.transferTokenFlowState
                        if flowState == .asset {
                            context.send(viewAction: .goToFlowState(.recipient))
                        }
                        if flowState == .confirmation {
                            context.send(viewAction: .goToFlowState(.asset))
                        }
                    }
            }
        }
        
        if flowState == .completed {
            ToolbarItem(placement: .primaryAction) {
                CompoundIcon(\.close)
                    .frame(width: 32, height: 32)
                    .onTapGesture {
                        context.send(viewAction: .transactionCompleted)
                    }
            }
        }
    }
}
