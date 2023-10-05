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

import WysiwygComposer

struct SuggestionTrigger {
    enum SuggestionType {
        case user
    }
    
    let type: SuggestionType
    let text: String
}

// sourcery: AutoMockable
protocol CompletionSuggestionServiceProtocol {
    // To be removed once we suggestions and mentions are always enabled
    var areSuggestionsEnabled: Bool { get }
    var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> { get }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?)
    func setMembers(_ members: [RoomMemberProxyProtocol])
}

final class CompletionSuggestionService: CompletionSuggestionServiceProtocol {
    let areSuggestionsEnabled: Bool
    let suggestionsPublisher: AnyPublisher<[SuggestionItem], Never>
    
    private let suggestionTriggerSubject = CurrentValueSubject<SuggestionTrigger?, Never>(nil)
    private let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
    
    init(areSuggestionsEnabled: Bool) {
        self.areSuggestionsEnabled = areSuggestionsEnabled
        if areSuggestionsEnabled {
            suggestionsPublisher = suggestionTriggerSubject
                .combineLatest(membersSubject)
                .map { suggestionTrigger, members -> [SuggestionItem] in
                    guard let suggestionTrigger else {
                        return []
                    }
                    
                    switch suggestionTrigger.type {
                    case .user:
                        return members.filter { member in
                            let containedInUserID = member.userID.lowercased().contains(suggestionTrigger.text.lowercased())
                            let containedInDisplayName = (member.displayName ?? "").lowercased().contains(suggestionTrigger.text.lowercased())
                            
                            return containedInUserID || containedInDisplayName
                        }
                        .map { SuggestionItem.user(item: .init(id: $0.userID, displayName: $0.displayName, avatarURL: $0.avatarURL)) }
                    }
                }
                .eraseToAnyPublisher()
        } else {
            suggestionsPublisher = Empty().eraseToAnyPublisher()
        }
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
    
    func setMembers(_ members: [RoomMemberProxyProtocol]) {
        membersSubject.value = members
    }
}

extension SuggestionPattern {
    var toTrigger: SuggestionTrigger? {
        switch key {
        case .at:
            return SuggestionTrigger(type: .user, text: text)
        // Not yet supported
        default:
            return nil
        }
    }
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
