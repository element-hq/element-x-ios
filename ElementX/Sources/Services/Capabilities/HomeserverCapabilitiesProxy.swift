//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct HomeserverCapabilitiesProxy: HomeserverCapabilitiesProxyProtocol {
    private let underlyingCapabilities: HomeserverCapabilitiesProtocol
    
    init(underlyingCapabilities: HomeserverCapabilitiesProtocol) {
        self.underlyingCapabilities = underlyingCapabilities
    }
    
    func refresh() async {
        do {
            try await underlyingCapabilities.refresh()
        } catch {
            MXLog.error("Failure refreshing homeserver capabilities: \(error)")
        }
    }
    
    func canChangeAvatar() async -> Bool {
        do {
            return try await underlyingCapabilities.canChangeAvatar()
        } catch {
            MXLog.error("Failure checking canChangeAvatar: \(error)")
            return true
        }
    }
    
    func canChangeDisplayName() async -> Bool {
        do {
            return try await underlyingCapabilities.canChangeDisplayname()
        } catch {
            MXLog.error("Failure checking canChangeDisplayName: \(error)")
            return true
        }
    }
}
