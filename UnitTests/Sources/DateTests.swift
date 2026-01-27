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
    
    func testMinimalDateFormatting() throws {
        let today = try XCTUnwrap(calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday))
        XCTAssertEqual(today.formattedMinimal(), today.formatted(date: .omitted, time: .shortened))
        
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .hour, value: 1, to: startOfYesterday))
        XCTAssertEqual(yesterday.formattedMinimal(), yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let nearYesterday = try XCTUnwrap(calendar.date(byAdding: DateComponents(hour: -10), to: today))
        XCTAssertEqual(nearYesterday.formattedMinimal(), yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let threeDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -3, to: startOfToday))
        XCTAssertEqual(threeDaysAgo.formattedMinimal(), threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        let sometimeInTheLastYear = try XCTUnwrap(calendar.date(byAdding: .month, value: -10, to: startOfToday))
        XCTAssertEqual(sometimeInTheLastYear.formattedMinimal(), sometimeInTheLastYear.formatted(.dateTime.day().month()))
        
        let theMillennium = try XCTUnwrap(calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)))
        XCTAssertEqual(theMillennium.formattedMinimal(), theMillennium.formatted(.dateTime.year().day().month()))
    }
    
    func testDateSeparatorFormatting() throws {
        let today = try XCTUnwrap(calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday))
        XCTAssertEqual(today.formattedDateSeparator(), "Today")
        
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .hour, value: 1, to: startOfYesterday))
        XCTAssertEqual(yesterday.formattedDateSeparator(), "Yesterday")
        
        let nearYesterday = try XCTUnwrap(calendar.date(byAdding: DateComponents(hour: -10), to: today))
        XCTAssertEqual(nearYesterday.formattedDateSeparator(), yesterday.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .beginningOfSentence)))
        
        let threeDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -3, to: startOfToday))
        XCTAssertEqual(threeDaysAgo.formattedDateSeparator(), threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        // This test will fail during the first 6 days of the year.
        let startOfTheYear = try XCTUnwrap(calendar.dateInterval(of: .year, for: startOfToday)?.start)
        XCTAssertEqual(startOfTheYear.formattedDateSeparator(), startOfTheYear.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        
        let theMillennium = try XCTUnwrap(calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)))
        XCTAssertEqual(theMillennium.formattedDateSeparator(), theMillennium.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
    }
}

// swiftlint:enable force_unwrapping
