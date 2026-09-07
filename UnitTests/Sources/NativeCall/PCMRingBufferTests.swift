//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import MatrixRtcKit
import Testing

struct PCMRingBufferTests {
    @Test
    func readsBackWhatWasWrittenAndZeroFillsTheRest() {
        let ring = PCMRingBuffer(capacity: 8)
        let written: [Int16] = [1, 2, 3]
        written.withUnsafeBufferPointer { ring.write($0) }
        
        var output = [Int16](repeating: 9, count: 5)
        let real = output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        
        #expect(real == 3)
        #expect(output == [1, 2, 3, 0, 0])
        #expect(ring.availableToRead == 0)
    }
    
    @Test
    func dropsTheNewestSamplesWhenFullAndTheOldestOnRequest() {
        let ring = PCMRingBuffer(capacity: 4)
        let dropped = [Int16](1...6).withUnsafeBufferPointer { ring.write($0) }
        #expect(dropped == 2)
        
        ring.dropOldest(2)
        var output = [Int16](repeating: 0, count: 2)
        output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        #expect(output == [3, 4])
    }
    
    @Test
    func wrapsAroundTheEnd() {
        let ring = PCMRingBuffer(capacity: 4)
        [Int16](1...3).withUnsafeBufferPointer { ring.write($0) }
        var output = [Int16](repeating: 0, count: 3)
        output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        
        [Int16](4...6).withUnsafeBufferPointer { ring.write($0) }
        output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        #expect(output == [4, 5, 6])
    }
}
