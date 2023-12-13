//
// Copyright 2023 New Vector Ltd
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

import Combine

struct SuggestionPattern: Equatable {
    enum SuggestionType: Equatable {
        case user
    }
    
    let type: SuggestionType
    let text: String
}

// periphery: ignore - markdown protocol
protocol ComposerToolbarViewModelProtocol {
    var actions: AnyPublisher<ComposerToolbarViewModelAction, Never> { get }
    var context: ComposerToolbarViewModelType.Context { get }
    func process(roomAction: RoomScreenComposerAction)
}
