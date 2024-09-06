//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum PollFormScreenViewModelAction: Equatable {
    case cancel
    case delete
    case submit(question: String, options: [String], pollKind: Poll.Kind)
}

struct PollFormScreenViewState: BindableState {
    let mode: PollFormMode
    let maxNumberOfOptions = 20
    var bindings: PollFormScreenViewStateBindings = .init()
    
    init(mode: PollFormMode) {
        self.mode = mode
        
        switch mode {
        case .new:
            bindings = .init()
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
    case new
    case edit(eventID: String, poll: Poll)
}

struct PollFormScreenViewStateBindings: Equatable {
    var question = ""
    var options: [Option] = [.init(), .init()]
    var isUndisclosed = false

    struct Option: Identifiable, Equatable {
        let id = UUID()
        var text = ""
    }

    var hasValidContent: Bool {
        !question.isEmpty && options.count >= 2 && options.allSatisfy { !$0.text.isEmpty }
    }

    var alertInfo: AlertInfo<UUID>?
    
    static func == (lhs: PollFormScreenViewStateBindings, rhs: PollFormScreenViewStateBindings) -> Bool {
        lhs.question == rhs.question && lhs.options.map(\.text) == rhs.options.map(\.text) && lhs.isUndisclosed == rhs.isUndisclosed
    }
}

extension PollFormScreenViewStateBindings {
    init(poll: Poll) {
        self.init(question: poll.question,
                  options: poll.options.map { .init(text: $0.text) },
                  isUndisclosed: poll.kind == .undisclosed)
    }
}

enum PollFormScreenViewAction {
    case cancel
    case submit
    case delete
    case deleteOption(index: Int)
    case addOption
}
