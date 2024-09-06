//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

struct MatrixUserShareLink<Label: View>: View {
    private let permalink: URL?
    private let label: Label
    
    init(userID: String, @ViewBuilder label: () -> Label) {
        self.label = label()
        permalink = try? URL(string: matrixToUserPermalink(userId: userID))
    }
    
    var body: some View {
        if let permalink {
            ShareLink(item: L10n.inviteFriendsText(InfoPlistReader.main.bundleDisplayName, permalink.absoluteString)) {
                label
            }
        }
    }
}

struct MatrixUserPermalink_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        MatrixUserShareLink(userID: "@someone:somewhere.org") {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
