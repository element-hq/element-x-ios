//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

enum CreatePollScreenViewModelAction {
    case submit(question: String, options: [String], pollKind: Poll.Kind)
    case cancel
}

struct CreatePollScreenViewState: BindableState {
    let mode: CreatePollMode
    let maxNumberOfOptions = 20
    var bindings: CreatePollScreenViewStateBindings = .init()
    
    init(mode: CreatePollMode) {
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
            #warning("AG: localise me")
            return "Edit poll"
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
        let initialBindings: CreatePollScreenViewStateBindings
        
        switch mode {
        case .new:
            initialBindings = .init()
        case .edit(_, let poll):
            initialBindings = .init(poll: poll)
        }

        return bindings != initialBindings
    }
}

enum CreatePollMode: Hashable {
    case new
    case edit(eventID: String, poll: Poll)
}

struct CreatePollScreenViewStateBindings: Equatable {
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
    
    static func == (lhs: CreatePollScreenViewStateBindings, rhs: CreatePollScreenViewStateBindings) -> Bool {
        lhs.question == rhs.question && lhs.options.map(\.text) == rhs.options.map(\.text) && lhs.isUndisclosed == rhs.isUndisclosed
    }
}

extension CreatePollScreenViewStateBindings {
    init(poll: Poll) {
        self.init(question: poll.question,
                  options: poll.options.map { .init(text: $0.text) },
                  isUndisclosed: poll.kind == .undisclosed)
    }
}

enum CreatePollScreenViewAction {
    case cancel
    case submit
    case delete
    case deleteOption(index: Int)
    case addOption
}
