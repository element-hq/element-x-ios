//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct EventContentValidationCacheTests {
    @Test
    func defaultsToUnknown() {
        let cache = EventContentValidationCache()
        
        #expect(cache.validation(for: "$event") == .unknown)
        #expect(cache.validationPublisher(for: "$event").value == .unknown)
    }
    
    @Test
    func updatePersistsAndPublishes() {
        let cache = EventContentValidationCache()
        let publisher = cache.validationPublisher(for: "$event")
        
        cache.update(.scanning, for: "$event")
        #expect(cache.validation(for: "$event") == .scanning)
        #expect(publisher.value == .scanning)
        
        cache.update(.notSafe, for: "$event")
        #expect(cache.validation(for: "$event") == .notSafe)
        #expect(publisher.value == .notSafe)
    }
    
    @Test
    func tracksEventsIndependently() {
        let cache = EventContentValidationCache()
        
        cache.update(.notSafe, for: "$unsafe")
        cache.update(.safe, for: "$safe")
        
        #expect(cache.validation(for: "$unsafe") == .notSafe)
        #expect(cache.validation(for: "$safe") == .safe)
        #expect(cache.validation(for: "$untouched") == .unknown)
    }
}
