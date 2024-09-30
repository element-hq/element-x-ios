//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

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
        Text(context.viewState.displayText)
            .font(.compound.bodyLGSemibold)
            .foregroundColor(textColor)
            .lineLimit(1)
            .padding(.leading, 4)
            .padding(.trailing, 6)
            .padding(.vertical, 1)
            .background { Capsule().foregroundColor(backgroundColor) }
            .onChange(of: context.viewState.displayText) { _ in
                didChangeText()
            }
    }
}

struct PillView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MockMediaProvider()
    
    static var previews: some View {
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadUser(isOwn: false))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Loading")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadUser(isOwn: true))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Loading Own")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadedUser(isOwn: false))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Loaded Long")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadedUser(isOwn: true))) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("Loaded Long Own")
        PillView(mediaProvider: mockMediaProvider,
                 context: PillContext.mock(type: .allUsers)) { }
            .frame(maxWidth: PillConstants.mockMaxWidth)
            .previewDisplayName("All Users")
    }
}
