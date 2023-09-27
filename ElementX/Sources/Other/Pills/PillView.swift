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
    @ObservedObject var viewModel: PillViewModel
    /// callback triggerd by changes in the display text
    let didChangeText: () -> Void
        
    var body: some View {
        HStack(spacing: 4) {
            LoadableAvatarImage(url: viewModel.url, name: viewModel.name, contentID: viewModel.contentID, avatarSize: .custom(24), imageProvider: imageProvider)
            Text(viewModel.displayText)
                .font(.compound.bodyLG)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        // for now design has defined no color so we will just use gray
        .background(Capsule().foregroundColor(.gray))
        .frame(maxWidth: 235)
        .onChange(of: viewModel.displayText) { _ in
            didChangeText()
        }
    }
}

struct PillView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MockMediaProvider()
    
    static var loading: some View {
        PillView(imageProvider: mockMediaProvider,
                 viewModel: PillViewModel.mockViewModel(type: .loadUser)) { }
    }
    
    static var previews: some View {
        loading
            .previewDisplayName("Loading")
        PillView(imageProvider: mockMediaProvider,
                 viewModel: PillViewModel.mockViewModel(type: .loadedUser)) { }
            .previewDisplayName("Loaded Long")
    }
}
