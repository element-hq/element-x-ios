//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

@MainActor
final class PillContext: ObservableObject {
    @Published var viewState: PillViewState = .undefined
    
    let data: PillTextAttachmentData
    var cancellable: AnyCancellable?
    
    init(timelineContext: TimelineViewModel.Context, data: PillTextAttachmentData) {
        self.data = data
        timelineContext.viewState.pillContextUpdater?(self)
    }
}

extension PillContext {
    static func mock(viewState: PillViewState, delay: Duration? = nil) -> PillContext {
        // This is just for previews so the internal data doesn't really matter
        let viewModel = PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: .allUsers, font: .preferredFont(forTextStyle: .body)))
        if let delay {
            viewModel.viewState = .mention(isOwnMention: false, displayText: "placeholder")
            Task {
                try? await Task.sleep(for: delay)
                viewModel.viewState = viewState
            }
        } else {
            viewModel.viewState = viewState
        }
        return viewModel
    }
}

enum PillViewState: Equatable {
    case mention(isOwnMention: Bool, displayText: String)
    case reference(displayText: String)
    case undefined
    
    var isOwnMention: Bool {
        switch self {
        case .mention(let isOwnMention, _):
            return isOwnMention
        default:
            return false
        }
    }
    
    var displayText: String {
        switch self {
        case .mention(_, let displayText), .reference(let displayText):
            return displayText
        case .undefined:
            return ""
        }
    }
    
    var isUndefined: Bool {
        switch self {
        case .undefined:
            return true
        default:
            return false
        }
    }
}
