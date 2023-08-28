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
    
    var body: some View {
        HStack(spacing: 4) {
            LoadableAvatarImage(url: nil, name: "test", contentID: "test", avatarSize: .custom(24), imageProvider: imageProvider)
            Text("Test")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().foregroundColor(.gray))
    }
}

struct PillView_Previews: PreviewProvider {
    static var previews: some View {
        PillView(imageProvider: MockMediaProvider())
    }
}
