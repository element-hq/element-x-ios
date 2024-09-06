//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum NSELogger {
    private static var isConfigured = false

    /// Memory formatter, uses exact 2 fraction digits and no grouping
    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.alwaysShowsDecimalSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }

    private static var formattedMemoryAvailable: String {
        let freeBytes = os_proc_available_memory()
        let freeMB = Double(freeBytes) / 1024 / 1024
        guard let formattedStr = numberFormatter.string(from: NSNumber(value: freeMB)) else {
            return ""
        }
        return "\(formattedStr) MB"
    }

    /// Details: https://developer.apple.com/forums/thread/105088
    /// - Returns: Current memory footprint
    private static var memoryFootprint: Float? {
        //  The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
        //  complex for the Swift C importer, so we have to define them ourselves.
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        guard let offset = MemoryLayout.offset(of: \task_vm_info_data_t.min_address) else {
            return nil
        }
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(offset / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard kr == KERN_SUCCESS, count >= TASK_VM_INFO_REV1_COUNT else {
            return nil
        }

        return Float(info.phys_footprint)
    }

    /// Formatted memory footprint for debugging purposes
    /// - Returns: Memory footprint in MBs as a readable string
    static var formattedMemoryFootprint: String {
        let usedBytes = UInt64(memoryFootprint ?? 0)
        let usedMB = Double(usedBytes) / 1024 / 1024
        guard let formattedStr = numberFormatter.string(from: NSNumber(value: usedMB)) else {
            return ""
        }
        return "\(formattedStr) MB"
    }

    static func configure(logLevel: TracingConfiguration.LogLevel) {
        guard !isConfigured else {
            return
        }
        isConfigured = true

        MXLog.configure(target: "nse", logLevel: logLevel)
    }

    static func logMemory(with tag: String) {
        MXLog.info("\(tag) Memory: footprint: \(formattedMemoryFootprint) - available: \(formattedMemoryAvailable)")
    }
}
