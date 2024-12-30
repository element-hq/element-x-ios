import Compound
import SwiftUI

struct UserRewardsSettingsScreen: View {
    @ObservedObject var context: UserRewardsSettingsScreenViewModel.Context

    @State private var showRewardsFAQ = false

    @State private var expandedFAQ: UUID?
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            ZeroListRow(kind: .custom {
                ZStack {
                    if showRewardsFAQ {
                        rewardsFaqView
                    } else {
                        rewardsView
                    }
                }
            })
        }
        .zeroList()
        .navigationTitle(showRewardsFAQ ? "ZBI FAQ" : "ZBI")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showRewardsFAQ)
        .toolbar {
            if showRewardsFAQ {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            showRewardsFAQ = false
                        }
                    } label: {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(Color.white)
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    var rewardsView: some View {
        VStack {
            VStack(alignment: .center) {
                ZStack(alignment: .center) {
                    Image(asset: Asset.Images.rewardsVector)
                    Image(asset: Asset.Images.zeroLogoMark)
                }

                Text(
                    "$\(context.viewState.bindings.userRewards.getRefPriceFormatted())"
                )
                .font(.robotoMonoRegular(size: 38))
                .foregroundColor(.compound.textPrimary)

                Text(
                    "\(context.viewState.bindings.userRewards.getZeroCreditsFormatted()) MEOW"
                )
                .font(.robotoMonoRegular(size: 14))
                .foregroundColor(.compound.textSecondary)
            }

            Spacer()

            VStack {
                Text(
                    "Earn by messaging, inviting friends, and when those you invited mint a Domain or invite their friends. "
                )
                .font(.zero.bodyMD)
                .foregroundColor(.compound.textSecondary)
                + Text("More ->")
                .font(.zero.bodyMD)
                .foregroundColor(Color.zero.bgAccentRest)
            }
            .padding(.horizontal, 24)
            .padding(.top, 200)
            .onTapGesture {
                withAnimation {
                    showRewardsFAQ = true
                }
            }
        }
    }

    var rewardsFaqView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                ForEach(ZeroRewardFaqProvider.faqsList) { faq in
                    let isExpanded = expandedFAQ == faq.id
                    VStack(alignment: .leading) {
                        HStack {
                            Text(faq.question)
                                .font(.zero.bodyMD)
                                .fontWeight(isExpanded ? .semibold : .regular)
                            Spacer()
                            Image(
                                systemName: isExpanded
                                    ? "chevron.up" : "chevron.down"
                            )
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.compound.textPrimary)
                            .frame(width: 12, height: 12)
                        }
                        .onTapGesture {
                            withAnimation {
                                expandedFAQ = isExpanded ? nil : faq.id
                            }
                        }

                        if isExpanded {
                            let attributedString = faq.getAttributedString()
                            Text(attributedString)
                                .onOpenURL { _ in
                                    openURL(ZeroRewardFaqProvider.uniswapURL)
                                }
                                .padding(.top, 6)
                                .transition(.opacity)
                        }

                        Divider()
                    }.padding()
                }
            }.padding()
        }
    }
}

// MARK: - Previews

struct UserRewardsSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = UserSessionMock(
            .init(
                clientProxy: ClientProxyMock(
                    .init(userID: "@userid:example.com",
                          deviceID: "AAAAAAAAAAA"))))
        return UserRewardsSettingsScreenViewModel(userSession: userSession)
    }()

    static var previews: some View {
        UserRewardsSettingsScreen(context: viewModel.context)
    }
}
