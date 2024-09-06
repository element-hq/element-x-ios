//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

extension Label {
    /// Creates a label using a local asset as a Compound icon and a title generated from a string.
    /// The icon size will be 24pt, scaling relative to the `bodyLG` with Dynamic Type.
    /// - Parameters:
    ///   - title: A string used as the label’s title.
    ///   - iconAsset: The asset to use as the custom Compound icon.
    ///
    /// The supplied asset should have a square frame or it may end up distorted.
    init(_ title: some StringProtocol, iconAsset: ImageAsset) where Title == Text, Icon == CompoundIcon {
        self.init {
            Text(title)
        } icon: {
            CompoundIcon(customImage: iconAsset.swiftUIImage)
        }
    }
    
    /// Creates a label using a local asset as a Compound icon and a title generated from a string.
    /// - Parameters:
    ///   - title: A string used as the label’s title.
    ///   - iconAsset: The asset to use as the custom Compound icon.
    ///   - size: The size of the icon.
    ///   - font: The font that the icon will scale relative to for Dynamic Type.
    ///
    /// The supplied asset should have a square frame or it may end up distorted.
    init(_ title: some StringProtocol,
         iconAsset: ImageAsset,
         iconSize: CompoundIcon.Size,
         relativeTo font: Font) where Title == Text, Icon == CompoundIcon {
        self.init {
            Text(title)
        } icon: {
            CompoundIcon(customImage: iconAsset.swiftUIImage, size: iconSize, relativeTo: font)
        }
    }
}
