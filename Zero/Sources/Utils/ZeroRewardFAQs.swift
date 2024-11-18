import Foundation

struct ZeroRewardFAQ: Identifiable {
    public let id = UUID()
    public let question: String
    public let answer: String
    public var highlights: [(String, String)] = []

    func getAttributedString() -> AttributedString {
        var attributedString = AttributedString(answer)
        for highlight in highlights {
            let range = attributedString.range(of: highlight.0)!
            attributedString[range].link = URL(string: highlight.1)
            attributedString[range].foregroundColor = .zero.bgAccentRest
            attributedString[range].underlineStyle = .single
        }
        return attributedString
    }
}

struct ZeroRewardFaqProvider {
    public static let uniswapURL = URL(
        string:
            "https://app.uniswap.org/swap?outputCurrency=0x0eC78ED49C2D27b315D462d43B5BAB94d2C79bf8&amp;inputCurrency=ETH&amp;use=V2"
    )!

    public static let faqsList = [
        ZeroRewardFAQ(
            question: "How do I earn daily income?",
            answer: """
                ZERO Messenger rewards all active users by distributing rewards from a daily pool. \
                The criteria that determine daily ZBI payments include:

                1. Messaging - Having conversations in the app contributes to your daily allotment.
                2. Invites - Inviting friends who sign up and join the app gives you a ZBI bump.
                3. Refer-a-Mint - Inviting friends who join Messenger and then go on to mint a ZERO ID \
                will earn YOU rewards too!
                4. Friends Inviting Friends - Invitees of friends you've invited also help you earn.
                5. Refer-a-Friend-of-a-Friend-to-Mint - Friends of friends minting Worlds or Domains in \
                the ZERO ID Explorer app earns you some trickle-up rewardonomics!
                """,
            highlights: [
                ("mint a ZERO ID", "https://explorer.zero.tech/"),
                ("ZERO ID Explorer", "https://explorer.zero.tech/"),
            ]
        ),

        ZeroRewardFAQ(
            question: "This seems too good to be true?",
            answer: """
                At ZERO, we believe a product cannot exist without the people who use it. By disbursing \
                MEOW to our Messenger community, we're distributing the value of ZERO to those that bring \
                it to life — you. Of course, we can't do this forever; early users of ZERO Messenger will \
                be rewarded more than latecomers. As we scale into the future, individual payouts will \
                diminish and we'll transition to a new model.
                """
        ),

        ZeroRewardFAQ(
            question: "What is MEOW?",
            answer: """
                MEOW (ticker symbol $MEOW) is an ERC-20 standard cryptocurrency token on the Ethereum \
                blockchain. It is the native currency of the ZERO ecosystem, powering a suite of native \
                zApps, including our unique identity solution — ZERO ID — and our ZERO blockchain browser, \
                Explorer. MEOW can be swapped for Ethereum or tradition fiat-backed currencies like USDC \
                at major DeFi exchanges, like Uniswap.

                MEOW is a used by a wider ecosystem of projects. Read more Here.
                """,
            highlights: [
                ("Explorer", "https://explorer.zero.tech/"),
                (
                    "Uniswap",
                    "https://app.uniswap.org/swap?outputCurrency=0x0eC78ED49C2D27b315D462d43B5BAB94d2C79bf8&inputCurrency=ETH&use=V2"
                ),
                ("Here", "https://www.meow.inc/"),
            ]
        ),

        ZeroRewardFAQ(
            question: "What is ZERO ID?",
            answer: """
                ZERO ID is the native identity management system powering the ZERO ecosystem. Everything \
                in Messenger is tied to your ZERO ID; it is your digital passport and your key to \
                unlocking the full potential of ZBI! ZERO ID comprises two type of domains, represented \
                as ERC-721 NFTs on the Ethereum blockchain: Worlds and Domains. Worlds are the top-level \
                domain in the system (0://hello) and are ideally suited for communities and organizations. \
                Domains are second-level-and-beyond subdomains in the system, existing under Worlds \
                (0://hello.goodbye), but also having the ability to mint domains under themselves \
                (0://hello.goodbye.bonjour, 0://hello.goodbye.bonjour.adieu, and so on)!
                """
        ),

        ZeroRewardFAQ(
            question: "How can I withdraw my MEOW?",
            answer:
                "The ability to withdraw your earned MEOW to an external wallet will be added soon!"
        ),
    ]
}
