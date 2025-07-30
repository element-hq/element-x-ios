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
                            enableKeyShareOnInvite: Bool,
                            requestTimeout: UInt64? = 30000,
                            maxRequestRetryTime: UInt64? = nil,
                            threadsEnabled: Bool) -> ClientBuilder {
        var builder = ClientBuilder()
            .crossProcessStoreLocksHolderName(holderName: InfoPlistReader.main.bundleIdentifier)
            .enableOidcRefreshLock()
            .setSessionDelegate(sessionDelegate: sessionDelegate)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .threadsEnabled(enabled: threadsEnabled)
            .requestConfig(config: .init(retryLimit: 0,
                                         timeout: requestTimeout,
                                         maxConcurrentRequests: nil,
                                         maxRetryTime: maxRequestRetryTime))
        
        builder = switch slidingSync {
        case .restored: builder
        case .discover: builder.slidingSyncVersionBuilder(versionBuilder: .discoverNative)
        }
        
        if setupEncryption {
            // Tắt tất cả các cài đặt mã hóa tự động
            builder = builder
                .autoEnableCrossSigning(autoEnableCrossSigning: false) // Tắt cross-signing tự động
                .backupDownloadStrategy(backupDownloadStrategy: .afterDecryptionFailure) // Giữ nguyên giá trị gốc
                .enableShareHistoryOnInvite(enableShareHistoryOnInvite: false) // Tắt share history
                .autoEnableBackups(autoEnableBackups: false) // Tắt backup tự động
                
            // Sử dụng cài đặt ít nghiêm ngặt nhất
            builder = builder
                .roomKeyRecipientStrategy(strategy: .errorOnVerifiedUserProblem)
                .decryptionSettings(decryptionSettings: .init(senderDeviceTrustRequirement: .untrusted))
        }
        
        if let httpProxy {
            builder = builder.proxy(url: httpProxy)
        }
        
        return appHooks.clientBuilderHook.configure(builder)
    }
}

enum ClientBuilderSlidingSync {
    /// Sliding sync will be configured when restoring the Session.
    case restored
    /// Sliding sync must be discovered whilst building the session.
    case discover
}
