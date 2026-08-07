//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import os
import Sentry

/// RIG (dogfood instrumentation): per-launch metrics to quantify the preview-prefill /
/// startup-time work against stock builds. Collects wall-clock milestones, how long the
/// visible room list takes to settle, how long stale previews stay on screen, and the
/// SDK's network bandwidth. Reports once per launch, ~2s after the visible list goes
/// quiet: one greppable MXLog line (for console scraping) and one Sentry "Launch metrics"
/// transaction carrying the same values as measurements.
nonisolated enum LaunchMetrics {
    struct Traffic: Sendable {
        let uploadedBytes: UInt64
        let downloadedBytes: UInt64
        let requestCount: UInt64
    }

    private struct State: Sendable {
        var roomsShown: Date?
        var roomListRunning: Date?
        var lastVisibleChurn: Date?
        var trafficAtRoomsShown: Traffic?
        var trafficProvider: (@Sendable () -> Traffic?)?
        var reporterStarted = false
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    /// Kernel fork timestamp of this process. Beware: iOS prewarming can inflate windows
    /// measured from here on Release builds; `stale_exposure` and `settle` are deltas
    /// between in-session milestones and are immune.
    private static let processStart: Date = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return Date() }
        let tv = info.kp_proc.p_starttime
        return Date(timeIntervalSince1970: TimeInterval(tv.tv_sec) + TimeInterval(tv.tv_usec) / 1_000_000)
    }()

    /// How long the visible list must stay unchanged to count as settled.
    private static let settleQuietPeriod: TimeInterval = 2.0
    /// Give up waiting for quiescence this long after the rooms appear (busy accounts
    /// receive live traffic continuously; the metric is then "still churning at cap").
    private static let settleCap: TimeInterval = 60.0

    /// Wired up by ClientProxy once the SDK client exists.
    static func setTrafficProvider(_ provider: @escaping @Sendable () -> Traffic?) {
        state.withLock { $0.trafficProvider = provider }
    }

    /// The room list service applied its first sync round (first write wins).
    static func noteRoomListRunning() {
        state.withLock {
            if $0.roomListRunning == nil { $0.roomListRunning = Date() }
        }
    }

    /// A diff batch changed what the top of the visible room list renders.
    static func noteVisibleChurn() {
        state.withLock { $0.lastVisibleChurn = Date() }
    }

    /// The home screen flipped from skeletons to real rooms: snapshot traffic and start
    /// the one-shot settle watcher.
    static func noteRoomsShown() {
        let shouldStartReporter: Bool = state.withLock {
            guard $0.roomsShown == nil else { return false }
            $0.roomsShown = Date()
            $0.trafficAtRoomsShown = $0.trafficProvider?()
            guard !$0.reporterStarted else { return false }
            $0.reporterStarted = true
            return true
        }

        guard shouldStartReporter else { return }

        Task.detached(priority: .utility) {
            let start = Date()
            while Date().timeIntervalSince(start) < settleCap {
                try? await Task.sleep(for: .milliseconds(500))

                let (running, lastChurn, shown): (Date?, Date?, Date?) = state.withLock {
                    ($0.roomListRunning, $0.lastVisibleChurn, $0.roomsShown)
                }

                // Settled: the first sync round has been applied AND the visible list
                // has been quiet for the full quiet period.
                if running != nil,
                   Date().timeIntervalSince(lastChurn ?? shown ?? start) >= settleQuietPeriod {
                    report(cappedAfter: nil)
                    return
                }
            }
            report(cappedAfter: settleCap)
        }
    }

    // MARK: - Private

    private static func report(cappedAfter: TimeInterval?) {
        let snapshot = state.withLock { $0 }
        guard let roomsShown = snapshot.roomsShown else { return }

        let settled = snapshot.lastVisibleChurn ?? roomsShown
        let trafficNow = snapshot.trafficProvider?()

        func ms(_ date: Date?) -> Int? {
            date.map { Int($0.timeIntervalSince(processStart) * 1000) }
        }

        let roomsShownMS = ms(roomsShown) ?? -1
        let runningMS = ms(snapshot.roomListRunning) ?? -1
        let settledMS = ms(settled) ?? -1
        let staleExposureMS = max(0, settledMS - roomsShownMS)

        let paintTraffic = snapshot.trafficAtRoomsShown

        MXLog.info("""
        LaunchMetrics: rooms_shown_ms=\(roomsShownMS) room_list_running_ms=\(runningMS) \
        visible_settled_ms=\(settledMS) stale_exposure_ms=\(staleExposureMS) \
        bytes_down_at_paint=\(paintTraffic?.downloadedBytes ?? 0) \
        bytes_up_at_paint=\(paintTraffic?.uploadedBytes ?? 0) \
        bytes_down=\(trafficNow?.downloadedBytes ?? 0) \
        bytes_up=\(trafficNow?.uploadedBytes ?? 0) \
        requests=\(trafficNow?.requestCount ?? 0) \
        capped=\(cappedAfter != nil)
        """)

        let transaction = SentrySDK.startTransaction(name: "Launch metrics", operation: "launch")
        func measure(_ name: String, _ value: Int, unit: MeasurementUnit) {
            transaction.setMeasurement(name: name, value: NSNumber(value: value), unit: unit)
        }
        measure("rooms_shown", roomsShownMS, unit: MeasurementUnitDuration.millisecond)
        measure("room_list_running", runningMS, unit: MeasurementUnitDuration.millisecond)
        measure("visible_settled", settledMS, unit: MeasurementUnitDuration.millisecond)
        measure("stale_exposure", staleExposureMS, unit: MeasurementUnitDuration.millisecond)
        if let paintTraffic {
            measure("bytes_down_at_paint", Int(paintTraffic.downloadedBytes), unit: MeasurementUnitInformation.byte)
            measure("bytes_up_at_paint", Int(paintTraffic.uploadedBytes), unit: MeasurementUnitInformation.byte)
        }
        if let trafficNow {
            measure("bytes_down", Int(trafficNow.downloadedBytes), unit: MeasurementUnitInformation.byte)
            measure("bytes_up", Int(trafficNow.uploadedBytes), unit: MeasurementUnitInformation.byte)
            measure("requests", Int(trafficNow.requestCount), unit: MeasurementUnit(unit: "none"))
        }
        transaction.setTag(value: cappedAfter != nil ? "true" : "false", key: "settle_capped")
        transaction.finish()
    }
}
