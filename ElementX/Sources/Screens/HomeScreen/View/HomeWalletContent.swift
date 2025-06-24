//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum HomeWalletTab: CaseIterable {
    case token
    case transaction
    case account
}

enum WalletAction: String, CaseIterable {
    case receive = "Receive"
    case swap = "Swap"
    case send = "Send"
}

struct HomeWalletContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: HomeScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    @State private var showWalletBalance: Bool = true
    @State private var selectedTab: HomeWalletTab = .token
    
    var body: some View {
        walletContent
    }
    
    private var walletContent: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    zeroCardDetails
                    
                    HStack(spacing: 12) {
                        WalletActionButton(action: .receive, onTap: {
                            
                        })
                        WalletActionButton(action: .swap, onTap: {
                            
                        })
                        WalletActionButton(action: .send, onTap: {
                            
                        })
                    }
                    .padding(.vertical, 12)
                    
                    ZStack(alignment: .trailing) {
                        SimpleTabButtonsView(tabs: HomeWalletTab.allCases,
                                             selectedTab: selectedTab,
                                             tabTitle: { tab in
                            switch tab {
                            case .token: return "Tokens"
                            case .transaction: return "Transactions"
                            case .account: return "Accounts"
                            }
                        },
                                             onTabSelected: { tab in
                            selectedTab = tab
                        },
                                             showDivider: true)
                        
                        Image(systemName: "ellipsis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.compound.textSecondary)
                            .padding([.bottom, .trailing], 8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                .padding()
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
    
    @ViewBuilder
    private var zeroCardDetails: some View {
        ZStack(alignment: .leading) {
            Image(asset: Asset.Images.frameZeroCard)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading) {
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Balance")
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                        
                        CompoundIcon(showWalletBalance ? \.visibilityOn : \.visibilityOff, size: .custom(16), relativeTo: .body)
                            .foregroundStyle(.compound.textSecondary)
                            .onTapGesture {
                                showWalletBalance.toggle()
                            }
                    }
                    
                    Text("$78,810.04")
                        .font(.robotoMonoRegular(size: 22))
                        .foregroundColor(.compound.textPrimary)
                        .shadow(color: .white.opacity(0.5), radius: 8)
                        .padding(.vertical, 0.5)
                    
                    Text("+5.56%")
                        .font(.zero.bodyMD)
                        .foregroundColor(.zero.bgAccentRest)
                }
                .padding(.top, 6)
                
                Spacer()
                
                Text("Lefty Wilder".uppercased())
                    .font(.robotoMonoRegular(size: 12))
                    .foregroundColor(.compound.textSecondary)
            }
            .padding(.all, 14)
        }
    }
}

private struct WalletActionButton : View {
    var action: WalletAction
    var onTap: () -> Void
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Group {
                    switch action {
                    case .send:
                        CompoundIcon(\.arrowUpRight)
                    case .receive:
                        CompoundIcon(\.arrowUpRight)
                            .rotationEffect(.degrees(180))
                    case .swap:
                        CompoundIcon(customImage: Image(systemName: "arrow.up.arrow.down"),
                                     size: .custom(18),
                                     relativeTo: .body)
                            .rotationEffect(.degrees(90))
                            .padding(.horizontal, 2)
                    }
                }
                .foregroundColor(.zero.bgAccentRest)
                .onTapGesture {
                    onTap()
                }
                
                Text(action.rawValue)
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.zero.bgAccentRest)
                    .onTapGesture { onTap() }
                    .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(.zero.bgAccentRest.opacity(0.1))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.zero.bgAccentRest.opacity(0.3), lineWidth: 1)
        }
        .onTapGesture { onTap() }
    }
}
