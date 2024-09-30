//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol PollInteractionHandlerProtocol {
    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error>
    func endPoll(pollStartID: String) async -> Result<Void, Error>
}

// sourcery: AutoMockable
extension PollInteractionHandlerProtocol { }
