//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

struct CurrentValuePublisherTests {
    @Test
    func publisherReplaysCurrentValueAndDeliversSubsequentOnes() {
        let subject = CurrentValueSubject<Int, Never>(1)
        var received = [Int]()
        let cancellable = subject.asCurrentValuePublisher().sink { received.append($0) }
        subject.send(2)
        subject.send(3)
        #expect(received == [1, 2, 3])
        cancellable.cancel()
    }
    
    @Test
    func mappedPublisherChainedInlineDeliversSubsequentValues() {
        let subject = CurrentValueSubject<Int, Never>(1)
        var received = [Int]()
        // The mapped publisher is intentionally chained without being stored: the struct is
        // discarded mid-chain, which used to cancel an eager map's subscription and stop updates.
        let cancellable = subject.asCurrentValuePublisher()
            .map { $0 * 2 }
            .removeDuplicates()
            .sink { received.append($0) }
        subject.send(2)
        subject.send(3)
        #expect(received == [2, 4, 6])
        cancellable.cancel()
    }
    
    @Test
    func mappedPublisherValueStaysCurrent() {
        let subject = CurrentValueSubject<Int, Never>(1)
        let mapped = subject.asCurrentValuePublisher().map { $0 * 2 }
        #expect(mapped.value == 2)
        subject.send(5)
        #expect(mapped.value == 10)
    }
}
