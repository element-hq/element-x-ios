//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
