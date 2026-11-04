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
    
    private var updateMembersTask: Task<Void, Never>?
    
    init(roomProxy: JoinedRoomProxyProtocol,
         roomListPublisher: AnyPublisher<[RoomSummary], Never>) {
        self.roomProxy = roomProxy
        
        // Search keys are built once per members or rooms update, not on every keystroke.
        let searchableMembersPublisher = roomProxy.membersPublisher
            .map { members in members.map { SearchableMember(member: $0) } }
        let searchableRoomsPublisher = roomListPublisher
            .map { roomSummaries in roomSummaries.compactMap { SearchableRoom(summary: $0) } }
        
        suggestionsPublisher = suggestionTriggerSubject
            .combineLatest(searchableMembersPublisher, searchableRoomsPublisher)
            .map { [weak self, ownUserID = roomProxy.ownUserID] suggestionTrigger, members, rooms -> [SuggestionItem] in
                guard let self,
                      let suggestionTrigger else {
                    return []
                }
                
                switch suggestionTrigger.type {
                case .user:
                    return membersSuggestions(suggestionTrigger: suggestionTrigger, members: members, ownUserID: ownUserID)
                case .room:
                    return roomSuggestions(suggestionTrigger: suggestionTrigger, rooms: rooms)
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
        let isNewUserMention = suggestionTrigger?.type == .user && suggestionTriggerSubject.value?.type != .user
        
        suggestionTriggerSubject.value = suggestionTrigger
        
        // Refresh the members each time a new user suggestion is triggered to pull in the latest profiles.
        guard isNewUserMention, updateMembersTask == nil else { return }
        
        updateMembersTask = Task { [weak self, roomProxy] in
            await roomProxy.updateMembers()
            self?.updateMembersTask = nil
        }
    }
    
    // MARK: - Private
    
    private func updateRoomInfo(_ roomInfo: RoomInfoProxyProtocol) {
        if let powerLevels = roomInfo.powerLevels {
            canMentionAllUsers = powerLevels.canOwnUserTriggerRoomNotification()
        }
    }
    
    private func membersSuggestions(suggestionTrigger: SuggestionTrigger,
                                    members: [SearchableMember],
                                    ownUserID: String) -> [SuggestionItem] {
        let query = SearchKey(suggestionTrigger.text)
        
        var membersSuggestion = members
            .filter { $0.member.userID != ownUserID && $0.member.membership == .join }
            .enumerated()
            .compactMap { index, searchableMember -> (rank: (Int, Int, Int), item: SuggestionItem)? in
                guard let match = searchableMember.match(query) else {
                    return nil
                }
                let member = searchableMember.member
                return ((match.offset, match.keyWeight, index),
                        .init(suggestionType: .user(.init(id: member.userID, displayName: member.displayName, avatarURL: member.avatarURL, status: member.status)),
                              range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text))
            }
            .sorted { $0.rank < $1.rank }
            .map(\.item)
        
        let allUsersKeys = [SearchKey(PillUtilities.everyone), SearchKey(String(PillUtilities.atRoom.dropFirst()))]
        if canMentionAllUsers,
           !roomProxy.infoPublisher.value.isDM,
           query.isEmpty || allUsersKeys.contains(where: { $0.offset(of: query) != nil }) {
            membersSuggestion
                .insert(SuggestionItem(suggestionType: .allUsers(roomProxy.details.avatar), range: suggestionTrigger.range, rawSuggestionText: suggestionTrigger.text), at: 0)
        }
        
        return membersSuggestion
    }
    
    private func roomSuggestions(suggestionTrigger: SuggestionTrigger,
                                 rooms: [SearchableRoom]) -> [SuggestionItem] {
        let query = SearchKey(suggestionTrigger.text)
        
        return rooms
            .filter { $0.matches(query) }
            .map { room in
                SuggestionItem(suggestionType: .room(.init(id: room.summary.id,
                                                           canonicalAlias: room.canonicalAlias,
                                                           name: room.summary.name,
                                                           avatar: room.summary.avatar)),
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
}

extension PillUtilities {
    static var everyone: String {
        L10n.commonEveryone
    }
}

// MARK: - Search

/// Text normalised like Element Web's autocomplete: case, diacritics and whitespace are ignored,
/// so "janeqdoe" finds "Jane Q Doe". Matches are ranked by where they start, like on Web.
private struct SearchKey {
    let value: String
    
    var isEmpty: Bool {
        value.isEmpty
    }
    
    init(_ text: String) {
        value = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).filter { !$0.isWhitespace }
    }
    
    /// Where the query starts in this key, or `nil` if it isn't in it.
    func offset(of query: SearchKey) -> Int? {
        guard let range = value.range(of: query.value) else {
            return nil
        }
        return value.distance(from: value.startIndex, to: range.lowerBound)
    }
}

private struct SearchableMember {
    let member: RoomMemberProxyProtocol
    let displayNameKey: SearchKey?
    let userIDKey: SearchKey
    
    init(member: RoomMemberProxyProtocol) {
        self.member = member
        displayNameKey = member.displayName.map { SearchKey($0) }
        userIDKey = SearchKey(String(member.userID.dropFirst()))
    }
    
    /// The earliest match, preferring the display name over the user ID when both start at the same offset.
    func match(_ query: SearchKey) -> (offset: Int, keyWeight: Int)? {
        guard !query.isEmpty else {
            return (0, 0)
        }
        let displayNameMatch = displayNameKey?.offset(of: query).map { (offset: $0, keyWeight: 0) }
        let userIDMatch = userIDKey.offset(of: query).map { (offset: $0, keyWeight: 1) }
        return [displayNameMatch, userIDMatch]
            .compactMap { $0 }
            .min { ($0.offset, $0.keyWeight) < ($1.offset, $1.keyWeight) }
    }
}

private struct SearchableRoom {
    let summary: RoomSummary
    let canonicalAlias: String
    let nameKey: SearchKey
    let aliasKey: SearchKey
    
    init?(summary: RoomSummary) {
        guard let canonicalAlias = summary.canonicalAlias else {
            return nil
        }
        self.summary = summary
        self.canonicalAlias = canonicalAlias
        nameKey = SearchKey(summary.name)
        aliasKey = SearchKey(canonicalAlias)
    }
    
    func matches(_ query: SearchKey) -> Bool {
        query.isEmpty || nameKey.offset(of: query) != nil || aliasKey.offset(of: query) != nil
    }
}
