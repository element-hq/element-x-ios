//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct CompletionSuggestionView: View {
    let mediaProvider: MediaProviderProtocol?
    let items: [SuggestionItem]
    var showBackgroundShadow = true
    let onTap: (SuggestionItem) -> Void
    
    private enum Constants {
        static let topPadding: CGFloat = 8.0
        static let listItemPadding: CGFloat = 6.0
        // added by the list itself when presenting the divider
        static let listItemSpacing: CGFloat = 4.0
        static let leadingPadding: CGFloat = 16.0
        // To make the scrolling more apparent we show a factional amount
        static let maxVisibleRows: CGFloat = 4.5
    }

    // MARK: Public
    
    @State private var prototypeListItemFrame: CGRect = .zero
    
    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            ZStack {
                MentionSuggestionItemView(mediaProvider: nil, item: .init(id: "", displayName: nil, avatarURL: nil, range: .init()))
                    .readFrame($prototypeListItemFrame)
                    .hidden()
                if showBackgroundShadow {
                    BackgroundView {
                        list()
                    }
                } else {
                    list()
                }
            }
            .padding(.bottom, Constants.listItemPadding)
        }
    }

    private func list() -> some View {
        List(items) { item in
            Button {
                onTap(item)
            } label: {
                switch item {
                case .user(let mention), .allUsers(let mention):
                    MentionSuggestionItemView(mediaProvider: mediaProvider, item: mention)
                }
            }
            .modifier(ListItemPaddingModifier(isFirst: items.first?.id == item.id))
            .listRowInsets(.init(top: 0, leading: Constants.leadingPadding, bottom: 0, trailing: 0))
        }
        .listStyle(PlainListStyle())
        .frame(height: contentHeightForRowCount(min(CGFloat(items.count), Constants.maxVisibleRows)))
        .background(Color.compound.bgCanvasDefault)
    }
    
    private func contentHeightForRowCount(_ count: CGFloat) -> CGFloat {
        (prototypeListItemFrame.height + Constants.listItemPadding * 2 + Constants.listItemSpacing) * count - Constants.listItemSpacing / 2 + Constants.topPadding - Constants.listItemPadding
    }

    private struct ListItemPaddingModifier: ViewModifier {
        private let isFirst: Bool

        init(isFirst: Bool) {
            self.isFirst = isFirst
        }

        func body(content: Content) -> some View {
            let topPadding: CGFloat = isFirst ? Constants.topPadding : Constants.listItemPadding
            let bottomPadding: CGFloat = Constants.listItemPadding

            return content
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
        }
    }
}

private struct BackgroundView<Content: View>: View {
    var content: () -> Content
    
    private let shadowRadius: CGFloat = 20.0
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .background(Color.compound.bgSubtlePrimary)
            .clipShape(RoundedCornerShape(radius: shadowRadius, corners: [.topLeft, .topRight]))
            .shadow(color: .black.opacity(0.20), radius: 20.0, x: 0.0, y: 3.0)
            .mask(Rectangle().padding(.init(top: -(shadowRadius * 2), leading: 0.0, bottom: 0.0, trailing: 0.0)))
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Previews

struct CompletionSuggestion_Previews: PreviewProvider, TestablePreview {
    static let multipleItems: [SuggestionItem] = (0...10).map { index in
        SuggestionItem.user(item: MentionSuggestionItem(id: "\(index)", displayName: "\(index)", avatarURL: nil, range: .init()))
    }
    
    static var previews: some View {
        // Putting them is VStack allows the preview to work properly in tests
        VStack(spacing: 8) {
            CompletionSuggestionView(mediaProvider: MockMediaProvider(),
                                     items: [.user(item: MentionSuggestionItem(id: "@user_mention_1:matrix.org", displayName: "User 1", avatarURL: nil, range: .init())),
                                             .user(item: MentionSuggestionItem(id: "@user_mention_2:matrix.org", displayName: "User 2", avatarURL: URL.documentsDirectory, range: .init()))]) { _ in }
        }
        VStack(spacing: 8) {
            CompletionSuggestionView(mediaProvider: MockMediaProvider(),
                                     items: multipleItems) { _ in }
        }
    }
}
