//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation

enum LiveLocationManagerError: Error {
    case roomNotJoined
    case startFailed
}

// sourcery: AutoMockable
protocol LiveLocationManagerProtocol: AnyObject {
    /// Publishes the current location authorization status.
    var authorizationStatus: CurrentValuePublisher<CLAuthorizationStatus, Never> { get }

    /// Requests "Always" location authorization from the user if the system allows it.
    ///
    /// - Returns: `true` if the request was forwarded to the system and a prompt will be shown;
    ///            `false` if the request was already made before and iOS would silently ignore it.
    @discardableResult
    func requestAlwaysAuthorizationIfPossible() -> Bool
    
    /// Starts sharing live location in a room.
    ///
    /// - Parameters:
    ///   - roomID: The identifier of the room to share live location in.
    ///   - duration: How long the live location should be shared.
    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationManagerError>
    
    /// Stops sharing live location in a room.
    ///
    /// Sends a stop event to the room (best effort) and removes it from the tracked sessions.
    /// Can also be used to stop a live location share started by another device.
    /// - Parameter roomID: The identifier of the room to stop sharing live location in.
    func stopLiveLocation(roomID: String) async
}
