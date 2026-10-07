//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct UserSettingsTests {
    private let store = VolatileUserDefaults()
    private let appSettings: AppSettings
    private let aliceSettings: UserSettings
    private let bobSettings: UserSettings
    
    init() {
        appSettings = AppSettings(store: store)
        aliceSettings = appSettings.userSettings(for: "@alice:example.com")
        bobSettings = appSettings.userSettings(for: "@bob:example.com")
    }
    
    @Test
    func accountSettingsAreScopedToAccount() {
        // Given settings for two different accounts.
        #expect(aliceSettings.account.searchBreadcrumbs.isEmpty)
        #expect(bobSettings.account.searchBreadcrumbs.isEmpty)
        
        // When updating an account setting for Alice.
        aliceSettings.account.searchBreadcrumbs = [.query("Alice")]
        
        // Then only Alice should see the change.
        #expect(aliceSettings.account.searchBreadcrumbs == [.query("Alice")])
        #expect(bobSettings.account.searchBreadcrumbs.isEmpty)
    }
    
    @Test
    func appSettingsAreShared() {
        // Given settings for two different accounts.
        #expect(!appSettings.hasSignedInBefore)
        #expect(!aliceSettings.app.hasSignedInBefore)
        #expect(!bobSettings.app.hasSignedInBefore)
        
        // When updating an app setting through Alice's settings.
        aliceSettings.app.hasSignedInBefore = true
        
        // Then the change should be seen by the app and every account.
        #expect(appSettings.hasSignedInBefore)
        #expect(aliceSettings.app.hasSignedInBefore)
        #expect(bobSettings.app.hasSignedInBefore)
    }
    
    @Test
    func migrateAppSettingsValueToAccountSettings() throws {
        // Given a store containing values saved under the keys previously used by the app settings.
        // These keys are hardcoded so that renaming a property breaks this test instead of the migration.
        store.set(true, forKey: "hasRunIdentityConfirmationOnboarding")
        try store.set(JSONEncoder().encode([SearchBreadcrumb.query("Alice")]), forKey: "searchBreadcrumbs")
        #expect(store.object(forKey: "hasRunIdentityConfirmationOnboarding") != nil)
        #expect(store.object(forKey: "searchBreadcrumbs") != nil)
        #expect(!aliceSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(aliceSettings.account.searchBreadcrumbs.isEmpty)
        
        // When migrating those values into Alice's account settings.
        aliceSettings.account.migrateAppSettingsValue(\.hasRunIdentityConfirmationOnboardingKey)
        aliceSettings.account.migrateAppSettingsValue(\.searchBreadcrumbsKey)
        
        // Then the values should belong to Alice only.
        #expect(aliceSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(aliceSettings.account.searchBreadcrumbs == [.query("Alice")])
        #expect(!bobSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(bobSettings.account.searchBreadcrumbs.isEmpty)
        #expect(store.object(forKey: "hasRunIdentityConfirmationOnboarding") == nil)
        #expect(store.object(forKey: "searchBreadcrumbs") == nil)
    }
    
    @Test
    func resetSessionSpecificSettings() {
        // Given app settings and account settings for two different accounts.
        appSettings.hasSignedInBefore = true
        aliceSettings.account.hasRunIdentityConfirmationOnboarding = true
        aliceSettings.account.searchBreadcrumbs = [.query("Alice")]
        bobSettings.account.hasRunIdentityConfirmationOnboarding = true
        bobSettings.account.searchBreadcrumbs = [.query("Bob")]
        #expect(appSettings.hasSignedInBefore)
        #expect(aliceSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(aliceSettings.account.searchBreadcrumbs == [.query("Alice")])
        #expect(bobSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(bobSettings.account.searchBreadcrumbs == [.query("Bob")])
        
        // When resetting Alice's session specific settings.
        aliceSettings.account.reset()
        
        // Then only Alice's account settings should be reset.
        #expect(!aliceSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(aliceSettings.account.searchBreadcrumbs.isEmpty)
        #expect(bobSettings.account.hasRunIdentityConfirmationOnboarding)
        #expect(bobSettings.account.searchBreadcrumbs == [.query("Bob")])
        #expect(appSettings.hasSignedInBefore)
    }
}
