//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import LocalAuthentication

/// A customised context that allows injecting a few mock values but otherwise behaves as expected.
/// It works as the actual context does and won't update the return values of `biometryType` and
/// `evaluatedPolicyDomainStateValue` until either `canEvaluatePolicy` or
/// `evaluatePolicy` have been called.
nonisolated class LAContextMock: LAContext {
    var biometryTypeValue: LABiometryType!
    private var internalBiometryTypeValue: LABiometryType!
    override var biometryType: LABiometryType {
        internalBiometryTypeValue
    }
    
    var evaluatedPolicyDomainStateValue: Data?
    private var internalEvaluatedPolicyDomainStateValue: Data?
    override var evaluatedPolicyDomainState: Data? {
        internalEvaluatedPolicyDomainStateValue
    }
    
    var canEvaluatePolicyReturnValue: Bool?
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        let result = canEvaluatePolicyReturnValue ?? super.canEvaluatePolicy(policy, error: error)
        updateInternalValues()
        return result
    }
    
    var evaluatePolicyReturnValue: Bool!
    var evaluatePolicyThrowableError: Error?
    var evaluatePolicyCallsCount = 0
    var evaluatePolicyCalled: Bool {
        evaluatePolicyCallsCount > 0
    }
    
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        evaluatePolicyCallsCount += 1
        updateInternalValues()
        if let evaluatePolicyThrowableError {
            throw evaluatePolicyThrowableError
        }
        return evaluatePolicyReturnValue
    }
    
    private func updateInternalValues() {
        internalBiometryTypeValue = biometryTypeValue
        internalEvaluatedPolicyDomainStateValue = evaluatedPolicyDomainStateValue
    }
}
