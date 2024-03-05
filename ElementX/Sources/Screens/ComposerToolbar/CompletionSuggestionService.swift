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
    private let roomProxy: RoomProxyProtocol
    private var canMentionAllUsers = false
    private(set) var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> = Empty().eraseToAnyPublisher()
    
    private let suggestionTriggerSubject = CurrentValueSubject<SuggestionPattern?, Never>(nil)
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        suggestionsPublisher = suggestionTriggerSubject
            .combineLatest(roomProxy.membersPublisher)
            .map { [weak self, ownUserID = roomProxy.ownUserID] suggestionPattern, members -> [SuggestionItem] in
                guard let self,
                      let suggestionPattern else {
                    return []
                }
                
                switch suggestionPattern.type {
                case .user:
                    var membersSuggestion = members
                        .compactMap { member -> SuggestionItem? in
                            guard member.userID != ownUserID,
                                  member.membership == .join,
                                  Self.isIncluded(searchText: suggestionPattern.text, userID: member.userID, displayName: member.displayName) else {
                                return nil
                            }
                            return SuggestionItem.user(item: .init(id: member.userID, displayName: member.displayName, avatarURL: member.avatarURL))
                        }
                    if self.canMentionAllUsers,
                       !self.roomProxy.isEncryptedOneToOneRoom,
                       Self.isIncluded(searchText: suggestionPattern.text, userID: PillConstants.atRoom, displayName: PillConstants.everyone) {
                        membersSuggestion
                            .insert(SuggestionItem.allUsers(item: .allUsersMention(roomAvatar: self.roomProxy.avatarURL)), at: 0)
                    }
                    return membersSuggestion
                }
            }
            // We only debounce if the suggestion is nil
            .debounceAndRemoveDuplicates(on: DispatchQueue.main) { [weak self] _ in
                self?.suggestionTriggerSubject.value != nil ? .milliseconds(500) : .milliseconds(0)
            }
        
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
    
    private static func isIncluded(searchText: String, userID: String, displayName: String?) -> Bool {
        // If the search text is empty give back all the results
        guard !searchText.isEmpty else {
            return true
        }
        let containedInUserID = userID.localizedStandardContains(searchText.lowercased())
        
        let containedInDisplayName: Bool
        if let displayName {
            containedInDisplayName = displayName.localizedStandardContains(searchText.lowercased())
        } else {
            containedInDisplayName = false
        }
        
        return containedInUserID || containedInDisplayName
    }
}
