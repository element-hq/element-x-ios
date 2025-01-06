//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import SwiftUIIntrospect

extension PlatformViewVersionPredicate<TextFieldType, UITextField> {
    static var supportedVersions: Self {
        .iOS(.v17, .v18)
    }
}

extension PlatformViewVersionPredicate<ScrollViewType, UIScrollView> {
    static var supportedVersions: Self {
        .iOS(.v17, .v18)
    }
}

extension PlatformViewVersionPredicate<ViewControllerType, UIViewController> {
    static var supportedVersions: Self {
        .iOS(.v17, .v18)
    }
}

extension PlatformViewVersionPredicate<NavigationStackType, UINavigationController> {
    static var supportedVersions: Self {
        .iOS(.v17, .v18)
    }
}
