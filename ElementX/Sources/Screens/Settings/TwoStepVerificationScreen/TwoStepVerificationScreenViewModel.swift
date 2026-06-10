//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias TwoStepVerificationScreenViewModelType = StateStoreViewModelV2<TwoStepVerificationScreenViewState, TwoStepVerificationScreenViewAction>

class TwoStepVerificationScreenViewModel: TwoStepVerificationScreenViewModelType, TwoStepVerificationScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let identityServiceClient: IdentityServiceClientProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol

    private let actionsSubject: PassthroughSubject<TwoStepVerificationScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<TwoStepVerificationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private var userHasPin = false

    private let indicatorID = "TwoStepVerificationScreen-Submit"
    private let successIndicatorID = "TwoStepVerificationScreen-Success"

    init(clientProxy: ClientProxyProtocol,
         identityServiceClient: IdentityServiceClientProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.identityServiceClient = identityServiceClient
        self.userIndicatorController = userIndicatorController

        super.init(initialViewState: TwoStepVerificationScreenViewState())

        Task { await loadStatus() }
    }

    override func process(viewAction: TwoStepVerificationScreenViewAction) {
        switch viewAction {
        case .startSetup:
            resetFlowState()
            state.phase = .enteringNew
        case .startChange:
            resetFlowState()
            state.selectedCountry = .deviceDefault
            state.phase = .enteringPhone
        case .phoneChanged:
            autoDetectCountry()
            reformatNumber()
            if state.errorMessage != nil { state.errorMessage = nil }
        case .countrySelected(let country):
            state.selectedCountry = country
            state.bindings.isCountryPickerPresented = false
            reformatNumber()
        case .pinChanged:
            let length = state.phase == .enteringOtp
                ? TwoStepVerificationScreenViewState.otpLength
                : TwoStepVerificationScreenViewState.pinLength
            let cleaned = String(state.bindings.pin.filter(\.isNumber).prefix(length))
            if cleaned != state.bindings.pin {
                state.bindings.pin = cleaned
            }
            if state.errorMessage != nil { state.errorMessage = nil }
            if cleaned.count == length {
                handleSubmittedCode(cleaned)
            }
        case .continueTapped:
            guard state.canContinue else { return }
            if state.phase == .enteringPhone {
                handleSubmittedPhone(state.e164PhoneNumber)
            } else {
                handleSubmittedCode(state.bindings.pin)
            }
        case .cancelEntry:
            resetFlowState()
            state.phase = userHasPin ? .overviewHasPin : .overviewNoPin
        }
    }

    // MARK: - Flow control

    private func resetFlowState() {
        state.errorMessage = nil
        state.currentPin = ""
        state.stagedNewPin = ""
        state.challengeId = nil
        state.otpCode = ""
        state.phone = ""
        state.bindings.pin = ""
        state.bindings.localPhoneNumber = ""
        state.bindings.isCountryPickerPresented = false
    }

    /// Rewrites the local phone digits with the country-specific live-formatted version
    /// (e.g. `"51985550619"` → `"(51) 98555-0619"`), mirroring the sign-up phone screen.
    private func reformatNumber() {
        let digits = state.bindings.localPhoneNumber.filter(\.isNumber)
        let formatted = state.selectedCountry.formatNational(digits: digits)
        if formatted != state.bindings.localPhoneNumber {
            state.bindings.localPhoneNumber = formatted
        }
    }

    /// Recomputes `selectedCountry` from the typed digits (e.g. typing a Canadian area code
    /// flips the flag from US to CA), matching the sign-up phone screen's behaviour.
    private func autoDetectCountry() {
        if let detected = Country.detect(localDigits: state.localDigits,
                                         current: state.selectedCountry) {
            state.selectedCountry = detected
        }
    }

    private func handleSubmittedPhone(_ phone: String) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard TwoStepVerificationScreenViewState.isValid(phone: trimmed) else {
            state.errorMessage = L10n.screenPhoneLoginInvalidNumber
            return
        }
        state.phone = trimmed
        state.bindings.pin = ""
        state.phase = .enteringCurrent
    }

    private func handleSubmittedCode(_ code: String) {
        switch state.phase {
        case .enteringCurrent:
            // Validate against the backend immediately before allowing progression.
            Task { await verifyCurrentPinAndRequestOtp(code) }
        case .enteringOtp:
            state.otpCode = code
            state.bindings.pin = ""
            state.phase = .enteringNew
        case .enteringNew:
            if isWeak(pin: code) {
                state.errorMessage = L10n.screenPinSetupWeakError
                state.bindings.pin = ""
                return
            }
            if userHasPin, !state.currentPin.isEmpty, code == state.currentPin {
                state.errorMessage = L10n.screenTwoStepVerificationSameAsCurrent
                state.bindings.pin = ""
                return
            }
            state.stagedNewPin = code
            state.bindings.pin = ""
            state.phase = .confirmingNew
        case .confirmingNew:
            guard code == state.stagedNewPin else {
                state.errorMessage = L10n.screenPinSetupMismatchError
                state.bindings.pin = ""
                state.stagedNewPin = ""
                state.phase = .enteringNew
                return
            }
            Task { await submitNewPin(code) }
        default:
            break
        }
    }

    // MARK: - Backend interactions

    private func loadStatus() async {
        guard let accessToken = clientProxy.accessToken else {
            state.phase = .overviewNoPin
            state.errorMessage = L10n.errorUnknown
            return
        }
        state.phase = .loading
        do {
            let hasPin = try await identityServiceClient.pinStatus(accessToken: accessToken)
            userHasPin = hasPin
            state.phase = hasPin ? .overviewHasPin : .overviewNoPin
        } catch {
            MXLog.error("Failed to fetch PIN status: \(error)")
            userHasPin = false
            state.phase = .overviewNoPin
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown
        }
    }

    private func verifyCurrentPinAndRequestOtp(_ currentPin: String) async {
        guard let accessToken = clientProxy.accessToken else {
            state.errorMessage = L10n.errorUnknown
            return
        }
        let phone = state.phone
        guard !phone.isEmpty else {
            state.errorMessage = L10n.errorUnknown
            state.phase = .enteringPhone
            return
        }
        let previousPhase = state.phase
        state.phase = .submitting
        userIndicatorController.submitIndicator(UserIndicator(id: indicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(indicatorID) }
        do {
            let challengeId = try await identityServiceClient.startPinChange(accessToken: accessToken,
                                                                             phone: phone,
                                                                             currentPin: currentPin)
            state.currentPin = currentPin
            state.challengeId = challengeId
            state.bindings.pin = ""
            state.errorMessage = nil
            state.phase = .enteringOtp
        } catch IdentityServiceError.invalidPin {
            state.errorMessage = L10n.screenTwoStepVerificationCurrentIncorrect
            state.bindings.pin = ""
            state.phase = .enteringCurrent
        } catch IdentityServiceError.pinLocked {
            state.errorMessage = L10n.screenTwoStepVerificationLocked
            state.phase = .overviewHasPin
        } catch let IdentityServiceError.pinChangeCooldown(retry) {
            state.errorMessage = IdentityServiceError.pinChangeCooldown(retryAfterSeconds: retry).errorDescription
            state.phase = .overviewHasPin
        } catch IdentityServiceError.rateLimited {
            state.errorMessage = IdentityServiceError.rateLimited.errorDescription
            state.phase = previousPhase
        } catch {
            MXLog.error("Failed to start PIN change: \(error)")
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown
            state.bindings.pin = ""
            state.phase = .enteringCurrent
        }
    }

    private func submitNewPin(_ pin: String) async {
        guard let accessToken = clientProxy.accessToken else {
            state.errorMessage = L10n.errorUnknown
            return
        }
        state.phase = .submitting
        userIndicatorController.submitIndicator(UserIndicator(id: indicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(indicatorID) }
        do {
            if userHasPin {
                guard let challengeId = state.challengeId else {
                    state.errorMessage = L10n.errorUnknown
                    state.phase = .overviewHasPin
                    return
                }
                try await identityServiceClient.completePinChange(accessToken: accessToken,
                                                                  challengeId: challengeId,
                                                                  otpCode: state.otpCode,
                                                                  newPin: pin)
            } else {
                try await identityServiceClient.setInitialPin(accessToken: accessToken,
                                                              userId: clientProxy.userID,
                                                              newPin: pin)
            }
            userHasPin = true
            resetFlowState()
            state.phase = .overviewHasPin
            userIndicatorController.submitIndicator(UserIndicator(id: successIndicatorID,
                                                                  type: .toast(progress: .none),
                                                                  title: L10n.screenTwoStepVerificationUpdated,
                                                                  iconName: "checkmark"))
        } catch IdentityServiceError.invalidOTP {
            state.errorMessage = L10n.screenTwoStepVerificationOtpInvalid
            state.bindings.pin = ""
            state.phase = .enteringOtp
        } catch IdentityServiceError.pinChangeChallengeInvalid {
            state.errorMessage = IdentityServiceError.pinChangeChallengeInvalid.errorDescription
            resetFlowState()
            state.phase = .overviewHasPin
        } catch IdentityServiceError.invalidPin {
            state.errorMessage = L10n.screenTwoStepVerificationCurrentIncorrect
            state.bindings.pin = ""
            state.phase = userHasPin ? .enteringCurrent : .enteringNew
        } catch IdentityServiceError.pinLocked {
            state.errorMessage = L10n.screenTwoStepVerificationLocked
            state.phase = userHasPin ? .overviewHasPin : .overviewNoPin
        } catch let IdentityServiceError.pinChangeCooldown(retry) {
            state.errorMessage = IdentityServiceError.pinChangeCooldown(retryAfterSeconds: retry).errorDescription
            state.phase = .overviewHasPin
        } catch {
            MXLog.error("Failed to set or update PIN: \(error)")
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown
            state.bindings.pin = ""
            state.phase = userHasPin ? .enteringCurrent : .enteringNew
        }
    }

    private func isWeak(pin: String) -> Bool {
        let weakPins: Set<String> = ["000000", "111111", "222222", "333333", "444444",
                                     "555555", "666666", "777777", "888888", "999999",
                                     "123456", "654321", "012345", "543210"]
        return weakPins.contains(pin)
    }
}
