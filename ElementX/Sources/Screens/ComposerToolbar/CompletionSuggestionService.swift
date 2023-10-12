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
    private var canMentionAllUsers = false
    let areSuggestionsEnabled: Bool
    private(set) var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> = Empty().eraseToAnyPublisher()
    
    private let suggestionTriggerSubject = CurrentValueSubject<SuggestionPattern?, Never>(nil)
    
    init(roomProxy: RoomProxyProtocol, areSuggestionsEnabled: Bool) {
        self.areSuggestionsEnabled = areSuggestionsEnabled
        guard areSuggestionsEnabled else {
            return
        }
        suggestionsPublisher = suggestionTriggerSubject
            .combineLatest(roomProxy.members)
            .map { [weak self] suggestionPattern, members -> [SuggestionItem] in
                guard let suggestionPattern else {
                    return []
                }
                
                switch suggestionPattern.type {
                case .user:
                    var membersSuggestion = members
                        .compactMap { member -> SuggestionItem? in
                            guard !member.isAccountOwner,
                                  member.membership == .join,
                                  Self.isIncluded(suggestionPattern: suggestionPattern, userID: member.userID, displayName: member.displayName) else {
                                return nil
                            }
                            return SuggestionItem.user(item: .init(id: member.userID, displayName: member.displayName, avatarURL: member.avatarURL))
                        }
                    if self?.canMentionAllUsers == true,
                       Self.isIncluded(suggestionPattern: suggestionPattern, userID: PillConstants.atRoom, displayName: PillConstants.everyone) {
                        membersSuggestion
                            .append(SuggestionItem.allUsers(item: .allUsersMention(roomAvatar: roomProxy.avatarURL)))
                    }
                    return membersSuggestion
                }
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        Task {
            switch await roomProxy.canUserTriggerRoomNotification(userID: roomProxy.ownUserID) {
            case .success(let value):
                canMentionAllUsers = value
            case .failure:
                canMentionAllUsers = false
            }
        }
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionPattern?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
    
    private static func isIncluded(suggestionPattern: SuggestionPattern, userID: String, displayName: String?) -> Bool {
        let containedInUserID = userID.localizedStandardContains(suggestionPattern.text.lowercased())
        
        let containedInDisplayName: Bool
        if let displayName {
            containedInDisplayName = displayName.localizedStandardContains(suggestionPattern.text.lowercased())
        } else {
            containedInDisplayName = false
        }
        
        return containedInUserID || containedInDisplayName
    }
}
