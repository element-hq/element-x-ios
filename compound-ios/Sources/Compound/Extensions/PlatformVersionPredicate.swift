//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

public extension PlatformViewVersionPredicate<NavigationStackType, UINavigationController> {
    static var supportedVersions: Self {
        .iOS(.v17...)
    }
}

public extension PlatformViewVersionPredicate<WindowType, UIWindow> {
    static var supportedVersions: Self {
        .iOS(.v17...)
    }
}

public extension PlatformViewVersionPredicate<TextFieldType, UITextField> {
    static var supportedVersions: Self {
        .iOS(.v17...)
    }
}

public extension PlatformViewVersionPredicate<ScrollViewType, UIScrollView> {
    static var supportedVersions: Self {
        .iOS(.v17...)
    }
}

public extension PlatformViewVersionPredicate<ViewControllerType, UIViewController> {
    static var supportedVersions: Self {
        .iOS(.v17...)
    }
}

public extension PlatformViewVersionPredicate<TabViewType, UITabBarController> {
    static var supportedVersions: Self {
        .iOS(.v17...)
    }
}
