//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

actor ContentScannerService: ContentScannerServiceProtocol {
    private let contentScannerProxy: ContentScannerProxyProtocol
    private let validationCache: EventContentValidationCacheProtocol
    
    /// The media source URLs that have already been scanned, per event.
    private var scannedSources: [String: Set<String>] = [:]
    /// The media source URLs whose scan is currently in flight, per event. Used to dedupe concurrent
    /// scans of the same source (the actor doesn't hold isolation across the `await`).
    private var inFlightSources: [String: Set<String>] = [:]
    
    init(contentScannerProxy: ContentScannerProxyProtocol, validationCache: EventContentValidationCacheProtocol) {
        self.contentScannerProxy = contentScannerProxy
        self.validationCache = validationCache
    }
    
    func scan(eventID: String, mediaSource: MediaSourceProxy) async {
        let sourceURL = mediaSource.url.absoluteString
        
        guard validationCache.validation(for: eventID) != .notSafe,
              scannedSources[eventID]?.contains(sourceURL) != true,
              inFlightSources[eventID]?.contains(sourceURL) != true else {
            return
        }
        
        inFlightSources[eventID, default: []].insert(sourceURL)
        validationCache.update(.scanning, for: eventID)
        
        let result = await contentScannerProxy.scan(mediaSource: mediaSource)
        
        inFlightSources[eventID]?.remove(sourceURL)
        
        // A sibling source (e.g. the thumbnail vs the full-size media) may have flagged the event
        // as unsafe while we were awaiting, so don't overwrite that verdict.
        guard validationCache.validation(for: eventID) != .notSafe else { return }
        
        switch result {
        case .success(let isClean):
            scannedSources[eventID, default: []].insert(sourceURL)
            validationCache.update(isClean ? .safe : .notSafe, for: eventID)
        case .failure:
            // A transient failure isn't cached so the scan can be retried - leave it unknown.
            validationCache.update(.unknown, for: eventID)
        }
    }
}
