//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct DateTests {
    let calendar = Calendar.current
    var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }
    
    var startOfYesterday: Date {
        // swiftlint: disable:next force_unwrapping
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
    }
    
    @Test
    func minimalDateFormatting() throws {
        let today = try #require(calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday))
        #expect(today.formattedMinimal() == today.formatted(date: .omitted, time: .shortened))
        
        let yesterday = try #require(calendar.date(byAdding: .hour, value: 1, to: startOfYesterday))
        #expect(yesterday.formattedMinimal() == yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let nearYesterday = try #require(calendar.date(byAdding: DateComponents(hour: -10), to: today))
        #expect(nearYesterday.formattedMinimal() == yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let threeDaysAgo = try #require(calendar.date(byAdding: .day, value: -3, to: startOfToday))
        #expect(threeDaysAgo.formattedMinimal() == threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        let sometimeInTheLastYear = try #require(calendar.date(byAdding: .month, value: -10, to: startOfToday))
        #expect(sometimeInTheLastYear.formattedMinimal() == sometimeInTheLastYear.formatted(.dateTime.day().month()))
        
        let theMillennium = try #require(calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)))
        #expect(theMillennium.formattedMinimal() == theMillennium.formatted(.dateTime.year().day().month()))
    }
    
    @Test
    func dateSeparatorFormatting() throws {
        let today = try #require(calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday))
        #expect(today.formattedDateSeparator() == "Today")
        
        let yesterday = try #require(calendar.date(byAdding: .hour, value: 1, to: startOfYesterday))
        #expect(yesterday.formattedDateSeparator() == "Yesterday")
        
        let nearYesterday = try #require(calendar.date(byAdding: DateComponents(hour: -10), to: today))
        #expect(nearYesterday.formattedDateSeparator() == yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let threeDaysAgo = try #require(calendar.date(byAdding: .day, value: -3, to: startOfToday))
        #expect(threeDaysAgo.formattedDateSeparator() == threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        // This test will fail during the first 6 days of the year.
        let startOfTheYear = try #require(calendar.dateInterval(of: .year, for: startOfToday)?.start)
        #expect(startOfTheYear.formattedDateSeparator() == startOfTheYear.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        
        let theMillennium = try #require(calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)))
        #expect(theMillennium.formattedDateSeparator() == theMillennium.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
    }
}
