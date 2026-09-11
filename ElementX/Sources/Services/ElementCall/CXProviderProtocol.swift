//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CallKit

// sourcery: AutoMockable
protocol CXProviderProtocol {
    func setDelegate(_ delegate: CXProviderDelegate?, queue: DispatchQueue?)
    func reportNewIncomingCall(with uuid: UUID, update: CXCallUpdate, completion: @escaping @Sendable (Error?) -> Void)
    func reportCall(with uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)
    func reportOutgoingCall(with uuid: UUID, startedConnectingAt: Date?)
    func reportOutgoingCall(with uuid: UUID, connectedAt: Date?)
    func reportCall(with uuid: UUID, updated update: CXCallUpdate)
}

extension CXProvider: CXProviderProtocol { }
