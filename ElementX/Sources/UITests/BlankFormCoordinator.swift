//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

class BlankFormCoordinator: CoordinatorProtocol {
    func toPresentable() -> AnyView {
        AnyView(BlankForm())
    }
}

/// An empty Form used for UI tests, behind a sheet.
private struct BlankForm: View {
    var body: some View {
        Form {
            Text("Nothing to see here.")
        }
        .compoundList()
    }
}

struct BlankForm_Previews: PreviewProvider {
    static var previews: some View {
        BlankForm()
    }
}
