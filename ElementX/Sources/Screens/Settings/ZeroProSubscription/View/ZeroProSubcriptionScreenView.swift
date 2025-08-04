//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ZeroProSubcriptionScreenView: View {
    @ObservedObject var context: ZeroProSubcriptionScreenViewModel.Context
    
    @State private var showZeroSubscriptionModal: Bool = false
        
    var body: some View {
        Form {
            ZeroListRow(kind: .custom({
                VStack(alignment: .center, spacing: 0) {
                    if context.viewState.isZeroProSubscriber {
                        HStack {
                            Spacer()
                            Text("Pro Member")
                                .font(.zero.bodySM)
                                .foregroundStyle(.zero.bgAccentRest)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.zero.bgAccentRest)
                                )
                        }
                    }
                    Image(asset: Asset.Images.imgZeroProSub)
                        .resizable()
                        .frame(width: 200, height: 200)
                    
                    Text("ZERO Pro")
                        .font(.compound.headingLGBold)
                        .foregroundStyle(.zero.bgAccentRest)
                    
                    Text("Supercharge your rewards.")
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                    
                    StrikedLabel(text: "Member Benefits")
                        .padding(.top, 32)
                    
                    VStack {
                        ZeroSettingsBenefitRow(title: "Earn Daily Income",
                                               description: "Only Pro members receive rewards")
                        
                        ZeroSettingsBenefitRow(title: "Pro Badge",
                                               description: "Flex with a special Pro badge")
                        
                        ZeroSettingsBenefitRow(title: "Earn Affiliate Fees",
                                               description: "Earn 30% of subscriptions from your code")
                    }
                    .padding(.top, 12)
                    
                    HorizontalDivider()
                        .padding(.vertical, 24)
                    
                    if context.viewState.isZeroProSubscriber {
                        manageZeroProSubscription
                    } else {
                        if context.viewState.canPurchaseSubscription {
                            subscribeToZeroProButton
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }))
        }
        .ignoresSafeArea()
        .zeroList()
        .sheet(isPresented: $showZeroSubscriptionModal, content: {
            ZeroSubscriptionModalView(
                onSubscribe: {
                    showZeroSubscriptionModal.toggle()
                    context.send(viewAction: .purchaseSubscriptionTapped)
                }
            )
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
        })
    }
    
    private var subscribeToZeroProButton: some View {
        Button(action: { showZeroSubscriptionModal.toggle() }) {
            Text("Subscribe to ZERO Pro")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.zero.bgAccentRest)
                )
        }
        .padding(.vertical, 8)
    }
    
    private var manageZeroProSubscription: some View {
        VStack(alignment: .leading) {
            Text("Manage your subscription")
                .font(.zero.bodyLG)
                .foregroundStyle(.compound.textPrimary)
            
            Text("Review terms or manage your subscription.")
                .font(.zero.bodyMD)
                .foregroundStyle(.compound.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Plan")
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                    
                    Text("$\(ZeroContants.ZERO_PRO_SUBSCRIPTION_USD) / month")
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Next billing date")
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                    
                    Text("24 Feb, 2026")
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct ZeroSubscriptionModalView : View {
    let onSubscribe: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("ZERO Pro Subscription")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Monthly Plan")
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Text("$\(ZeroContants.ZERO_PRO_SUBSCRIPTION_USD.formatToThousandSeparatedString()) / month")
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textPrimary)
                }
                
                Text("$\((ZeroContants.ZERO_PRO_SUBSCRIPTION_USD * 12).formatToThousandSeparatedString()) per year, billed monthly")
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.zero.bgAccentRest.opacity(0.15))
                    .stroke(.zero.bgAccentRest)
            )
            
            Button(action: { onSubscribe() }) {
                Text("Subscribe")
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.zero.bgAccentRest)
                    )
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
    }
}
