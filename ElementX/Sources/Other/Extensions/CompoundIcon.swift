//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

extension CompoundIcon {
    init(asset: ImageAsset) {
        self.init(customImage: asset.swiftUIImage)
    }
    
    init(asset: ImageAsset, size: CompoundIcon.Size, relativeTo font: Font) {
        self.init(customImage: asset.swiftUIImage, size: size, relativeTo: font)
    }
}
