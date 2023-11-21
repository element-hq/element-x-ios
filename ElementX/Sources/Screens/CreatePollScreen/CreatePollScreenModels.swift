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
    case create(question: String, options: [String], pollKind: Poll.Kind)
    case cancel
}

struct CreatePollScreenViewState: BindableState {
    let mode: CreatePollMode
    let maxNumberOfOptions = 20
    var bindings: CreatePollScreenViewStateBindings = .init()
    
    var navigationTitle: String {
        switch mode {
        case .new:
            return L10n.screenCreatePollTitle
        case .edit(let eventID):
            #warning("AG: localise me")
            return "Edit poll"
        }
    }
}

enum CreatePollMode: Hashable {
    case new
    case edit(eventID: String)
}

struct CreatePollScreenViewStateBindings {
    var question = ""
    var options: [Option] = [.init(), .init()]
    var isUndisclosed = false

    struct Option: Identifiable, Equatable {
        let id = UUID()
        var text = ""
    }

    var isCreateButtonDisabled: Bool {
        question.isEmpty || options.count < 2 || options.contains { $0.text.isEmpty }
    }

    var hasContent: Bool {
        !question.isEmpty || options.contains(where: { !$0.text.isEmpty }) || isUndisclosed
    }

    var alertInfo: AlertInfo<UUID>?
}

enum CreatePollScreenViewAction {
    case cancel
    case create
    case deleteOption(index: Int)
    case addOption
}
