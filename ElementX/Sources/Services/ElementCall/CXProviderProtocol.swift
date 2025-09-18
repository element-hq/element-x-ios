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
    func reportNewIncomingCall(with uuid: UUID, update: CXCallUpdate, completion: @escaping (Error?) -> Void)
    func reportCall(with uuid: UUID, endedAt: Date?, reason: CXCallEndedReason)
}

extension CXProvider: CXProviderProtocol { }
