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
        #expect(try result.get() == true) // swiftlint:disable:this force_try
        
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
        #expect(try result.get() == false) // swiftlint:disable:this force_try
        
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
        
        #expect(try result.get() == true) // swiftlint:disable:this force_try
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
    
    // MARK: - Helpers
    
    private func makeSource(_ id: String) -> MediaSourceProxy {
        // swiftlint:disable:next force_unwrapping force_try
        try! MediaSourceProxy(url: URL(string: "mxc://example.com/\(id)")!, mimeType: nil)
    }
}
