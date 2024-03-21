//
// Copyright 2024 New Vector Ltd
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

import Compound
import SwiftUI

struct RoomDirectorySearchView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Label(L10n.screenRoomlistRoomDirectoryButtonTitle, icon: \.listBulleted)
        }
        .buttonStyle(.compound(.secondary))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
    
struct RoomDirectorySearchView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomDirectorySearchView { }
    }
}
