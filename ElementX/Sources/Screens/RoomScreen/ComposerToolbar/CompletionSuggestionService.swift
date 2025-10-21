//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

private enum SuggestionTriggerRegex {
    /// Matches any string of characters after an @ or # that is not a whitespace
    static let atOrHash = /[@#]\S*/
    
    static let at: Character = "@"
    static let hash: Character = "#"
}

final class CompletionSuggestionService: CompletionSuggestionServiceProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private var canMentionAllUsers = false
    
    private(set) var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> = Empty().eraseToAnyPublisher()
    
    private let suggestionTriggerSubject = CurrentValueSubject<SuggestionTrigger?, Never>(nil)
    
    private var cancellables = Set<AnyCancellable>()
    
    init(roomProxy: JoinedRoomProxyProtocol,
         roomListPublisher: AnyPublisher<[RoomSummary], Never>) {
        self.roomProxy = roomProxy
        
        suggestionsPublisher = suggestionTriggerSubject
            .combineLatest(roomProxy.membersPublisher, roomListPublisher)
            .map { [weak self, ownUserID = roomProxy.ownUserID] suggestionTrigger, members, roomSummaries -> [SuggestionItem] in
                guard let self,
                      let suggestionTrigger else {
                    return []
                }
                
                switch suggestionTrigger.type {
                case .user:
                    return membersSuggestions(suggestionTrigger: suggestionTrigger, members: members, ownUserID: ownUserID)
                case .room:
                    return roomSuggestions(suggestionTrigger: suggestionTrigger, roomSummaries: roomSummaries)
                }
            }
            // We only debounce if the suggestion is nil
            .debounceAndRemoveDuplicates(on: DispatchQueue.main) { [weak self] _ in
                self?.suggestionTriggerSubject.value != nil ? .milliseconds(500) : .milliseconds(0)
            }
        
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo)
            }
            .store(in: &cancellables)
        
        updateRoomInfo(roomProxy.infoPublisher.value)
    }
    
    func processTextMessage(_ textMessage: String, selectedRange: NSRange) {
        setSuggestionTrigger(detectTriggerInText(textMessage, selectedRange: selectedRange))
    }
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?) {
        suggestionTriggerSubject.value = suggestionTrigger
    }
    
    // MARK: - Private
    
    private func updateRoomInfo(_ roomInfo: RoomInfoProxyProtocol) {
        if let powerLevels = roomProxy.infoPublisher.value.powerLevels {
            canMentionAllUsers = powerLevels.canOwnUserTriggerRoomNotification()
        }
    }
    
    private func membersSuggestions(suggestionTrigger: SuggestionTrigger,
                                    members: [RoomMemberProxyProtocol],
                                    ownUserID: String) -> [SuggestionItem] {
        var membersSuggestion = members
            .compactMap { member -> SuggestionItem? in
                guard member.userID != ownUserID,
                      member.membership == .join,
                      Self.shouldIncludeMember(userID: member.userID, displayName: member.displayName, searchText: suggestionTrigger.text) else {
                    return nil
                }
                return .init(suggestionType: .user(.init(id: member.userID, displayName: member.displayName, avatarURL: member.avatarURL)), range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text)
            }
        
        if canMentionAllUsers,
           !roomProxy.isDirectOneToOneRoom,
           Self.shouldIncludeMember(userID: PillUtilities.atRoom, displayName: PillUtilities.everyone, searchText: suggestionTrigger.text) {
            membersSuggestion
                .insert(SuggestionItem(suggestionType: .allUsers(roomProxy.details.avatar), range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text), at: 0)
        }
        
        return membersSuggestion
    }
    
    private func roomSuggestions(suggestionTrigger: SuggestionTrigger,
                                 roomSummaries: [RoomSummary]) -> [SuggestionItem] {
        roomSummaries
            .compactMap { roomSummary -> SuggestionItem? in
                guard let canonicalAlias = roomSummary.canonicalAlias,
                      Self.shouldIncludeRoom(roomName: roomSummary.name, roomAlias: canonicalAlias, searchText: suggestionTrigger.text) else {
                    return nil
                }
                
                return .init(suggestionType: .room(.init(id: roomSummary.id,
                                                         canonicalAlias: canonicalAlias,
                                                         name: roomSummary.name,
                                                         avatar: roomSummary.avatar)),
                             range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text)
            }
    }
    
    private func detectTriggerInText(_ text: String, selectedRange: NSRange) -> SuggestionTrigger? {
        let matches = text.matches(of: SuggestionTriggerRegex.atOrHash)
        let match = matches.first { matchResult in
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
        let firstChar = suggestionText.removeFirst()
        
        switch firstChar {
        case SuggestionTriggerRegex.at:
            return .init(type: .user, text: suggestionText, range: NSRange(match.range, in: text))
        case SuggestionTriggerRegex.hash:
            return .init(type: .room, text: suggestionText, range: NSRange(match.range, in: text))
        default:
            return nil
        }
    }
    
    private static func shouldIncludeMember(userID: String, displayName: String?, searchText: String) -> Bool {
        // If the search text is empty give back all the results
        guard !searchText.isEmpty else {
            return true
        }
        let containedInUserID = userID.localizedStandardContains(searchText)
        
        let containedInDisplayName: Bool
        if let displayName {
            containedInDisplayName = displayName.localizedStandardContains(searchText)
        } else {
            containedInDisplayName = false
        }
        
        return containedInUserID || containedInDisplayName
    }
    
    private static func shouldIncludeRoom(roomName: String, roomAlias: String, searchText: String) -> Bool {
        // If the search text is empty give back all the results
        guard !searchText.isEmpty else {
            return true
        }
        return roomName.localizedStandardContains(searchText) || roomAlias.localizedStandardContains(searchText)
    }
}

extension PillUtilities {
    static var everyone: String {
        L10n.commonEveryone
    }
}
