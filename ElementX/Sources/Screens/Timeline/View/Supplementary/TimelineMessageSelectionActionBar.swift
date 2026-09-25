//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Replaces the composer while messages are being selected, offering the action to take on them.
struct TimelineMessageSelectionActionBar: View {
    @ObservedObject var context: TimelineViewModelType.Context
    
    var body: some View {
        Button {
            context.send(viewAction: .forwardMessageSelection)
        } label: {
            Label(L10n.actionForwardMessages(context.viewState.messageSelection.count), icon: \.forward)
        }
        .buttonStyle(.compound(.primary))
        .padding(16)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
}

// MARK: - Previews

struct TimelineMessageSelectionActionBar_Previews: PreviewProvider, TestablePreview {
    static let viewModel: TimelineViewModel = {
        let viewModel = TimelineViewModel.mock() // A fresh instance so the shared mock isn't left selecting.
        viewModel.state.messageSelection.selectedEventIDs = ["$1", "$2", "$3"]
        return viewModel
    }()
    
    static var previews: some View {
        TimelineMessageSelectionActionBar(context: viewModel.context)
            .previewLayout(.sizeThatFits)
    }
}
