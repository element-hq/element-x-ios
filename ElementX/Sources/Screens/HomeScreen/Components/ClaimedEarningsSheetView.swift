//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ClaimedEarningsSheetView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            EarningsSheetBackground()
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Earnings Claimed")
                        .font(.compound.bodyLGSemibold)
                        .foregroundStyle(.compound.textPrimary)
                    
                    Spacer()
                    
                    CompoundIcon(\.close, size: .small, relativeTo: .compound.bodyLGSemibold)
                        .padding(4)
                        .background(Circle().fill(.compound.bgCanvasDefaultLevel1))
                        .onTapGesture { onDismiss() }
                }
                
                Text("Your daily earnings have been added to you Wallet.")
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(.black)
                                .frame(width: 75, height: 75)
                                .shadow(color: .zero.bgAccentRest.opacity(0.5), radius: 20)
                            
                            Image(asset: Asset.Images.postMeowIcon)
                                .resizable()
                                .padding(12)
                                .frame(width: 75, height: 75)
                                .foregroundStyle(.zero.bgAccentRest)
                                                        
                            Image(asset: Asset.Images.iconZChain)
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        .background(
                            Circle()
                                .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                        )
                        
                        Text("25,000.23 MEOW")
                            .font(.compound.bodyLGSemibold)
                            .foregroundStyle(.zero.bgAccentRest)
                            .shadow(color: .white.opacity(0.5), radius: 4)
                        
                        Text("$1200.24")
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    shareOnXButton
                    closeButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
    }
    
    @ViewBuilder
    var shareOnXButton: some View {
        Button(action: {  }) {
            Text("Share on X")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.zero.bgAccentRest)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.zero.bgAccentRest.opacity(0.15))
                        .stroke(.zero.bgAccentRest)
                )
        }
    }
    
    @ViewBuilder
    var closeButton: some View {
        Button(action: { onDismiss() }) {
            Text("Close")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.zero.bgAccentRest)
                )
        }
    }
}

private struct EarningsSheetBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .zero.bgAccentRest.opacity(0.75),
                        Color.black,
                        Color.black,
                        .zero.bgAccentRest.opacity(0.5),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .zero.bgAccentRest.opacity(0.5),
                                .zero.bgAccentRest.opacity(0.25)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .padding(16)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}
