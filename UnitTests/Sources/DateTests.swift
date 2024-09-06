//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        // This test will fail during the first 6 days of the year.
        let sometimeThisYear = calendar.date(byAdding: .month, value: -10, to: startOfToday)!
        XCTAssertEqual(sometimeThisYear.formattedMinimal(), sometimeThisYear.formatted(.dateTime.day().month()))
        
        let theMillennium = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        XCTAssertEqual(theMillennium.formattedMinimal(), theMillennium.formatted(.dateTime.year().day().month()))
    }
}

// swiftlint:enable force_unwrapping
