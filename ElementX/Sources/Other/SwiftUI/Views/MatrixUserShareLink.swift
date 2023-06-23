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

struct MatrixUserShareLink<Label: View>: View {
    private let permalink: URL?
    private let label: Label
    
    init(userID: String, @ViewBuilder label: () -> Label) {
        self.label = label()
        permalink = try? PermalinkBuilder.permalinkTo(userIdentifier: userID,
                                                      baseURL: ServiceLocator.shared.settings.permalinkBaseURL)
    }
    
    var body: some View {
        if let permalink {
            ShareLink(item: L10n.inviteFriendsText(InfoPlistReader.main.bundleDisplayName, permalink.absoluteString)) {
                label
            }
        }
    }
}

struct MatrixUserPermalink_Previews: PreviewProvider {
    static var previews: some View {
        MatrixUserShareLink(userID: "@someone:somewhere.org") {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
