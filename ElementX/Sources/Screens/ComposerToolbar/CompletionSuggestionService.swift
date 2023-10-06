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
import Foundation

final class CompletionSuggestionService: CompletionSuggestionServiceProtocol {
    let areSuggestionsEnabled: Bool
    let suggestionsPublisher: AnyPublisher<[SuggestionItem], Never>
    
    private let suggestionTriggerSubject = CurrentValueSubject<SuggestionPattern?, Never>(nil)
    
    init(roomProxy: RoomProxyProtocol, areSuggestionsEnabled: Bool) {
        self.areSuggestionsEnabled = areSuggestionsEnabled
        guard areSuggestionsEnabled else {
            suggestionsPublisher = Empty().eraseToAnyPublisher()
            return
        }
        suggestionsPublisher = suggestionTriggerSubject
            .combineLatest(roomProxy.members)
            .map { suggestionTrigger, members -> [SuggestionItem] in
                guard let suggestionTrigger else {
                    return []
                }
                
                switch suggestionTrigger.type {
                case .user:
                    return members.filter { member in
                        guard !member.isAccountOwner && member.membership == .join else {
                            return false
                        }
                        
                        let containedInUserID = member.userID.localizedStandardContains(suggestionTrigger.text.lowercased())
                        
                        let containedInDisplayName: Bool
                        if let displayName = member.displayName {
                            containedInDisplayName = displayName.localizedStandardContains(suggestionTrigger.text.lowercased())
                        } else {
                            containedInDisplayName = false
                        }
                        
                        return containedInUserID || containedInDisplayName
                    }
                    .map { SuggestionItem.user(item: .init(id: $0.userID, displayName: $0.displayName, avatarURL: $0.avatarURL)) }
                }
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionPattern?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
}
