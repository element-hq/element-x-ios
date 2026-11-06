//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing
import Version

@MainActor
struct UserSessionMigratorTests {
    var clientProxy: ClientProxyMock!
    var userSession: UserSessionMock!
    var migrator: UserSessionMigrator!
    
    @Test("An account is migrated from its last migrated version to the new version")
    mutating func migration() async {
        // Given an app last run on 26.12.1 and an account migrated to 26.12.1.
        setupMigrator(newVersion: Version(27, 1, 2), oldAppVersion: Version(26, 12, 1), lastAccountVersionMigrated: "26.12.1")
        
        // When migrating the account to 27.1.2.
        await migrator.migrate(userSession)
        
        // Then it should be migrated and marked as migrated to 27.1.2.
        #expect(clientProxy.optimizeStoresCalled)
        #expect(userSession.userSettings.account.lastVersionMigrated == "27.1.2")
    }
    
    @Test("An account without a migrated version is given the version the app last ran, then migrated from it")
    mutating func migratingToAccountSettingsVersion() async {
        // Given an app last run on 26.10.4 and an account that has never been migrated.
        setupMigrator(oldAppVersion: Version(26, 10, 4), lastAccountVersionMigrated: nil)
        
        // When migrating the account.
        await migrator.migrate(userSession)
        
        // Then it should be migrated from 26.10.4 and marked as migrated to 26.11.2.
        #expect(clientProxy.optimizeStoresCalled)
        #expect(userSession.userSettings.account.lastVersionMigrated == "26.11.2")
    }
    
    @Test("An account without a migrated version isn't migrated once the app has run 26.11.2")
    mutating func migrationWithoutAccountVersion() async {
        // Given an app last run on 26.11.2 and an account that has never been migrated.
        setupMigrator(oldAppVersion: Version(26, 11, 2), lastAccountVersionMigrated: nil)
        
        // When migrating the account.
        await migrator.migrate(userSession)
        
        // Then nothing should be migrated and the account should still have no migrated version.
        #expect(!clientProxy.optimizeStoresCalled)
        #expect(userSession.userSettings.account.lastVersionMigrated == nil)
    }
    
    @Test("An account already migrated to the new version isn't migrated again")
    mutating func repeatedMigration() async {
        // Given an app last run on 26.10.4 and an account already migrated to 26.11.2.
        setupMigrator(oldAppVersion: Version(26, 10, 4), lastAccountVersionMigrated: "26.11.2")
        
        // When migrating the account.
        await migrator.migrate(userSession)
        
        // Then nothing should be migrated.
        #expect(!clientProxy.optimizeStoresCalled)
    }
    
    @Test("Marking an account as migrated stores the new version")
    mutating func markingAsMigrated() {
        // Given a freshly installed app and an account that has never been migrated.
        setupMigrator(oldAppVersion: nil, lastAccountVersionMigrated: nil)
        
        // When marking the account as migrated.
        migrator.markAsMigrated(userSession)
        
        // Then the account should be marked as migrated to 26.11.2.
        #expect(userSession.userSettings.account.lastVersionMigrated == "26.11.2")
    }
    
    // MARK: - Private
    
    mutating func setupMigrator(newVersion: Version = Version(26, 11, 2), oldAppVersion: Version?, lastAccountVersionMigrated: String?) {
        clientProxy = ClientProxyMock(.init())
        clientProxy.optimizeStoresReturnValue = .success(())
        
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.userSettings.account.lastVersionMigrated = lastAccountVersionMigrated
        
        migrator = UserSessionMigrator(newVersion: newVersion,
                                       oldAppVersion: oldAppVersion,
                                       appSettings: .volatile(),
                                       appMediator: AppMediatorMock(.init()))
    }
}
