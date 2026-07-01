//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Synchronization

final nonisolated class ContentScannerService: ContentScannerServiceProtocol {
    private let contentScannerProxy: ContentScannerProxyProtocol
    
    private struct State {
        /// Scan verdicts keyed by the media source's URL. Only definitive verdicts are cached,
        /// failed scans are left out so that they can be retried.
        var scanResults = [String: Bool]()
        /// In-flight scans keyed by the media source's URL, so that concurrent requests
        /// for the same source await a single scan.
        var ongoingScans = [String: Task<Result<Bool, ContentScannerServiceError>, Never>]()
    }
    
    private let state = Mutex(State())
    
    init(contentScannerProxy: ContentScannerProxyProtocol) {
        self.contentScannerProxy = contentScannerProxy
    }
    
    func scanResultFromSource(_ source: MediaSourceProxy) -> Bool? {
        state.withLock { $0.scanResults[source.url.absoluteString] }
    }
    
    @discardableResult
    func loadScanResultFromSource(_ source: MediaSourceProxy) async -> Result<Bool, ContentScannerServiceError> {
        enum Scan {
            case cached(Bool)
            case ongoing(Task<Result<Bool, ContentScannerServiceError>, Never>)
        }
        
        let sourceURL = source.url.absoluteString
        
        // Atomically return the cached verdict, join an ongoing scan, or register a new one.
        let scan = state.withLock { state -> Scan in
            if let cachedResult = state.scanResults[sourceURL] {
                return .cached(cachedResult)
            }
            
            if let ongoingScan = state.ongoingScans[sourceURL] {
                return .ongoing(ongoingScan)
            }
            
            let ongoingScan = Task { [weak self, contentScannerProxy] () -> Result<Bool, ContentScannerServiceError> in
                let result: Result<Bool, ContentScannerServiceError>
                switch await contentScannerProxy.scan(mediaSource: source) {
                case .success(let isSafe):
                    result = .success(isSafe)
                case .failure(let error):
                    MXLog.error("Failed scanning media source: \(error)")
                    result = .failure(.failedScanning)
                }
                
                self?.state.withLock { state in
                    state.ongoingScans[sourceURL] = nil
                    if case .success(let isSafe) = result {
                        state.scanResults[sourceURL] = isSafe
                    }
                }
                
                return result
            }
            
            state.ongoingScans[sourceURL] = ongoingScan
            return .ongoing(ongoingScan)
        }
        
        switch scan {
        case .cached(let isSafe):
            return .success(isSafe)
        case .ongoing(let ongoingScan):
            return await ongoingScan.value
        }
    }
}
