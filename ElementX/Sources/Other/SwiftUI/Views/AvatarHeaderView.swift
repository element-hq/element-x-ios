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

struct AvatarHeaderView<Footer: View>: View {
    let avatarUrl: URL?
    let name: String?
    let id: String
    let avatarSize: AvatarSize
    let imageProvider: ImageProviderProtocol?
    let subtitle: String?
    var onAvatarTap: (() -> Void)?
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 8.0) {
            Button {
                onAvatarTap?()
            } label: {
                LoadableAvatarImage(url: avatarUrl,
                                    name: name,
                                    contentID: id,
                                    avatarSize: avatarSize,
                                    imageProvider: imageProvider)
            }
            .buttonStyle(.borderless) // Add a button style to stop the whole row being tappable.

            Text(name ?? id)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.headingLGBold)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            if let subtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyLG)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
            
            footer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }
}

struct HeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            AvatarHeaderView(avatarUrl: URL.picturesDirectory,
                             name: "Test Room",
                             id: "test",
                             avatarSize: .room(on: .details),
                             imageProvider: MockMediaProvider(),
                             subtitle: "#test:matrix.org") {
                HStack(spacing: 32) {
                    ShareLink(item: "test") {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: "Test"))
                }
                .padding(.top, 32)
            }
        }
    }
}
