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
        
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: startOfToday)!
        XCTAssertEqual(threeDaysAgo.formattedMinimal(), threeDaysAgo.formatted(.dateTime.weekday(.wide)))
        
        // This test will fail during the first 6 days of the year.
        let sometimeThisYear = calendar.date(byAdding: .month, value: -10, to: startOfToday)!
        XCTAssertEqual(sometimeThisYear.formattedMinimal(), sometimeThisYear.formatted(.dateTime.day().month()))
        
        let theMillennium = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        XCTAssertEqual(theMillennium.formattedMinimal(), theMillennium.formatted(.dateTime.year().day().month()))
    }
}
