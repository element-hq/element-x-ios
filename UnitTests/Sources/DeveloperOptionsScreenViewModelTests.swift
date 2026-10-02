//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct DeveloperOptionsScreenViewModelTests {
    private let appSettings = AppSettings.volatile()
    private var viewModel: DeveloperOptionsScreenViewModel!
    
    @Test
    mutating func enablingMultiAccountArmsTheAnnouncement() {
        setupViewModel()
        #expect(appSettings.hasSeenMultiAccountAnnouncement)
        
        appSettings.multiAccountEnabled = true
        
        #expect(!appSettings.hasSeenMultiAccountAnnouncement)
    }
    
    @Test
    mutating func openingWithMultiAccountAlreadyEnabledDoesNotArm() {
        appSettings.multiAccountEnabled = true
        appSettings.hasSeenMultiAccountAnnouncement = true
        
        setupViewModel()
        
        #expect(appSettings.hasSeenMultiAccountAnnouncement)
    }
    
    private mutating func setupViewModel() {
        viewModel = DeveloperOptionsScreenViewModel(developerOptions: appSettings, appHooks: AppHooks(), clientProxy: nil)
    }
}
