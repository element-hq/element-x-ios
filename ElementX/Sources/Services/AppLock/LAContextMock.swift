//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import LocalAuthentication

/// A customised context that allows injecting a few mock values but otherwise behaves as expected.
/// It works as the actual context does and won't update the return values of `biometryType` and
/// `evaluatedPolicyDomainStateValue` until either `canEvaluatePolicy` or
/// `evaluatePolicy` have been called.
class LAContextMock: LAContext {
    var biometryTypeValue: LABiometryType!
    private var internalBiometryTypeValue: LABiometryType!
    override var biometryType: LABiometryType { internalBiometryTypeValue }
    
    var evaluatedPolicyDomainStateValue: Data?
    private var internalEvaluatedPolicyDomainStateValue: Data?
    override var evaluatedPolicyDomainState: Data? { internalEvaluatedPolicyDomainStateValue }
    
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        let result = super.canEvaluatePolicy(policy, error: error)
        updateInternalValues()
        return result
    }
    
    var evaluatePolicyReturnValue: Bool!
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        updateInternalValues()
        return evaluatePolicyReturnValue
    }
    
    private func updateInternalValues() {
        internalBiometryTypeValue = biometryTypeValue
        internalEvaluatedPolicyDomainStateValue = evaluatedPolicyDomainStateValue
    }
}
