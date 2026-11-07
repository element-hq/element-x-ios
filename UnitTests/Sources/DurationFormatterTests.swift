//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct DurationFormatterTests {
    @Test("Durations use the biggest exact unit",
          arguments: [(60.0, "1 minute"),
                      (3600, "1 hour"),
                      (28800, "8 hours"),
                      (86400, "1 day"),
                      (604_800, "1 week"),
                      (1_209_600, "2 weeks"),
                      (2_592_000, "30 days"),
                      (7_776_000, "90 days"),
                      (31_536_000, "1 year"),
                      (94_608_000, "3 years"),
                      (90, "2 minutes"),
                      (30, "1 minute"),
                      (5400, "90 minutes"),
                      (2_851_200, "33 days")])
    func biggestUnit(duration: TimeInterval, expected: String) {
        #expect(DurationFormatter.string(for: duration) == expected)
    }
    
    @Test("Only the given units are used, rounding up in the smallest one",
          arguments: [(31_536_000.0, [DurationFormatter.Unit.day], "365 days"),
                      (604_800, [.day], "7 days"),
                      (129_600, [.day], "2 days"),
                      (900, [.hour, .minute], "15 minutes"),
                      (3600, [.hour, .minute], "1 hour"),
                      (129_600, [.hour, .minute], "36 hours"),
                      (90, [.hour, .minute], "2 minutes")])
    func givenUnits(duration: TimeInterval, units: [DurationFormatter.Unit], expected: String) {
        #expect(DurationFormatter.string(for: duration, in: units) == expected)
    }
    
    @Test("Odd values are kept between 1 second and 1000 years",
          arguments: [(TimeInterval.nan, "1 minute", "1 day"),
                      (-.infinity, "1 minute", "1 day"),
                      (-60, "1 minute", "1 day"),
                      (0, "1 minute", "1 day"),
                      // The thousands separator depends on the locale.
                      (.infinity, "\(1000.formatted()) years", "\(365_000.formatted()) days"),
                      (1e300, "\(1000.formatted()) years", "\(365_000.formatted()) days")])
    func oddValues(duration: TimeInterval, expected: String, expectedInDays: String) {
        #expect(DurationFormatter.string(for: duration) == expected)
        #expect(DurationFormatter.string(for: duration, in: [.day]) == expectedInDays)
    }
}
