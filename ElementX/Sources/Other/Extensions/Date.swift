//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
            return formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence))
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
