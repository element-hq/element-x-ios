//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Darwin
import Foundation

/// Diagnostics (strip before upstreaming): samples the main thread's call stack for a short
/// window and logs folded stacks, to attribute main-thread stalls (like the reaction picker's
/// post-appear pause) on a dogfood device without Instruments. App frames log as
/// `ElementX+0x<offset>` for offline `atos -offset` symbolication against the build's dSYM.
enum MainThreadSampler {
    private static var isRunning = false
    
    /// Call from the main thread. Samples until `duration` elapses, then logs.
    static func start(duration: TimeInterval, label: String) {
        guard !isRunning, Thread.isMainThread else { return }
        isRunning = true
        let mainThread = pthread_mach_thread_np(pthread_self())
        Thread.detachNewThread {
            sample(mainThread: mainThread, duration: duration, label: label)
            DispatchQueue.main.async {
                MainActor.assumeIsolated { isRunning = false }
            }
        }
    }
    
    private nonisolated static func sample(mainThread: thread_act_t, duration: TimeInterval, label: String) {
        let start = Date()
        let end = start.addingTimeInterval(duration)
        var samples = [(offsetMs: Int, stack: [UInt64])]()
        while Date() < end {
            if let stack = captureStack(of: mainThread) {
                samples.append((Int(Date().timeIntervalSince(start) * 1000), stack))
            }
            usleep(2000)
        }
        
        // Fold identical stacks (a stall = many identical samples) so the log stays small.
        var folded = [String: (count: Int, firstMs: Int, lastMs: Int)]()
        for (offsetMs, stack) in samples {
            let line = stack.map(symbolicate).joined(separator: ";")
            var entry = folded[line] ?? (0, offsetMs, offsetMs)
            entry.count += 1
            entry.lastMs = offsetMs
            folded[line] = entry
        }
        MXLog.info("MTS[\(label)]: \(samples.count) samples over \(Int(duration * 1000))ms")
        for (line, entry) in folded.sorted(by: { $0.value.count > $1.value.count }) where entry.count > 1 {
            MXLog.info("MTS[\(label)] \(entry.count)x @\(entry.firstMs)-\(entry.lastMs)ms: \(line)")
        }
    }
    
    private nonisolated static func captureStack(of thread: thread_act_t) -> [UInt64]? {
        #if arch(arm64)
        let maxDepth = 48
        var pcs = [UInt64](repeating: 0, count: maxDepth) // Allocated before the suspend.
        var depth = 0
        guard thread_suspend(thread) == KERN_SUCCESS else { return nil }
        // No allocations between here and thread_resume: the suspended thread may hold the malloc lock.
        var state = arm_thread_state64_t()
        var count = mach_msg_type_number_t(MemoryLayout<arm_thread_state64_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &state) { statePtr in
            statePtr.withMemoryRebound(to: natural_t.self, capacity: Int(count)) {
                thread_get_state(thread, thread_state_flavor_t(ARM_THREAD_STATE64), $0, &count)
            }
        }
        if kr == KERN_SUCCESS {
            pcs[depth] = strip(state.__pc)
            depth += 1
            let lr = strip(state.__lr)
            if lr != 0 {
                pcs[depth] = lr
                depth += 1
            }
            var fp = state.__fp
            while depth < maxDepth, fp != 0, fp % 8 == 0 {
                var record: (fp: UInt64, lr: UInt64) = (0, 0)
                var outSize: vm_size_t = 0
                let readResult = withUnsafeMutableBytes(of: &record) { buffer in
                    vm_read_overwrite(mach_task_self_,
                                      vm_address_t(fp),
                                      16,
                                      vm_address_t(UInt(bitPattern: buffer.baseAddress)),
                                      &outSize)
                }
                guard readResult == KERN_SUCCESS, outSize == 16 else { break }
                let returnAddress = strip(record.lr)
                guard returnAddress != 0 else { break }
                pcs[depth] = returnAddress
                depth += 1
                guard record.fp > fp, record.fp - fp < 1 << 20 else { break } // Stacks grow down; sanity-cap the stride.
                fp = record.fp
            }
        }
        thread_resume(thread)
        return depth > 0 ? Array(pcs[0..<depth]) : nil
        #else
        return nil
        #endif
    }
    
    /// Strips arm64e pointer authentication bits.
    private nonisolated static func strip(_ pointer: UInt64) -> UInt64 {
        pointer & 0x0000_007F_FFFF_FFFF
    }
    
    private nonisolated static func symbolicate(_ pc: UInt64) -> String {
        var info = Dl_info()
        guard dladdr(UnsafeRawPointer(bitPattern: UInt(pc)), &info) != 0, let imageBase = info.dli_fbase else {
            return String(format: "0x%llx", pc)
        }
        let module = info.dli_fname.map { (String(cString: $0) as NSString).lastPathComponent } ?? "?"
        if let symbolName = info.dli_sname, let symbolAddress = info.dli_saddr {
            return "\(module)`\(String(cString: symbolName))+\(pc - UInt64(UInt(bitPattern: symbolAddress)))"
        }
        return String(format: "%@+0x%llx", module, pc - UInt64(UInt(bitPattern: imageBase)))
    }
}
