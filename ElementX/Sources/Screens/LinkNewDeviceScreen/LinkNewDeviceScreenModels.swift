//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum LinkNewDeviceScreenViewModelAction {
    case linkMobileDevice(LinkNewDeviceService.LinkMobileProgressPublisher)
    case linkDesktopComputer
    case dismiss
}

struct LinkNewDeviceScreenViewState: BindableState {
    enum Mode: Equatable { case loading, readyToLink(isGeneratingCode: Bool), notSupported }
    var mode: Mode = .loading
    
    let showLinkDesktopComputerButton: Bool
}

enum LinkNewDeviceScreenViewAction {
    case linkMobileDevice
    case linkDesktopComputer
    case dismiss
}
