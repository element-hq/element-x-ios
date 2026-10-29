//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

nonisolated extension ClientBuilderSDKMock {
    struct Configuration {
        var client = ClientSDKMock(.init())
    }
    
    enum MockError: Error { case generic }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        autoEnableBackupsAutoEnableBackupsClosure = { [unowned self] _ in self }
        autoEnableCrossSigningAutoEnableCrossSigningClosure = { [unowned self] _ in self }
        backupDownloadStrategyBackupDownloadStrategyClosure = { [unowned self] _ in self }
        crossProcessLockConfigCrossProcessLockConfigClosure = { [unowned self] _ in self }
        decryptionSettingsDecryptionSettingsClosure = { [unowned self] _ in self }
        disableWellKnownLookupDisableWellKnownLookupClosure = { [unowned self] _ in self }
        dmRoomDefinitionDmRoomDefinitionClosure = { [unowned self] _ in self }
        enableAutomaticBackPaginationEnableAutomaticBackPaginationClosure = { [unowned self] _ in self }
        enableShareHistoryOnInviteEnableShareHistoryOnInviteClosure = { [unowned self] _ in self }
        homeserverUrlUrlClosure = { [unowned self] _ in self }
        inMemoryStoreClosure = { [unowned self] in self }
        proxyUrlClosure = { [unowned self] _ in self }
        requestConfigConfigClosure = { [unowned self] _ in self }
        roomKeyRecipientStrategyStrategyClosure = { [unowned self] _ in self }
        serverNameOrHomeserverUrlServerNameOrUrlClosure = { [unowned self] _ in self }
        setSessionDelegateSessionDelegateClosure = { [unowned self] _ in self }
        slidingSyncVersionBuilderVersionBuilderClosure = { [unowned self] _ in self }
        sqliteStoreConfigClosure = { [unowned self] _ in self }
        systemIsMemoryConstrainedClosure = { [unowned self] in self }
        threadsEnabledEnabledThreadSubscriptionsClosure = { [unowned self] _, _ in self }
        userAgentUserAgentClosure = { [unowned self] _ in self }
        withSearchIndexStorePathKeyClosure = { [unowned self] _, _ in self }
        
        buildClosure = { configuration.client }
    }
}
