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

// sourcery: AutoMockable
protocol CompletionSuggestionServiceProtocol {
    // To be removed once we suggestions and mentions are always enabled
    var areSuggestionsEnabled: Bool { get }
    var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> { get }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionPattern?)
}

extension CompletionSuggestionServiceMock {
    struct CompletionSuggestionServiceMockConfiguration {
        var areSuggestionsEnabled = true
        var suggestions: [SuggestionItem] = []
    }
    
    convenience init(configuration: CompletionSuggestionServiceMockConfiguration) {
        self.init()
        underlyingAreSuggestionsEnabled = configuration.areSuggestionsEnabled
        underlyingSuggestionsPublisher = Just(configuration.suggestions).eraseToAnyPublisher()
    }
}
