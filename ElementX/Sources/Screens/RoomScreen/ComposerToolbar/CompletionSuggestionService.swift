//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

private enum SuggestionTriggerRegex {
    static let at = /@\w+/
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
                            return .init(suggestionType: .user(.init(id: member.userID, displayName: member.displayName, avatarURL: member.avatarURL)), range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text)
                        }
                    
                    if self.canMentionAllUsers,
                       !self.roomProxy.isDirectOneToOneRoom,
                       Self.shouldIncludeMember(userID: PillConstants.atRoom, displayName: PillConstants.everyone, searchText: suggestionTrigger.text) {
                        membersSuggestion
                            .insert(SuggestionItem(suggestionType: .allUsers(roomProxy.details.avatar), range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text), at: 0)
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
    
    func processTextMessage(_ textMessage: String, selectedRange: NSRange) {
        setSuggestionTrigger(detectTriggerInText(textMessage, selectedRange: selectedRange))
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
    
    // MARK: - Private
    
    private func detectTriggerInText(_ text: String, selectedRange: NSRange) -> SuggestionTrigger? {
        let matches = text.matches(of: SuggestionTriggerRegex.at)
        let match = matches
            .first { matchResult in
                let lowerBound = matchResult.range.lowerBound.utf16Offset(in: matchResult.base)
                let upperBound = matchResult.range.upperBound.utf16Offset(in: matchResult.base)
                return selectedRange.location >= lowerBound
                    && selectedRange.location <= upperBound
                    && selectedRange.length <= upperBound - lowerBound
            }
        
        guard let match else {
            return nil
        }
        
        var suggestionText = String(text[match.range])
        suggestionText.removeFirst()
        
        return .init(type: .user, text: suggestionText, range: NSRange(match.range, in: text))
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
