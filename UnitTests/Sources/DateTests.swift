//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

// swiftlint:disable force_unwrapping

class DateTests: XCTestCase {
    let calendar = Calendar.current
    let startOfToday = Calendar.current.startOfDay(for: .now)
    let startOfYesterday = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
    
    func testMinimalDateFormatting() {
        let today = calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday)!
        XCTAssertEqual(today.formattedMinimal(), today.formatted(date: .omitted, time: .shortened))
        
        let yesterday = calendar.date(byAdding: .hour, value: 1, to: startOfYesterday)!
        XCTAssertEqual(yesterday.formattedMinimal(), yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let nearYesterday = calendar.date(byAdding: DateComponents(hour: -10), to: today)!
        XCTAssertEqual(nearYesterday.formattedMinimal(), yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: startOfToday)!
        XCTAssertEqual(threeDaysAgo.formattedMinimal(), threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        let sometimeInTheLastYear = calendar.date(byAdding: .month, value: -10, to: startOfToday)!
        XCTAssertEqual(sometimeInTheLastYear.formattedMinimal(), sometimeInTheLastYear.formatted(.dateTime.day().month()))
        
        let theMillennium = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        XCTAssertEqual(theMillennium.formattedMinimal(), theMillennium.formatted(.dateTime.year().day().month()))
    }
    
    func testDateSeparatorFormatting() {
        let today = calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday)!
        XCTAssertEqual(today.formattedDateSeparator(), "Today")
        
        let yesterday = calendar.date(byAdding: .hour, value: 1, to: startOfYesterday)!
        XCTAssertEqual(yesterday.formattedDateSeparator(), "Yesterday")
        
        let nearYesterday = calendar.date(byAdding: DateComponents(hour: -10), to: today)!
        XCTAssertEqual(nearYesterday.formattedDateSeparator(), yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: startOfToday)!
        XCTAssertEqual(threeDaysAgo.formattedDateSeparator(), threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        // This test will fail during the first 6 days of the year.
        let startOfTheYear = calendar.date(bySetting: .dayOfYear, value: 1, of: startOfToday)!
        // FIXME: Uncomment on the 7th Jan.
        // XCTAssertEqual(startOfTheYear.formattedDateSeparator(), startOfTheYear.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        
        let theMillennium = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        XCTAssertEqual(theMillennium.formattedDateSeparator(), theMillennium.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
    }
}

// swiftlint:enable force_unwrapping
