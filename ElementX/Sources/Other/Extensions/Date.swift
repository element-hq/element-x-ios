//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension Date {
    /// The date formatted with the minimal necessary units given how long ago it occurred.
    func formattedMinimal() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            // Just the time if it was today.
            return formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(self) {
            // Simply "Yesterday" if it was yesterday.
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { fatalError() }
            return yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence))
        } else if let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now)),
                  sixDaysAgo <= self {
            // The named day if it was in the last 6 days.
            return formatted(.dateTime.weekday(.wide))
        } else if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: .now),
                  oneYearAgo <= self {
            // The day and month if it was in the past year
            return formatted(.dateTime.day().month())
        } else {
            // The day, month and year if it is any older.
            return formatted(.dateTime.year().day().month())
        }
    }
}
