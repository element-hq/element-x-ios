//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct ContentScannerServiceTests {
    @Test
    func safeContentIsCached() async throws {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(true)
        let service = ContentScannerService(contentScannerProxy: proxy)
        let source = makeSource("1")
        
        #expect(service.scanResultFromSource(source) == nil, "A source should not have a verdict before being scanned.")
        
        let result = await service.loadScanResultFromSource(source)
        #expect(try result.get() == true)
        
        #expect(service.scanResultFromSource(source) == true)
        
        // A second load returns the cached verdict without scanning again.
        await service.loadScanResultFromSource(source)
        #expect(proxy.scanMediaSourceCallsCount == 1)
    }
    
    @Test
    func unsafeContentIsCached() async throws {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(false)
        let service = ContentScannerService(contentScannerProxy: proxy)
        let source = makeSource("1")
        
        let result = await service.loadScanResultFromSource(source)
        #expect(try result.get() == false)
        
        #expect(service.scanResultFromSource(source) == false)
        
        await service.loadScanResultFromSource(source)
        #expect(proxy.scanMediaSourceCallsCount == 1)
    }
    
    @Test
    func sourcesAreCachedIndependently() async {
        let proxy = ContentScannerProxyMock()
        let service = ContentScannerService(contentScannerProxy: proxy)
        
        proxy.scanMediaSourceReturnValue = .success(true)
        await service.loadScanResultFromSource(makeSource("safe"))
        proxy.scanMediaSourceReturnValue = .success(false)
        await service.loadScanResultFromSource(makeSource("unsafe"))
        
        #expect(service.scanResultFromSource(makeSource("safe")) == true)
        #expect(service.scanResultFromSource(makeSource("unsafe")) == false)
        #expect(service.scanResultFromSource(makeSource("unscanned")) == nil)
    }
    
    @Test
    func failedScanIsNotCachedAndCanBeRetried() async throws {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .failure(.missingClient)
        let service = ContentScannerService(contentScannerProxy: proxy)
        let source = makeSource("1")
        
        var result = await service.loadScanResultFromSource(source)
        guard case .failure(.failedScanning) = result else {
            Issue.record("The scan should fail when the proxy fails.")
            return
        }
        
        #expect(service.scanResultFromSource(source) == nil, "A failed scan should not be cached.")
        
        // The scan is retried and now succeeds.
        proxy.scanMediaSourceReturnValue = .success(true)
        result = await service.loadScanResultFromSource(source)
        
        #expect(try result.get() == true)
        #expect(proxy.scanMediaSourceCallsCount == 2)
    }
    
    @Test
    func concurrentLoadsShareASingleScan() async {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceClosure = { _ in
            try? await Task.sleep(for: .milliseconds(50))
            return .success(true)
        }
        let service = ContentScannerService(contentScannerProxy: proxy)
        let source = makeSource("1")
        
        async let first = service.loadScanResultFromSource(source)
        async let second = service.loadScanResultFromSource(source)
        let results = await [first, second]
        
        #expect(results.allSatisfy { (try? $0.get()) == true })
        #expect(proxy.scanMediaSourceCallsCount == 1, "Concurrent loads for the same source should share a single scan.")
    }
    
    // MARK: - Multiple sources
    
    @Test
    func multipleSourcesAreSafeWhenAllSafe() async throws {
        let proxy = ContentScannerProxyMock()
        proxy.scanMediaSourceReturnValue = .success(true)
        let service = ContentScannerService(contentScannerProxy: proxy)
        
        let result = await service.loadScanResultFromSources([makeSource("media"), makeSource("thumbnail")])
        
        #expect(try result.get() == true)
    }
    
    @Test
    func multipleSourcesAreUnsafeWhenAnySourceIsUnsafe() async throws {
        let proxy = ContentScannerProxyMock()
        let unsafeSource = makeSource("thumbnail")
        proxy.scanMediaSourceClosure = { source in
            source == unsafeSource ? .success(false) : .success(true)
        }
        let service = ContentScannerService(contentScannerProxy: proxy)
        
        // The media is safe but its thumbnail is unsafe, which is enough to flag the whole item.
        let result = await service.loadScanResultFromSources([makeSource("media"), unsafeSource])
        
        #expect(try result.get() == false)
    }
    
    @Test
    func multipleSourcesFailWhenAnySourceFails() async {
        let proxy = ContentScannerProxyMock()
        let failingSource = makeSource("thumbnail")
        proxy.scanMediaSourceClosure = { source in
            source == failingSource ? .failure(.missingClient) : .success(true)
        }
        let service = ContentScannerService(contentScannerProxy: proxy)
        
        let result = await service.loadScanResultFromSources([makeSource("media"), failingSource])
        
        guard case .failure(.failedScanning) = result else {
            Issue.record("A failure of any source should fail the combined scan.")
            return
        }
    }
    
    @Test
    func multipleSourcesSyncLookupCombinesVerdicts() async {
        let proxy = ContentScannerProxyMock()
        let service = ContentScannerService(contentScannerProxy: proxy)
        
        proxy.scanMediaSourceReturnValue = .success(true)
        await service.loadScanResultFromSource(makeSource("safe"))
        proxy.scanMediaSourceReturnValue = .success(false)
        await service.loadScanResultFromSource(makeSource("unsafe"))
        
        #expect(service.scanResultFromSources([makeSource("safe")]) == true)
        #expect(service.scanResultFromSources([makeSource("safe"), makeSource("unsafe")]) == false)
        #expect(service.scanResultFromSources([makeSource("safe"), makeSource("unscanned")]) == nil)
    }
    
    // MARK: - Helpers
    
    private func makeSource(_ id: String) -> MediaSourceProxy {
        // swiftlint:disable:next force_unwrapping force_try
        try! MediaSourceProxy(url: URL(string: "mxc://example.com/\(id)")!, mimeType: nil)
    }
}
