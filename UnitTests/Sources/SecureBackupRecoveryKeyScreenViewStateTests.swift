//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct SecureBackupRecoveryKeyScreenViewStateTests {
    @Test
    func settingUpShowsTheKeyToSave() {
        let state = makeState(mode: .setupRecovery, recoveryKey: "key")
        
        #expect(state.title == L10n.screenRecoveryKeySaveTitle)
        #expect(state.subtitle == L10n.screenRecoveryKeySaveDescription)
        #expect(state.recoveryKeySubtitle == L10n.screenRecoveryKeySaveKeyDescription)
    }
    
    @Test
    func settingUpIntroducesTheKeyUntilThereIsOne() {
        let state = makeState(mode: .setupRecovery)
        
        #expect(state.title == L10n.screenRecoveryKeySetupTitle)
        #expect(state.subtitle == L10n.screenRecoveryKeySetupDescription)
        #expect(state.recoveryKeySubtitle == L10n.screenRecoveryKeySetupGenerateKeyDescription)
    }
    
    @Test
    func changingShowsTheKeyToSave() {
        let state = makeState(mode: .changeRecovery, recoveryKey: "key")
        
        #expect(state.title == L10n.screenRecoveryKeySaveTitle)
        #expect(state.subtitle == L10n.screenRecoveryKeySaveDescription)
        #expect(state.recoveryKeySubtitle == L10n.screenRecoveryKeySaveKeyDescription)
    }
    
    @Test
    func changingIntroducesTheKeyUntilThereIsOne() {
        let state = makeState(mode: .changeRecovery)
        
        #expect(state.title == L10n.screenRecoveryKeyChangeTitle)
        #expect(state.subtitle == L10n.screenRecoveryKeyChangeDescription)
        #expect(state.recoveryKeySubtitle == L10n.screenRecoveryKeyChangeGenerateKeyDescription)
    }
    
    @Test
    func fixingAsksForTheExistingKey() {
        let state = makeState(mode: .fixRecovery)
        
        #expect(state.title == L10n.screenRecoveryKeyConfirmTitle)
        #expect(state.subtitle == L10n.screenRecoveryKeyConfirmDescription)
        #expect(state.recoveryKeySubtitle == L10n.screenRecoveryKeyConfirmKeyDescription)
    }
    
    @Test
    func unknownModeShowsAnError() {
        let state = makeState(mode: .unknown)
        
        #expect(state.title == L10n.errorUnknown)
        #expect(state.subtitle == nil)
        #expect(state.recoveryKeySubtitle == nil)
    }
    
    @Test(arguments: [SecureBackupRecoveryKeyScreenViewMode.setupRecovery, .changeRecovery, .fixRecovery, .unknown])
    func completingShowsTheSuccessScreen(mode: SecureBackupRecoveryKeyScreenViewMode) {
        var state = makeState(mode: mode, recoveryKey: "key")
        #expect(state.icon == \.keySolid)
        
        state.isCompleted = true
        
        #expect(state.title == L10n.screenRecoveryKeySuccessTitle)
        #expect(state.subtitle == L10n.screenCustomRecoveryKeySuccessSubtitle)
        #expect(state.icon == \.checkCircleSolid)
    }
    
    // MARK: - Helpers
    
    private func makeState(mode: SecureBackupRecoveryKeyScreenViewMode, recoveryKey: String? = nil) -> SecureBackupRecoveryKeyScreenViewState {
        var state = SecureBackupRecoveryKeyScreenViewState(isModallyPresented: false,
                                                           mode: mode,
                                                           presentationContext: .standard,
                                                           bindings: .init())
        state.recoveryKey = recoveryKey
        return state
    }
}
