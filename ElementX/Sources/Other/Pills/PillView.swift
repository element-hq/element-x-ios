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
        Text(context.viewState.displayText)
            .font(.compound.bodyLGSemibold)
            .foregroundColor(textColor)
            .lineLimit(1)
            .padding(.leading, 4)
            .padding(.trailing, 6)
            .padding(.vertical, 1)
            .background { Capsule().foregroundColor(backgroundColor) }
    }
}

struct PillView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MediaProviderMock(configuration: .init())
    
    static var previews: some View {
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: false,
                                                               displayText: PillUtilities.userPillDisplayText(username: "User",
                                                                                                              userID: "@alice:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("User")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: false,
                                                               displayText: PillUtilities.userPillDisplayText(username: "Alice but with a very long name",
                                                                                                              userID: "@alice:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("User with a long name")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: false,
                                                               displayText: PillUtilities.userPillDisplayText(username: nil, userID: "@alice:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("User with missing name")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .mention(isOwnMention: true,
                                                               displayText: PillUtilities.userPillDisplayText(username: "Alice", userID: "@alice:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("Own user")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .reference(displayText: PillUtilities.roomPillDisplayText(roomName: "Room",
                                                                                                                rawRoomText: "#room:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("Room")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .reference(displayText: PillUtilities.roomPillDisplayText(roomName: nil,
                                                                                                                rawRoomText: "#room:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("Room without name")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .reference(displayText: PillUtilities.eventPillDisplayText(roomName: "Room", rawRoomText: "#room:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("Message link")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(viewState: .reference(displayText: PillUtilities.eventPillDisplayText(roomName: nil, rawRoomText: "#room:matrix.org")))) { }
            .frame(maxWidth: PillUtilities.mockMaxWidth)
            .previewDisplayName("Message link without room name")
    }
}
