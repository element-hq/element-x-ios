//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class DateUtil {
    
    static let shared = DateUtil()
    
    private init() { }
    
    func dateFromISO8601String(_ dateString: String) -> Date {
        let fallback: Date = Date(timeIntervalSince1970: 0)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Handle milliseconds
        if let date = isoFormatter.date(from: dateString) {
            return date
        } else {
            return fallback
        }
    }
}
