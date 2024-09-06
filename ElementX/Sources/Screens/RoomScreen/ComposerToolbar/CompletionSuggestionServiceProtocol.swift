//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import WysiwygComposer

struct SuggestionTrigger: Equatable {
    enum SuggestionType: Equatable {
        case user
    }
    
    let type: SuggestionType
    let text: String
    let range: NSRange
}

enum SuggestionItem: Identifiable, Equatable {
    case user(item: MentionSuggestionItem)
    case allUsers(item: MentionSuggestionItem)
    
    var id: String {
        switch self {
        case .user(let user):
            return user.id
        case .allUsers:
            return PillConstants.atRoom
        }
    }
    
    var range: NSRange {
        switch self {
        case .user(let item), .allUsers(let item):
            return item.range
        }
    }
}

struct MentionSuggestionItem: Identifiable, Equatable {
    let id: String
    let displayName: String?
    let avatarURL: URL?
    let range: NSRange
}

// sourcery: AutoMockable
protocol CompletionSuggestionServiceProtocol {
    var suggestionsPublisher: AnyPublisher<[SuggestionItem], Never> { get }
    
    func processTextMessage(_ textMessage: String?)
    
    func setSuggestionTrigger(_ suggestionTrigger: SuggestionTrigger?)
}

extension WysiwygComposer.SuggestionPattern {
    var toElementPattern: SuggestionTrigger? {
        switch key {
        case .at:
            return SuggestionTrigger(type: .user, text: text, range: .init(location: Int(start), length: Int(end)))
        default:
            return nil
        }
    }
}

extension CompletionSuggestionServiceMock {
    struct CompletionSuggestionServiceMockConfiguration {
        var suggestions: [SuggestionItem] = []
    }
    
    convenience init(configuration: CompletionSuggestionServiceMockConfiguration) {
        self.init()
        underlyingSuggestionsPublisher = Just(configuration.suggestions).eraseToAnyPublisher()
    }
}
