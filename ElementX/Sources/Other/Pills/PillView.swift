//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
