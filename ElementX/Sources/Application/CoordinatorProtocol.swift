//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

@MainActor
protocol CoordinatorProtocol: AnyObject {
    func start()
    func stop()
    func toPresentable() -> AnyView
}

extension CoordinatorProtocol {
    func start() { }

    func stop() { }

    func toPresentable() -> AnyView {
        AnyView(Text("View not configured"))
    }
}
