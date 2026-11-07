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
    func checkingAsksForTheExistingKey() {
        let state = makeState(mode: .checkRecovery)
        
        #expect(state.title == L10n.screenRecoveryKeyCheckTitle)
        #expect(state.subtitle == L10n.screenRecoveryKeyCheckSubtitle)
        #expect(state.recoveryKeySubtitle == nil)
    }
    
    @Test
    func completingACheckHasItsOwnTitle() {
        var state = makeState(mode: .checkRecovery)
        state.isCompleted = true
        
        #expect(state.title == L10n.screenRecoveryKeyCheckSuccessTitle)
        #expect(state.subtitle == L10n.screenCustomRecoveryKeySuccessSubtitle)
    }
    
    @Test
    func unknownModeShowsAnError() {
        let state = makeState(mode: .unknown)
        
        #expect(state.title == L10n.errorUnknown)
        #expect(state.subtitle == nil)
        #expect(state.recoveryKeySubtitle == nil)
    }
    
    @Test("Completing a change of the recovery key says that the new key is active")
    func completingAChange() {
        var state = makeState(mode: .changeRecovery, recoveryKey: "key")
        #expect(state.icon == \.keySolid)
        
        state.isCompleted = true
        
        #expect(state.title == L10n.screenRecoveryKeySuccessTitle)
        #expect(state.subtitle == L10n.screenCustomRecoveryKeySuccessSubtitle)
        #expect(state.completionNotice == nil)
        #expect(state.icon == \.checkCircleSolid)
    }
    
    @Test("Completing the set up says that the backup is ready and where to change the key")
    func completingTheSetUp() {
        var state = makeState(mode: .setupRecovery, recoveryKey: "key")
        #expect(state.completionNotice == nil)
        
        state.isCompleted = true
        
        #expect(state.title == L10n.screenCustomRecoveryKeySuccessTitle)
        #expect(state.subtitle == L10n.screenCustomRecoveryKeySuccessSubtitle)
        #expect(state.completionNotice == L10n.screenCustomRecoveryKeySuccessNotice)
        #expect(state.icon == \.checkCircleSolid)
    }
    
    @Test(arguments: [SecureBackupRecoveryKeyScreenViewMode.fixRecovery, .checkRecovery, .unknown])
    func completingElsewhereHasNoNotice(mode: SecureBackupRecoveryKeyScreenViewMode) {
        var state = makeState(mode: mode)
        state.isCompleted = true
        
        #expect(state.completionNotice == nil)
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
