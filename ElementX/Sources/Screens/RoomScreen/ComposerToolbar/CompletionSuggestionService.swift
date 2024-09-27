//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

private enum SuggestionTriggerPattern: Character {
    case at = "@"
}

final class CompletionSuggestionService: CompletionSuggestionServiceProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private var canMentionAllUsers = false
    private(set) var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> = Empty().eraseToAnyPublisher()
    
    private let suggestionTriggerSubject = CurrentValueSubject<SuggestionTrigger?, Never>(nil)
    
    init(roomProxy: JoinedRoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        suggestionsPublisher = suggestionTriggerSubject
            .combineLatest(roomProxy.membersPublisher)
            .map { [weak self, ownUserID = roomProxy.ownUserID] suggestionTrigger, members -> [SuggestionItem] in
                guard let self,
                      let suggestionTrigger else {
                    return []
                }
                
                switch suggestionTrigger.type {
                case .user:
                    var membersSuggestion = members
                        .compactMap { member -> SuggestionItem? in
                            guard member.userID != ownUserID,
                                  member.membership == .join,
                                  Self.shouldIncludeMember(userID: member.userID, displayName: member.displayName, searchText: suggestionTrigger.text) else {
                                return nil
                            }
                            return SuggestionItem.user(item: .init(id: member.userID,
                                                                   displayName: member.displayName,
                                                                   avatarURL: member.avatarURL,
                                                                   range: suggestionTrigger.range))
                        }
                    
                    if self.canMentionAllUsers,
                       !self.roomProxy.isEncryptedOneToOneRoom,
                       Self.shouldIncludeMember(userID: PillConstants.atRoom, displayName: PillConstants.everyone, searchText: suggestionTrigger.text) {
                        membersSuggestion
                            .insert(SuggestionItem.allUsers(item: .init(id: PillConstants.atRoom,
                                                                        displayName: PillConstants.everyone,
                                                                        avatarURL: self.roomProxy.avatarURL,
                                                                        range: suggestionTrigger.range)), at: 0)
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
    
    func processTextMessage(_ textMessage: String?) {
        setSuggestionTrigger(detectTriggerInText(textMessage))
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
    
    // MARK: - Private
    
    private func detectTriggerInText(_ text: String?) -> SuggestionTrigger? {
        guard let text else {
            return nil
        }
        
        let components = text.components(separatedBy: .whitespaces)
        
        guard var lastComponent = components.last,
              let range = text.range(of: lastComponent, options: .backwards),
              lastComponent.count > 0,
              let suggestionKey = SuggestionTriggerPattern(rawValue: lastComponent.removeFirst()),
              // If a second character exists and is the same as the key it shouldn't trigger.
              lastComponent.first != suggestionKey.rawValue else {
            return nil
        }
        
        return .init(type: .user, text: lastComponent, range: NSRange(range, in: text))
    }
    
    private static func shouldIncludeMember(userID: String, displayName: String?, searchText: String) -> Bool {
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
