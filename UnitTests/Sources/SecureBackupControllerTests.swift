//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
struct SecureBackupControllerTests {
    private struct TestError: Error { }
    
    private let encryption = EncryptionSDKMock()
    private let controller: SecureBackupController
    
    init() {
        encryption.backupStateListenerListenerReturnValue = TaskHandleSDKMock()
        encryption.recoveryStateListenerListenerReturnValue = TaskHandleSDKMock()
        controller = SecureBackupController(encryption: encryption)
    }
    
    // MARK: - Generating and activating a recovery key
    
    @Test
    func generatingAKeyDoesNotActivateIt() {
        let key = controller.generateRecoveryKey()
        
        #expect(!key.isEmpty)
        #expect(!encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerCalled)
    }
    
    @Test
    func eachGeneratedKeyIsDifferent() {
        #expect(controller.generateRecoveryKey() != controller.generateRecoveryKey())
    }
    
    @Test
    func activatingWithoutAGeneratedKeyFails() async {
        let result = await controller.activateRecoveryKey()
        
        #expect(result.isFailure(.failedActivatingRecoveryKey))
        #expect(!encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerCalled)
    }
    
    @Test
    func activatingUsesTheGeneratedKey() async throws {
        let generatedKey = controller.generateRecoveryKey()
        var activatedKey: String?
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerClosure = { _, key, progressListener in
            activatedKey = key?.toBase58()
            progressListener.onUpdate(status: .done(recoveryKey: generatedKey))
            return generatedKey
        }
        
        let deferred = deferFulfillment(controller.recoveryState) { $0 == .enabled }
        let result = await controller.activateRecoveryKey()
        try await deferred.fulfill()
        
        #expect(result.isSuccess)
        #expect(activatedKey == generatedKey)
    }
    
    @Test
    func aKeyCanOnlyBeActivatedOnce() async {
        _ = controller.generateRecoveryKey()
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerReturnValue = "key"
        
        #expect(await controller.activateRecoveryKey().isSuccess)
        #expect(await controller.activateRecoveryKey().isFailure(.failedActivatingRecoveryKey))
        #expect(encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerCallsCount == 1)
    }
    
    @Test
    func failingToActivateKeepsTheKeyForARetry() async {
        let generatedKey = controller.generateRecoveryKey()
        var activatedKeys = [String?]()
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerClosure = { _, key, _ in
            activatedKeys.append(key?.toBase58())
            if activatedKeys.count == 1 {
                throw TestError()
            }
            return generatedKey
        }
        
        #expect(await controller.activateRecoveryKey().isFailure(.failedActivatingRecoveryKey))
        #expect(await controller.activateRecoveryKey().isSuccess)
        #expect(activatedKeys == [generatedKey, generatedKey])
    }
    
    @Test
    func roomKeyUploadErrorsFailTheActivation() async {
        _ = controller.generateRecoveryKey()
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerClosure = { _, _, progressListener in
            progressListener.onUpdate(status: .roomKeyUploadError)
            // The listener hops to the main actor, so give it the chance to run before returning.
            for _ in 0..<10 {
                await Task.yield()
            }
            return "key"
        }
        
        #expect(await controller.activateRecoveryKey().isFailure(.failedActivatingRecoveryKey))
    }
    
    @Test
    func activatingMovesThroughTheSettingUpState() async throws {
        _ = controller.generateRecoveryKey()
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerClosure = { _, _, progressListener in
            progressListener.onUpdate(status: .creatingRecoveryKey)
            return "key"
        }
        
        let deferred = deferFulfillment(controller.recoveryState) { $0 == .settingUp }
        _ = await controller.activateRecoveryKey()
        try await deferred.fulfill()
    }
    
    @Test
    func passphraseKeysAreActivatedStraightAway() async {
        var activatedKey: SecretStorageKey?
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerClosure = { _, key, _ in
            activatedKey = key
            return "passphrase-key"
        }
        
        let result = await controller.generateRecoveryKey(withPassphrase: "a passphrase")
        
        guard case .success(let recoveryKey) = result else {
            Issue.record("Expected the key to be generated.")
            return
        }
        #expect(recoveryKey == "passphrase-key")
        #expect(activatedKey != nil)
    }
    
    @Test
    func withoutAPassphraseARandomKeyIsActivated() async {
        var activatedKey: SecretStorageKey?
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerClosure = { _, key, _ in
            activatedKey = key
            return "random-key"
        }
        
        _ = await controller.generateRecoveryKey(withPassphrase: nil)
        
        #expect(activatedKey != nil)
    }
    
    @Test
    func failingToActivateAPassphraseKeyIsReported() async {
        encryption.enableRecoveryWaitForBackupsToUploadKeyProgressListenerThrowableError = TestError()
        
        let result = await controller.generateRecoveryKey(withPassphrase: nil)
        
        #expect(result.isFailure(.failedGeneratingRecoveryKey))
    }
}

private extension Result where Failure == SecureBackupControllerError {
    var isSuccess: Bool {
        if case .success = self {
            true
        } else {
            false
        }
    }
    
    func isFailure(_ error: SecureBackupControllerError) -> Bool {
        if case .failure(let failure) = self {
            failure == error
        } else {
            false
        }
    }
}
