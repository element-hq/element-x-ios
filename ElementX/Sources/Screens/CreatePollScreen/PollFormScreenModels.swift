//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PollFormScreenViewModelAction: Equatable {
    case close
}

struct PollFormScreenViewState: BindableState {
    let mode: PollFormMode
    let maxNumberOfOptions: Int
    var bindings: PollFormScreenViewStateBindings = .init()
    
    init(mode: PollFormMode, maxNumberOfOptions: Int) {
        self.mode = mode
        self.maxNumberOfOptions = maxNumberOfOptions
        
        switch mode {
        case .new(let topic):
            bindings = .init(question: topic ?? "")
        case .edit(_, let poll):
            bindings = .init(poll: poll)
        }
    }
    
    var navigationTitle: String {
        switch mode {
        case .new:
            return L10n.screenCreatePollTitle
        case .edit:
            return L10n.screenEditPollTitle
        }
    }
    
    var submitButtonTitle: String {
        switch mode {
        case .new:
            return L10n.actionCreate
        case .edit:
            return L10n.actionDone
        }
    }
    
    var isSubmitButtonDisabled: Bool {
        switch mode {
        case .new:
            return !bindings.hasValidContent
        case .edit:
            return !bindings.hasValidContent || !formContentHasChanged
        }
    }
    
    var formContentHasChanged: Bool {
        let initialBindings: PollFormScreenViewStateBindings
        
        switch mode {
        case .new:
            initialBindings = .init()
        case .edit(_, let poll):
            initialBindings = .init(poll: poll)
        }
        
        return bindings != initialBindings
    }
}

enum PollFormMode: Hashable {
    case new(topic: String?)
    case edit(eventID: String, poll: Poll)
}

struct PollFormScreenViewStateBindings: Equatable {
    var question = ""
    var options: [Option] = [.init(), .init()] {
        didSet {
            maxSelections = clampedMaxSelections
        }
    }
    
    var maxSelections = 1 {
        didSet {
            maxSelections = clampedMaxSelections
        }
    }
    
    var isUndisclosed = false
    
    struct Option: Identifiable, Equatable {
        let id = UUID()
        var text = ""
    }
    
    var hasValidContent: Bool {
        !question.isEmpty && options.count >= 2 && options.allSatisfy { !$0.text.isEmpty } && maxSelections >= 1 && maxSelections <= options.count
    }
    
    var alertInfo: AlertInfo<UUID>?
    
    static func == (lhs: PollFormScreenViewStateBindings, rhs: PollFormScreenViewStateBindings) -> Bool {
        lhs.question == rhs.question &&
            lhs.options.map(\.text) == rhs.options.map(\.text) &&
            lhs.maxSelections == rhs.maxSelections &&
            lhs.isUndisclosed == rhs.isUndisclosed
    }
    
    private var clampedMaxSelections: Int {
        min(max(maxSelections, 1), max(options.count, 1))
    }
}

extension PollFormScreenViewStateBindings {
    init(poll: Poll) {
        self.init(question: poll.question,
                  options: poll.options.map { .init(text: $0.text) },
                  maxSelections: min(max(poll.maxSelections, 1), max(poll.options.count, 1)),
                  isUndisclosed: poll.kind == .undisclosed)
    }
}

enum PollFormScreenViewAction {
    case cancel
    case submit
    case delete
    case deleteOption(index: Int)
    case addOption
    case decrementMaxSelections
    case incrementMaxSelections
}
