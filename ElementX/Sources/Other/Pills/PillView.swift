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
    let imageProvider: ImageProviderProtocol?
    @ObservedObject var context: PillContext
    /// callback triggerd by changes in the display text
    let didChangeText: () -> Void
        
    var body: some View {
        HStack(spacing: 4) {
            LoadableAvatarImage(url: context.viewState.avatarURL, name: context.viewState.name, contentID: context.viewState.contentID, avatarSize: .custom(24), imageProvider: imageProvider)
            Text(context.viewState.displayText)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(.compound.textOnSolidPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        // for now design has defined no color so we will just use gray
        .background(Capsule().foregroundColor(context.viewState.isOwnMention ? .compound.bgCriticalPrimary : .gray))
        .frame(maxWidth: PillConstants.maxWidth)
        .onChange(of: context.viewState.displayText) { _ in
            didChangeText()
        }
    }
}

struct PillView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MockMediaProvider()
    
    static var previews: some View {
        PillView(imageProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadUser(isOwn: false))) { }
            .previewDisplayName("Loading")
        PillView(imageProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadUser(isOwn: true))) { }
            .previewDisplayName("Loading Own")
        PillView(imageProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadedUser(isOwn: false))) { }
            // To simulate the trimming that happens at UIKit level
            .previewDisplayName("Loaded Long")
        PillView(imageProvider: mockMediaProvider,
                 context: PillContext.mock(type: .loadedUser(isOwn: true))) { }
            // To simulate the trimming that happens at UIKit level
            .frame(maxWidth: PillConstants.maxWidth)
        PillView(imageProvider: mockMediaProvider,
                 context: PillContext.mock(type: .allUsers)) { }
            .previewDisplayName("All Users")
    }
}
