//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Formats durations in the biggest unit that divides them exactly, e.g. "2 weeks", "8 hours" or "90 minutes".
enum DurationFormatter {
    /// Ordered from the biggest unit to the smallest.
    enum Unit: CaseIterable {
        case year, week, day, hour, minute
    }
    
    /// - Parameters:
    ///   - duration: The duration in seconds.
    ///   - units: The units to choose from. When none of them divides the duration exactly,
    ///   it's rounded up in the smallest one.
    static func string(for duration: TimeInterval, in units: [Unit] = Unit.allCases) -> String {
        let seconds = wholeSeconds(duration)
        let units = Unit.allCases.filter(units.contains)
        
        for unit in units where seconds >= unit.seconds && seconds.isMultiple(of: unit.seconds) {
            return unit.string(count: seconds / unit.seconds)
        }
        
        let smallestUnit = units.last ?? .minute
        return smallestUnit.string(count: (seconds + smallestUnit.seconds - 1) / smallestUnit.seconds)
    }
    
    // MARK: - Private
    
    /// Durations can come from the server unvalidated, so keep them within 1 second and 1000 years before converting to `Int`.
    private static let maximumSeconds: TimeInterval = 1000 * 365 * 24 * 60 * 60
    
    private static func wholeSeconds(_ duration: TimeInterval) -> Int {
        guard !duration.isNaN else { return 1 }
        return Int(min(max(duration, 1), maximumSeconds).rounded(.up))
    }
}

private extension DurationFormatter.Unit {
    /// One formatter per unit, each allowed only that unit so that e.g. 14 days never becomes "2 weeks".
    static let formatters = Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.makeFormatter()) })
    
    var seconds: Int {
        switch self {
        case .year: 365 * 24 * 60 * 60
        case .week: 7 * 24 * 60 * 60
        case .day: 24 * 60 * 60
        case .hour: 60 * 60
        case .minute: 60
        }
    }
    
    func string(count: Int) -> String {
        var components = DateComponents()
        components.setValue(count, for: component)
        return Self.formatters[self]?.string(from: components) ?? ""
    }
    
    private var component: Calendar.Component {
        switch self {
        case .year: .year
        case .week: .weekOfMonth
        case .day: .day
        case .hour: .hour
        case .minute: .minute
        }
    }
    
    private var calendarUnit: NSCalendar.Unit {
        switch self {
        case .year: .year
        case .week: .weekOfMonth
        case .day: .day
        case .hour: .hour
        case .minute: .minute
        }
    }
    
    private func makeFormatter() -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = calendarUnit
        return formatter
    }
}
