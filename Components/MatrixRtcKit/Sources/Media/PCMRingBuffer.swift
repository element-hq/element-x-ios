//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Synchronization

/// A single-producer single-consumer ring of Int16 samples, lock free so the audio render thread
/// can read it without ever waiting on the filler.
final nonisolated class PCMRingBuffer: @unchecked Sendable {
    private let capacity: Int
    private let storage: UnsafeMutablePointer<Int16>
    private let readIndex = Atomic<Int>(0)
    private let writeIndex = Atomic<Int>(0)
    
    /// - Parameter capacity: in samples, rounded up to a power of two.
    init(capacity: Int) {
        var size = 1
        while size < capacity {
            size <<= 1
        }
        self.capacity = size
        storage = .allocate(capacity: size)
        storage.initialize(repeating: 0, count: size)
    }
    
    deinit {
        storage.deallocate()
    }
    
    var availableToRead: Int {
        writeIndex.load(ordering: .acquiring) - readIndex.load(ordering: .relaxed)
    }
    
    var availableToWrite: Int {
        capacity - availableToRead
    }
    
    /// Writes as much as fits and returns how many samples were dropped (the *newest* ones).
    @discardableResult
    func write(_ samples: UnsafeBufferPointer<Int16>) -> Int {
        let write = writeIndex.load(ordering: .relaxed)
        let free = capacity - (write - readIndex.load(ordering: .acquiring))
        let count = min(samples.count, free)
        for index in 0..<count {
            storage[(write + index) & (capacity - 1)] = samples[index]
        }
        writeIndex.store(write + count, ordering: .releasing)
        return samples.count - count
    }
    
    /// Drops the oldest `count` samples so a slow consumer bounds latency rather than growing it.
    func dropOldest(_ count: Int) {
        let read = readIndex.load(ordering: .relaxed)
        readIndex.store(read + min(count, availableToRead), ordering: .releasing)
    }
    
    /// Reads up to `into.count` samples, zero-filling the remainder. Returns how many were real.
    @discardableResult
    func read(into destination: UnsafeMutableBufferPointer<Int16>) -> Int {
        let read = readIndex.load(ordering: .relaxed)
        let available = writeIndex.load(ordering: .acquiring) - read
        let count = min(destination.count, available)
        for index in 0..<count {
            destination[index] = storage[(read + index) & (capacity - 1)]
        }
        if count < destination.count {
            for index in count..<destination.count {
                destination[index] = 0
            }
        }
        readIndex.store(read + count, ordering: .releasing)
        return count
    }
    
    func clear() {
        readIndex.store(writeIndex.load(ordering: .acquiring), ordering: .releasing)
    }
}
