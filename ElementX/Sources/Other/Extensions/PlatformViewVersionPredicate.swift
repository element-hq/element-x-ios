//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

import SwiftUIIntrospect

extension PlatformViewVersionPredicate<WindowType, UIWindow> {
    static var supportedVersions: Self {
        .iOS(.v16, .v17)
    }
}

extension PlatformViewVersionPredicate<TextFieldType, UITextField> {
    static var supportedVersions: Self {
        .iOS(.v16, .v17)
    }
}

extension PlatformViewVersionPredicate<ScrollViewType, UIScrollView> {
    static var supportedVersions: Self {
        .iOS(.v16, .v17)
    }
}

extension PlatformViewVersionPredicate<ViewControllerType, UIViewController> {
    static var supportedVersions: Self {
        .iOS(.v16, .v17)
    }
}
