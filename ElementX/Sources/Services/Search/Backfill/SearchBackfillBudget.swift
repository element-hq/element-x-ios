//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Cost limits for one execution of the search backfill.
///
/// Budgets are denominated in **pages and rooms, never events**. The app has no trustworthy event
/// count: inferring one from the timeline item list would report its largest numbers precisely when
/// nothing was indexed at all (history re-hydrated from the local event cache), which is exactly
/// backwards.
///
/// These are conservative starting points, not measurements. Each page is a network round trip of up
/// to `pageSize` events, so one execution costs at most `maxPagesPerExecution` requests. They should
/// be re-tuned against a device measurement of index growth per page.
struct SearchBackfillBudget: Equatable {
    /// Events requested per page. Matches the room polls history sweep, the only other bulk
    /// back-pagination in the app.
    var pageSize: UInt16 = 250
    
    /// Pages for a single room before moving on, so one huge room cannot starve the rest.
    ///
    /// Deliberately looser than `maxRoomDuration`, which is the effective per-room bound. Every
    /// generation walks a room from its live end, and pages served from already-cached history are
    /// charged here while indexing nothing — a tight page cap therefore walls each room at
    /// `cap × cached-chunk-size` events forever.
    var maxPagesPerRoom = 200
    
    /// Pages across the whole execution. The dominant cost control.
    var maxPagesPerExecution = 300
    
    /// Wall-clock ceiling, kept well inside the time iOS allows a background processing task.
    var executionDeadline: Duration = .seconds(300)
    
    /// Time spent on any one room, so a slow server cannot consume the whole execution.
    var maxRoomDuration: Duration = .seconds(45)
    
    /// Consecutive failures before a room is abandoned for this generation.
    var maxFailuresPerRoom = 2
    
    /// Breathing room between requests so the sweep does not monopolise the network.
    var delayBetweenPages: Duration = .milliseconds(250)
    
    /// Longer pause between rooms; the sweep is never in a hurry.
    var delayBetweenRooms: Duration = .seconds(1)
    
    /// Rooms visited in one sweep generation.
    ///
    /// `element-meta#3252` specifies "the 100 most recent rooms" for iOS, which is where this number
    /// comes from — Android's equivalent sweep uses 200.
    var roomQueueLimit = 100
}

extension SearchBackfillBudget {
    /// Used by the background task, where the device is on external power and nobody is waiting.
    static var background: SearchBackfillBudget {
        .init()
    }
    
    /// Used when the user opens search. Far tighter: this is their battery and quite possibly their
    /// cellular data, and they are waiting on the screen in front of them.
    static var foreground: SearchBackfillBudget {
        .init(maxPagesPerRoom: 10,
              maxPagesPerExecution: 30,
              executionDeadline: .seconds(30),
              maxRoomDuration: .seconds(10))
    }
}
