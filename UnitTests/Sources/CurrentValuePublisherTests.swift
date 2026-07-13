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
        // Regression test: chain the mapped publisher inline WITHOUT storing it. The eager
        // subject-bridging implementation of map lost its feeding subscription here (nothing
        // retained the returned struct's cancellable), so subscribers only ever saw the
        // initial value — hiding e.g. live knock request updates in the room screen.
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
