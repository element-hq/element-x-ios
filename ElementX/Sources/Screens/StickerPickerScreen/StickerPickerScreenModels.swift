//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum StickerPickerScreenCoordinatorAction {
    case stickerSelected(Sticker)
    case cancel
}

struct StickerPickerScreenViewState: Equatable {
    var packs: [StickerPack] = []
    var selectedPackIndex: Int = 0
    var isLoading: Bool = true
    var errorMessage: String?

    var currentPack: StickerPack? {
        guard !packs.isEmpty, selectedPackIndex < packs.count else {
            return nil
        }
        return packs[selectedPackIndex]
    }
}

enum StickerPickerScreenViewAction {
    case selectPack(index: Int)
    case selectSticker(Sticker)
    case dismiss
    case retryLoading
}
