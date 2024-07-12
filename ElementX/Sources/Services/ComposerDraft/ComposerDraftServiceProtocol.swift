//
// Copyright 2024 New Vector Ltd
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
