//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import LocalAuthentication

/// A customised context that allows injecting a few mock values but otherwise behaves as expected.
nonisolated class LAContextMock: LAContext {
    var biometryTypeValue: LABiometryType!
    override var biometryType: LABiometryType {
        biometryTypeValue
    }
    
    var biometricStateHashValue: Data?
    override var biometricStateHash: Data? {
        biometricStateHashValue
    }
    
    var canEvaluatePolicyReturnValue: Bool?
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyReturnValue ?? super.canEvaluatePolicy(policy, error: error)
    }
    
    var evaluatePolicyReturnValue: Bool!
    var evaluatePolicyThrowableError: Error?
    var evaluatePolicyCallsCount = 0
    var evaluatePolicyCalled: Bool {
        evaluatePolicyCallsCount > 0
    }
    
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        evaluatePolicyCallsCount += 1
        if let evaluatePolicyThrowableError {
            throw evaluatePolicyThrowableError
        }
        return evaluatePolicyReturnValue
    }
}
