//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension ClientBuilder {
    /// A helper method that applies the common builder modifiers needed for the app.
    static func baseBuilder(setupEncryption: Bool = true,
                            httpProxy: String? = nil,
                            slidingSync: ClientBuilderSlidingSync,
                            sessionDelegate: ClientSessionDelegate,
                            appHooks: AppHooks,
                            enableOnlySignedDeviceIsolationMode: Bool,
                            eventCacheEnabled: Bool) -> ClientBuilder {
        var builder = ClientBuilder()
            .crossProcessStoreLocksHolderName(holderName: InfoPlistReader.main.bundleIdentifier)
            .enableOidcRefreshLock()
            .setSessionDelegate(sessionDelegate: sessionDelegate)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .requestConfig(config: .init(retryLimit: 0, timeout: 30000, maxConcurrentRequests: nil, retryTimeout: nil))
            .useEventCachePersistentStorage(value: eventCacheEnabled)
        
        builder = switch slidingSync {
        case .restored: builder
        case .discoverProxy: builder.slidingSyncVersionBuilder(versionBuilder: .discoverProxy)
        case .discoverNative: builder.slidingSyncVersionBuilder(versionBuilder: .discoverNative)
        case .forceNative: builder.slidingSyncVersionBuilder(versionBuilder: .native)
        }
        
        if setupEncryption {
            builder = builder
                .autoEnableCrossSigning(autoEnableCrossSigning: true)
                .backupDownloadStrategy(backupDownloadStrategy: .afterDecryptionFailure)
                .autoEnableBackups(autoEnableBackups: true)
                
            if enableOnlySignedDeviceIsolationMode {
                builder = builder
                    .roomKeyRecipientStrategy(strategy: .identityBasedStrategy)
                    .roomDecryptionTrustRequirement(trustRequirement: .crossSignedOrLegacy)
            } else {
                builder = builder
                    .roomKeyRecipientStrategy(strategy: .deviceBasedStrategy(onlyAllowTrustedDevices: false, errorOnVerifiedUserProblem: true))
                    .roomDecryptionTrustRequirement(trustRequirement: .untrusted)
            }
        }
        
        if let httpProxy {
            builder = builder.proxy(url: httpProxy)
        }
        
        return appHooks.clientBuilderHook.configure(builder)
    }
}

enum ClientBuilderSlidingSync {
    /// The proxy will be supplied when restoring the Session.
    case restored
    /// A proxy must be discovered whilst building the session.
    case discoverProxy
    /// Native sliding sync must be discovered whilst building the session.
    case discoverNative
    /// Forces native sliding sync without discovering it.
    case forceNative
}
