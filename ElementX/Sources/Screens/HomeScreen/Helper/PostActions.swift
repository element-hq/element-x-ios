//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

struct PostActions {
    var onPostTapped: () -> Void = {}
    var onOpenArweaveLink: () -> Void = {}
    var onMeowTapped: (Int) -> Void = { _ in }
    var onOpenYoutubeLink: (String) -> Void = { _ in }
    var onOpenUserProfile: (ZPostUserProfile) -> Void = { _ in }
    var onMediaTapped: (String) -> Void = { _ in }
    var onReloadMedia: () -> Void = {}
}
