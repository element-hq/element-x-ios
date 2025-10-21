//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A very simple mock layout of some pills within messages bubbles and the composer.
struct PillViewOnBubble_Previews: PreviewProvider, TestablePreview {
    static let mentionContext = PillContext.mock(viewState: makeViewState(isOwnMention: false))
    static let ownMentionContext = PillContext.mock(viewState: makeViewState(isOwnMention: true))
    
    static var previews: some View {
        VStack(spacing: 16) {
            mockMessage
                .bubbleBackground(isOutgoing: false, color: .compound._bgBubbleIncoming)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            mockMessage
                .bubbleBackground(isOutgoing: true, color: .compound._bgBubbleOutgoing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            HStack(spacing: 8) {
                mockMessage
                    .offset(y: -1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .messageComposerStyle()
                
                SendButton { }
            }
            .padding(.top)
        }
        .padding(16)
    }
    
    static var mockMessage: some View {
        HStack(spacing: 4) {
            Text("Hello").foregroundStyle(.compound.textPrimary)
            PillView(context: mentionContext) { }
            PillView(context: ownMentionContext) { }
        }
    }
    
    static func makeViewState(isOwnMention: Bool) -> PillViewState {
        .mention(isOwnMention: isOwnMention,
                 displayText: PillUtilities.userPillDisplayText(username: isOwnMention ? "Alice" : "Bob",
                                                                userID: isOwnMention ? "@alice:matrix.org" : "@bob:matrix.org"))
    }
}
