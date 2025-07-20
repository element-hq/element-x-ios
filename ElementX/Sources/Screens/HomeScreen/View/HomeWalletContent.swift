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
    private let scrollViewAdapter: ScrollViewAdapter = ScrollViewAdapter()
    
    @State private var showWalletBalance: Bool = true
    @State private var selectedTab: HomeWalletTab = .token
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isCompactMode: Bool = false
    
    var body: some View {
        walletContent
    }
    
    private var walletContent: some View {
        GeometryReader { geometry in
            VStack {
                cardDetailsView
                    .animation(.easeIn(duration: 0.25), value: isCompactMode)
                
                walletTabsView
                
                ScrollView {
                    offsetReader
                        .frame(height: 0)
                    
                    HomeWalletTabsContentView(context: context, selectedWalletTab: selectedTab)
                }
                .coordinateSpace(name: "scroll")
                .introspect(.scrollView, on: .supportedVersions) { scrollView in
                    guard scrollView != scrollViewAdapter.scrollView else { return }
                    scrollViewAdapter.scrollView = scrollView
                }
                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
                .animation(.elementDefault, value: context.viewState.walletContentListMode)
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var cardDetailsView: some View {
        if isCompactMode {
            compatCardDetails
        } else {
            VStack(alignment: .leading, spacing: 0) {
                zeroCardDetails
                
                actionButtonsView
                    .padding(.vertical, 6)
            }
        }
    }
    
    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("scroll")).minY)
        }
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            scrollOffset = value
            withAnimation(.easeInOut(duration: 0.3)) {
                isCompactMode = scrollOffset < -60
            }
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 10) {
            WalletActionButton(action: .receive, compactButtonStyle: isCompactMode) {
                context.send(viewAction: .startWalletTransaction(.receiveTransaction))
            }
            
            // Uncomment when swap is ready
            // WalletActionButton(action: .swap) {
            //     // swap action
            // }
            
            WalletActionButton(action: .send, compactButtonStyle: isCompactMode) {
                context.send(viewAction: .startWalletTransaction(.sendToken))
            }
        }
        .modifier(ActionButtonFrameModifier(isCompact: isCompactMode))
    }
    
    @ViewBuilder
    private var walletTabsView: some View {
        ZStack(alignment: .trailing) {
            SimpleTabButtonsView(tabs: [HomeWalletTab.token, HomeWalletTab.transaction],
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
            
//            Image(systemName: "ellipsis")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 18, height: 18)
//                .foregroundStyle(.compound.textSecondary)
//                .padding([.bottom, .trailing], 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var zeroCardDetails: some View {
        ZStack(alignment: .leading) {
            Image(asset: Asset.Images.frameZeroCard)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
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
                    
                    Text(showWalletBalance ? "******" : "$0")
                        .font(.robotoMonoRegular(size: 22))
                        .foregroundColor(.compound.textPrimary)
                        .shadow(color: .white.opacity(0.5), radius: 8)
                        .padding(.vertical, 4)
                    
//                    Text("+5.56%")
//                        .font(.zero.bodyMD)
//                        .foregroundColor(.zero.bgAccentRest)
                }
                .padding(.top, 6)
                
                Spacer()
                
                if let userName = context.viewState.currentUserZeroProfile?.displayName {
                    Text(userName.uppercased())
                        .font(.robotoMonoRegular(size: 12))
                        .foregroundColor(.compound.textSecondary)
                        .padding(.bottom, 8)
                }
            }
            .padding(.all, 14)
        }
        .frame(height: 225)
    }
    
    @ViewBuilder
    private var compatCardDetails: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
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
                
                Text(showWalletBalance ? "******" : "$0")
                    .font(.robotoMonoRegular(size: 22))
                    .foregroundColor(.compound.textPrimary)
                    .shadow(color: .white.opacity(0.5), radius: 8)
                    .padding(.vertical, 4)
                
//                Text("+5.56%")
//                    .font(.zero.bodyMD)
//                    .foregroundColor(.zero.bgAccentRest)
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            actionButtonsView
        }
        .padding(.vertical, 8)
    }
}

private struct WalletActionButton : View {
    var action: WalletAction
    var compactButtonStyle: Bool = false
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
                
                if !compactButtonStyle {
                    Text(action.rawValue)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.zero.bgAccentRest)
                        .onTapGesture { onTap() }
                        .padding(.horizontal, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(.zero.bgAccentRest.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.zero.bgAccentRest.opacity(0.3), lineWidth: 1)
        }
        .onTapGesture { onTap() }
    }
}

private struct ActionButtonFrameModifier: ViewModifier {
    let isCompact: Bool

    func body(content: Content) -> some View {
        if isCompact {
            content.frame(width: 110)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}

// PreferenceKey to track scroll offset
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
