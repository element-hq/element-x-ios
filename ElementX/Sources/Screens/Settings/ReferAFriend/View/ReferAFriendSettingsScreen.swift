//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ReferAFriendSettingsScreen: View {
    @ObservedObject var context: InviteFriendSettingsScreenViewModel.Context
    
    @State private var referralCodeCopied: Bool = false
    
    var body: some View {
        Form {
            ZeroListRow(kind: .custom {
                VStack(alignment: .center, spacing: 0) {
                    Image(asset: Asset.Images.referAFriendImage)
                    
                    VStack(spacing: 0) {
                        Text("Refer a Friend")
                            .font(.compound.headingMDBold)
                            .foregroundColor(.zero.bgAccentRest)
                        
                        Text("Earn 30% of pro subs from your code.")
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                        
                        VStack {
                            ReferAFriendBenefitRow(title: "Receive a Bonus",
                                                   description: "Both you and the invitee get free tokens")
                            
                            ReferAFriendBenefitRow(title: "Earn Passive Income",
                                                   description: "Receive 30% of Pro subscription revenue")
                            
                            ReferAFriendBenefitRow(title: "Grow your Reputation",
                                                   description: "Increase your clout with a bigger network")
                        }
                        .padding(.top, 12)
                        
                        if context.viewState.inviteSlug.isEmpty || !context.viewState.hasRemaniningInvites {
                            Text("Thank you! You’ve used all of your available invites. We’ll let you know when you can invite more people.")
                                .font(.zero.bodyLG)
                                .foregroundColor(.zero.bgAccentRest)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.zero.bgAccentRest.opacity(0.15))
                                )
                                .padding(.vertical, 10)
                        } else {
                            referralCodeLabel
                                .padding(.vertical, 6)
                            
                            HStack(spacing: 12) {
                                BottomInfoBox(title: "Total invited so far",
                                              description: context.viewState.totalInvited)
                                BottomInfoBox(title: "Pro subs",
                                              description: context.viewState.proSubscriptionsCount)
                            }
                            
                            referralCodeStrip
                                .padding(.top, 8)
                            
                            if context.viewState.hasRemaniningInvites {
                                shareInviteButton
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            })
        }
        .ignoresSafeArea()
        .zeroList()
    }
    
    private var referralCodeLabel: some View {
        ZStack {
            Rectangle()
                .fill(.compound.textSecondary.opacity(0.2))
                .frame(height: 1)
            
            Text("Your referral code")
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                .padding(.horizontal, 8)
                .background(.black)
        }
    }
    
    private var referralCodeStrip: some View {
        ZStack(alignment: .trailing) {
            Text(referralCodeCopied ? "Text Copied!" : context.viewState.inviteSlug)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(.zero.bgAccentRest)
                .onTapGesture {
                    copyRefferalCode()
                }
                .frame(maxWidth: .infinity)
                        
            Button(action: { copyRefferalCode() }) {
                Image(asset: referralCodeCopied ? Asset.Images.checkIcon : Asset.Images.iconCopy)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .background(.zero.bgAccentRest.opacity(0.1))
                    .foregroundStyle(.zero.bgAccentRest)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(.zero.bgAccentRest.opacity(0.1))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.zero.bgAccentRest.opacity(0.3), lineWidth: 1)
        }
        .onTapGesture {
            copyRefferalCode()
        }
    }
    
    func copyRefferalCode() {
        if !referralCodeCopied {
            referralCodeCopied = true
            context.send(viewAction: .inviteCopied)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                referralCodeCopied = false
            }
        }
    }
    
    var shareInviteButton: some View {
        Button(action: { copyRefferalCode() }) {
            Text("Share Invite")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.zero.bgAccentRest)
                )
        }
        .padding(.bottom, 24)
    }
    
    var referralCodeCopiedView: some View {
        VStack {
            Image(asset: Asset.Images.checkIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 48)
            
            Text("Invite Copied")
                .font(.compound.bodyLGSemibold)
                .foregroundStyle(.compound.textPrimary)
        }
        .padding(.all, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.compound.bgCanvasDefaultLevel1)
        )
    }
    
    private func inviteCodeMessage(inviteSlug: String) -> String {
        """
        Here's your invite code to ZERO Messenger:
        \(inviteSlug)

        Join early, earn more:
        https://zos.zero.tech/get-access
        """
    }
}

private struct ReferAFriendBenefitRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.compound.textPrimary)
                
                Text(description)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .padding(.top, 1)
            }
            
            Spacer()
            
            Image(asset: Asset.Images.checkIcon)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.zero.bgAccentRest)
                .frame(width: 20, height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.compound.bgCanvasDisabled)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 1)
    }
}

private struct BottomInfoBox: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.zero.bodySM)
                .foregroundColor(.compound.textSecondary)
            
            Text(description)
                .font(.compound.headingMD)
                .foregroundColor(.zero.bgAccentRest)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.zero.bgAccentRest.opacity(0.3), lineWidth: 1)
        }
    }
}
