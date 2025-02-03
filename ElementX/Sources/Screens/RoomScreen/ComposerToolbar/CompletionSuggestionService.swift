//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
                       !self.roomProxy.isDirectOneToOneRoom,
                       Self.shouldIncludeMember(userID: PillConstants.atRoom, displayName: PillConstants.everyone, searchText: suggestionTrigger.text) {
                        membersSuggestion
                            .insert(SuggestionItem.allUsers(item: .init(id: PillConstants.atRoom,
                                                                        displayName: PillConstants.everyone,
                                                                        avatarURL: self.roomProxy.infoPublisher.value.avatarURL,
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
    
    func processTextMessage(_ textMessage: String, selectedRange: NSRange) {
        setSuggestionTrigger(detectTriggerInText(textMessage, selectedRange: selectedRange))
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
    
    // MARK: - Private
    
    private func detectTriggerInText(_ text: String, selectedRange: NSRange) -> SuggestionTrigger? {
            return nil
        }
        
        var suggestionText: String?
        var range: Range<String.Index>?
        
        var startIndex: String.Index = text.startIndex
        let components = text
            .components(separatedBy: .whitespaces)
            .filter { $0.first == SuggestionTriggerPattern.at.rawValue }
        
        for component in components {
            guard let textRange = text.range(of: component, range: startIndex..<text.endIndex) else {
                continue
            }
            startIndex = textRange.upperBound
            
            let startIndex = textRange.lowerBound.utf16Offset(in: text)
            let endIndex = textRange.upperBound.utf16Offset(in: text)
            
            guard selectedRange.location >= startIndex,
                  selectedRange.location <= endIndex,
                  selectedRange.length <= endIndex - startIndex
            else {
                continue
            }
            
            suggestionText = String(text[textRange.lowerBound..<textRange.upperBound])
            suggestionText?.removeFirst()
            range = textRange
        }
        
        guard let suggestionText,
              let range else {
            return nil
        }
      
        return .init(type: .user, text: suggestionText, range: NSRange(range, in: text))
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
