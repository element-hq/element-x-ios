//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

import MatrixRustSDK

struct ComposerDraftProxy: Equatable {
    enum ComposerDraftType: Equatable {
        case newMessage
        case reply(eventID: String)
        case edit(eventID: String)
        
        var toRust: MatrixRustSDK.ComposerDraftType {
            switch self {
            case .newMessage:
                return .newMessage
            case .edit(let eventID):
                return .edit(eventId: eventID)
            case .reply(let eventID):
                return .reply(eventId: eventID)
            }
        }
        
        init(from rustDraftType: MatrixRustSDK.ComposerDraftType) {
            switch rustDraftType {
            case .newMessage:
                self = .newMessage
            case .edit(let eventID):
                self = .edit(eventID: eventID)
            case .reply(let eventID):
                self = .reply(eventID: eventID)
            }
        }
    }
    
    let plainText: String
    let htmlText: String?
    let draftType: ComposerDraftType
    
    var toRust: ComposerDraft {
        ComposerDraft(plainText: plainText, htmlText: htmlText, draftType: draftType.toRust)
    }
}

extension ComposerDraftProxy {
    init(from rustDraft: ComposerDraft) {
        plainText = rustDraft.plainText
        htmlText = rustDraft.htmlText
        draftType = ComposerDraftType(from: rustDraft.draftType)
    }
}

enum ComposerDraftServiceError: Error {
    case failedToLoadDraft
    case failedToLoadReply
    case failedToSaveDraft
    case failedToClearDraft
}

// sourcery: AutoMockable
protocol ComposerDraftServiceProtocol {
    func saveDraft(_ draft: ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError>
    func saveVolatileDraft(_ draft: ComposerDraftProxy)
    func loadDraft() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError>
    func loadVolatileDraft() -> ComposerDraftProxy?
    func clearDraft() async -> Result<Void, ComposerDraftServiceError>
    func clearVolatileDraft()
    func getReply(eventID: String) async -> Result<TimelineItemReply, ComposerDraftServiceError>
}
