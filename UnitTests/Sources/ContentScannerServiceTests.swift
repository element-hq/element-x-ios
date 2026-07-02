//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct ContentScannerServiceTests {
    @Test
    func cleanContentIsReportedSafe() async {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(true)
        let cache = EventContentValidationCache()
        let service = ContentScannerService(contentScannerProxy: proxy, validationCache: cache)
        
        await service.scan(eventID: "$event", mediaSource: makeSource("1"))
        
        #expect(cache.validation(for: "$event") == .safe)
        #expect(proxy.scanMediaSourceCallsCount == 1)
    }
    
    @Test
    func unsafeContentIsReportedNotSafe() async {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(false)
        let cache = EventContentValidationCache()
        let service = ContentScannerService(contentScannerProxy: proxy, validationCache: cache)
        
        await service.scan(eventID: "$event", mediaSource: makeSource("1"))
        
        #expect(cache.validation(for: "$event") == .notSafe)
    }
    
    @Test
    func alreadyScannedSourceIsNotScannedAgain() async {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(true)
        let cache = EventContentValidationCache()
        let service = ContentScannerService(contentScannerProxy: proxy, validationCache: cache)
        let source = makeSource("1")
        
        await service.scan(eventID: "$event", mediaSource: source)
        await service.scan(eventID: "$event", mediaSource: source)
        
        #expect(proxy.scanMediaSourceCallsCount == 1)
    }
    
    @Test
    func unsafeEventShortCircuitsRemainingSources() async {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(false)
        let cache = EventContentValidationCache()
        let service = ContentScannerService(contentScannerProxy: proxy, validationCache: cache)
        
        // Once the thumbnail source is flagged unsafe the full-size source shouldn't be scanned.
        await service.scan(eventID: "$event", mediaSource: makeSource("thumbnail"))
        await service.scan(eventID: "$event", mediaSource: makeSource("full"))
        
        #expect(proxy.scanMediaSourceCallsCount == 1)
        #expect(cache.validation(for: "$event") == .notSafe)
    }
    
    @Test
    func transientFailureLeavesEventRetryable() async {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .failure(.missingClient)
        let cache = EventContentValidationCache()
        let service = ContentScannerService(contentScannerProxy: proxy, validationCache: cache)
        let source = makeSource("1")
        
        await service.scan(eventID: "$event", mediaSource: source)
        #expect(cache.validation(for: "$event") == .unknown, "A transient failure should not be cached.")
        
        // The same source can be scanned again and now succeeds.
        proxy.scanMediaSourceReturnValue = .success(true)
        await service.scan(eventID: "$event", mediaSource: source)
        
        #expect(cache.validation(for: "$event") == .safe)
        #expect(proxy.scanMediaSourceCallsCount == 2)
    }
    
    // MARK: - Helpers
    
    private func makeSource(_ id: String) -> MediaSourceProxy {
        // swiftlint:disable:next force_unwrapping force_try
        try! MediaSourceProxy(url: URL(string: "mxc://example.com/\(id)")!, mimeType: nil)
    }
}
