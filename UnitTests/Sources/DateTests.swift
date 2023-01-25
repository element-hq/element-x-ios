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
        let today = calendar.date(byAdding: DateComponents(hour: 9, minute: 30), to: startOfToday)
        XCTAssertEqual(today?.formattedMinimal(), "9:30 AM")
        
        let yesterday = calendar.date(byAdding: .hour, value: 1, to: startOfYesterday)
        XCTAssertEqual(yesterday?.formattedMinimal(), "Yesterday")
        
        let saturday = calendar.nextWeekend(startingAfter: startOfToday, direction: .backward)?.start
        XCTAssertEqual(saturday?.formattedMinimal(), "Saturday")
        
        // This test will fail during the first 6 days of the year.
        let newYearsDay = calendar.date(from: DateComponents(year: calendar.component(.year, from: startOfToday), month: 1, day: 1))!
        XCTAssertEqual(newYearsDay.formattedMinimal(), "Jan 1")
        
        let theMillennium = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        XCTAssertEqual(theMillennium.formattedMinimal(), "Jan 1, 2000")
    }
}
