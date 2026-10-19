//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation

enum LiveLocationServiceError: Error {
    case roomNotJoined
    case startFailed
}

/// What an account's service asks of the `LiveLocationManager`, which owns the system location manager.
enum LiveLocationServiceAction {
    case requestAlwaysAuthorization
}

// sourcery: AutoMockable
protocol LiveLocationServiceProtocol: AnyObject {
    var userID: String { get }
    var actionsPublisher: AnyPublisher<LiveLocationServiceAction, Never> { get }
    
    /// Whether this account is sharing its live location in at least one room.
    var isSharingPublisher: CurrentValuePublisher<Bool, Never> { get }
    /// The app's location authorization status.
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
    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationServiceError>
    
    /// Stops sharing live location in a room.
    ///
    /// Sends a stop event to the room (best effort) and removes it from the tracked sessions.
    /// Can also be used to stop a live location share started by another device.
    /// - Parameter roomID: The identifier of the room to stop sharing live location in.
    func stopLiveLocation(roomID: String) async
    
    func authorizationStatusChanged(to status: CLAuthorizationStatus)
    /// Sends the location to the rooms this account is sharing in.
    func locationUpdated(_ coordinate: CLLocationCoordinate2D)
    /// Stops every share, e.g. when the authorization is lost or before signing out.
    func stopAllLiveLocations() async
}
