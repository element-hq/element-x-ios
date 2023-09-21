//
// Copyright 2022 New Vector Ltd
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
