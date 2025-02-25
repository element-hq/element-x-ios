//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PillView: View {
    let mediaProvider: MediaProviderProtocol?
    @ObservedObject var context: PillContext
    /// callback triggerd by changes in the display text
    let didChangeText: () -> Void
    
    var textColor: Color {
        context.viewState.isOwnMention ? .compound._textOwnPill : .compound.textPrimary
    }
    
    var backgroundColor: Color {
        context.viewState.isOwnMention ? .compound._bgOwnPill : .compound._bgPill
    }
        
    var body: some View {
        mainContent
            .onChange(of: context.viewState.displayText) {
                didChangeText()
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: 4) {
            image
            Text(context.viewState.displayText)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(textColor)
                .lineLimit(1)
        }
        .padding(.leading, 4)
        .padding(.trailing, 6)
        .padding(.vertical, 1)
        .background { Capsule().foregroundColor(backgroundColor) }
    }
    
    @ViewBuilder
    private var image: some View {
        if let image = context.viewState.image {
            switch image {
            case .link:
                CompoundIcon(\.link, size: .custom(12), relativeTo: .compound.bodyLGSemibold)
                    .padding(2)
                    .foregroundStyle(.compound.bgCanvasDefault)
                    .background(.compound.textLinkExternal)
                    .clipShape(Circle())
            case .roomAvatar(let avatar):
                RoomAvatarImage(avatar: avatar, avatarSize: .custom(16), mediaProvider: mediaProvider)
            }
        }
    }
}

struct PillView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MediaProviderMock(configuration: .init())
    
    static var previews: some View {
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: false,
                                                               displayText: "@Alice"))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("User")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: false,
                                                               displayText: "@Alice but with a very very long name"))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("User with a long name")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: true,
                                                               displayText: "@Alice"))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Own user")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .reference(avatar: .roomAvatar(.room(id: "roomID", name: "Room", avatarURL: nil)), displayText: "Room"))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Room")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .reference(avatar: .link, displayText: L10n.screenRoomEventPill("Room")))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Message link")
    }
}
