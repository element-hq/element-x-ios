//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ChangePhoneScreenViewModelType = StateStoreViewModelV2<ChangePhoneScreenViewState, ChangePhoneScreenViewAction>

class ChangePhoneScreenViewModel: ChangePhoneScreenViewModelType, ChangePhoneScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let identityServiceClient: IdentityServiceClientProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol

    private let actionsSubject: PassthroughSubject<ChangePhoneScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ChangePhoneScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private let indicatorID = "ChangePhoneScreen-Submit"
    private let successIndicatorID = "ChangePhoneScreen-Success"

    init(clientProxy: ClientProxyProtocol,
         identityServiceClient: IdentityServiceClientProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.identityServiceClient = identityServiceClient
        self.userIndicatorController = userIndicatorController

        super.init(initialViewState: ChangePhoneScreenViewState())
    }

    override func process(viewAction: ChangePhoneScreenViewAction) {
        switch viewAction {
        case .start:
            state.selectedCountry = .deviceDefault
            state.reauthToken = ""
            state.bindings.code = ""
            state.errorMessage = nil
            Task { await beginFlow() }
        case .phoneChanged:
            normalizeInput()
            autoDetectCountry()
            reformatNumber()
            if state.errorMessage != nil { state.errorMessage = nil }
        case .countrySelected(let country):
            state.selectedCountry = country
            state.bindings.isCountryPickerPresented = false
            reformatNumber()
        case .codeChanged:
            let length = currentCodeLength
            let cleaned = String(state.bindings.code.filter(\.isNumber).prefix(length))
            if cleaned != state.bindings.code {
                state.bindings.code = cleaned
            }
            if state.errorMessage != nil { state.errorMessage = nil }
            if cleaned.count == length {
                handleSubmittedCode(cleaned)
            }
        case .continueTapped:
            guard state.canContinue else { return }
            if state.phase == .newPhone {
                handleSubmittedPhone(state.e164PhoneNumber)
            } else {
                handleSubmittedCode(state.bindings.code)
            }
        case .cancel:
            actionsSubject.send(.close)
        case .done:
            actionsSubject.send(.close)
        case .setUpPin:
            actionsSubject.send(.setUpPin)
        }
    }

    // MARK: - Flow control

    private var currentCodeLength: Int {
        state.phase == .pin
            ? ChangePhoneScreenViewState.pinLength
            : ChangePhoneScreenViewState.otpLength
    }

    private func handleSubmittedPhone(_ phone: String) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ChangePhoneScreenViewState.isValid(phone: trimmed) else {
            state.errorMessage = L10n.screenPhoneLoginInvalidNumber
            return
        }
        state.newPhoneE164 = trimmed
        state.errorMessage = nil
        Task { await requestOtpForNewNumber() }
    }

    private func handleSubmittedCode(_ code: String) {
        switch state.phase {
        case .pin:
            // Step up with the PIN first; minting a reauth token gates the later SMS.
            Task { await verifyPin(code: code) }
        case .otp:
            Task { await submitChange(code: code) }
        default:
            break
        }
    }

    private func normalizeInput() {
        let raw = state.bindings.localPhoneNumber
        let (country, localDigits) = Country.normalize(rawInput: raw, current: state.selectedCountry)
        if country != state.selectedCountry {
            state.selectedCountry = country
        }
        if localDigits != raw.filter(\.isNumber) {
            state.bindings.localPhoneNumber = localDigits
        }
    }

    private func reformatNumber() {
        let digits = state.bindings.localPhoneNumber.filter(\.isNumber)
        let formatted = state.selectedCountry.formatNational(digits: digits)
        if formatted != state.bindings.localPhoneNumber {
            state.bindings.localPhoneNumber = formatted
        }
    }

    private func autoDetectCountry() {
        if let detected = Country.detect(localDigits: state.localDigits,
                                         current: state.selectedCountry) {
            state.selectedCountry = detected
        }
    }

    // MARK: - Backend interactions

    /// Gate the flow on PIN status (`GET /security/pin/status`) when the user taps intro Continue.
    /// No PIN → ``ChangePhoneScreenPhase/needsPinSetup``; PIN present but inside the fresh-2FA
    /// cooldown → ``ChangePhoneScreenPhase/cooldown``; otherwise proceed to the ``pin`` step.
    private func beginFlow() async {
        guard let accessToken = clientProxy.accessToken else {
            state.errorMessage = L10n.errorUnknown
            state.phase = .intro
            return
        }
        state.phase = .submitting
        userIndicatorController.submitIndicator(UserIndicator(id: indicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(indicatorID) }
        do {
            let status = try await identityServiceClient.pinStatus(accessToken: accessToken)
            guard status.hasPin else {
                state.phase = .needsPinSetup
                return
            }
            if status.cooldownRemaining > 0 {
                state.cooldownRemainingSeconds = status.cooldownRemaining
                state.phase = .cooldown
                return
            }
            state.phase = .pin
        } catch IdentityServiceError.pinSetupRequired {
            state.phase = .needsPinSetup
        } catch let IdentityServiceError.twoFactorCooldown(retry) {
            state.cooldownRemainingSeconds = retry ?? 0
            state.phase = .cooldown
        } catch {
            MXLog.error("Failed to fetch PIN status for change-phone: \(error)")
            userIndicatorController.submitIndicator(UserIndicator(title: (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown,
                                                                  iconName: "xmark"))
            state.phase = .intro
        }
    }

    /// PIN step-up — validate the account PIN and hold the minted reauth token. No SMS fires here.
    /// On success, advance to the new-number step; on a wrong PIN, stay on `.pin`.
    private func verifyPin(code: String) async {
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
            let reauthToken = try await identityServiceClient.verifyPinReauth(accessToken: accessToken,
                                                                              userId: clientProxy.userID,
                                                                              pin: code)
            state.reauthToken = reauthToken
            state.bindings.code = ""
            state.errorMessage = nil
            state.phase = .newPhone
        } catch IdentityServiceError.pinSetupRequired {
            // PIN was removed out from under us — bounce to the setup interstitial.
            state.bindings.code = ""
            state.errorMessage = nil
            state.phase = .needsPinSetup
        } catch let IdentityServiceError.twoFactorCooldown(retry) {
            state.bindings.code = ""
            state.errorMessage = nil
            state.cooldownRemainingSeconds = retry ?? 0
            state.phase = .cooldown
        } catch IdentityServiceError.invalidPin {
            state.errorMessage = L10n.screenChangePhonePinIncorrect
            state.bindings.code = ""
            state.phase = .pin
        } catch let IdentityServiceError.pinLocked(retry) {
            state.errorMessage = IdentityServiceError.pinLocked(retryAfterSeconds: retry).errorDescription
            state.bindings.code = ""
            state.phase = .pin
        } catch IdentityServiceError.rateLimited {
            state.errorMessage = IdentityServiceError.rateLimited.errorDescription
            state.bindings.code = ""
            state.phase = .pin
        } catch {
            MXLog.error("Failed to verify PIN step-up: \(error)")
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown
            state.bindings.code = ""
            state.phase = .pin
        }
    }

    /// With a valid reauth token in hand, send the verification OTP to the new number. This is where
    /// the SMS fires. On success, collect the code; on a bad number, stay on `.newPhone`.
    private func requestOtpForNewNumber() async {
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
            try await identityServiceClient.requestPhoneChangeOTP(accessToken: accessToken,
                                                                  userId: clientProxy.userID,
                                                                  newPhone: state.newPhoneE164,
                                                                  reauthToken: state.reauthToken,
                                                                  language: Locale.current.identifier)
            state.bindings.code = ""
            state.errorMessage = nil
            state.phase = .otp
        } catch let IdentityServiceError.twoFactorCooldown(retry) {
            // Backend defense-in-depth: cooldown became active mid-flow.
            state.errorMessage = nil
            state.reauthToken = ""
            state.bindings.code = ""
            state.cooldownRemainingSeconds = retry ?? 0
            state.phase = .cooldown
        } catch IdentityServiceError.invalidReauthToken {
            // Step-up expired — restart from the PIN step.
            state.errorMessage = IdentityServiceError.invalidReauthToken.errorDescription
            state.reauthToken = ""
            state.bindings.code = ""
            state.phase = .pin
        } catch IdentityServiceError.phoneAlreadyLinked {
            // Backend now rejects a taken number at the REQUEST step (409) instead of sending an
            // SMS, so the user must never reach `.otp`. Keep the typed number so they can see which
            // one was rejected and tweak it, and surface the reason as a toast — same treatment as
            // the submitChange phoneAlreadyLinked case.
            state.errorMessage = L10n.screenChangePhoneAlreadyLinked
            state.bindings.code = ""
            state.phase = .newPhone
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.screenChangePhoneAlreadyLinked,
                                                                  iconName: "xmark"))
        } catch IdentityServiceError.rateLimited {
            state.errorMessage = IdentityServiceError.rateLimited.errorDescription
            state.phase = .newPhone
        } catch let IdentityServiceError.server(status, message) where status == 400 {
            // Invalid / unsupported number for the configured SMS region.
            state.errorMessage = message ?? L10n.screenPhoneLoginInvalidNumber
            state.bindings.localPhoneNumber = ""
            state.phase = .newPhone
        } catch {
            MXLog.error("Failed to request OTP for the new number: \(error)")
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown
            state.phase = .newPhone
        }
    }

    /// Final step — verify the new-number OTP and consume the reauth token; backend re-binds the number.
    private func submitChange(code: String) async {
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
            try await identityServiceClient.changePhoneNumber(accessToken: accessToken,
                                                              userId: clientProxy.userID,
                                                              newPhone: state.newPhoneE164,
                                                              code: code,
                                                              reauthToken: state.reauthToken)
            state.errorMessage = nil
            state.phase = .done
            userIndicatorController.submitIndicator(UserIndicator(id: successIndicatorID,
                                                                  type: .toast(progress: .none),
                                                                  title: L10n.screenChangePhoneSuccess,
                                                                  iconName: "checkmark"))
        } catch IdentityServiceError.invalidOTP {
            state.errorMessage = L10n.screenChangePhoneOtpInvalid
            state.bindings.code = ""
            state.phase = .otp
        } catch IdentityServiceError.invalidReauthToken {
            // Step-up expired / consumed — restart from the PIN step.
            state.errorMessage = IdentityServiceError.invalidReauthToken.errorDescription
            state.reauthToken = ""
            state.bindings.code = ""
            state.phase = .pin
        } catch IdentityServiceError.phoneAlreadyLinked {
            // Keep the typed number so the user can see which one was rejected and tweak it,
            // and surface the reason as a toast — otherwise the bounce back to .newPhone reads
            // as an unexplained loop.
            state.errorMessage = L10n.screenChangePhoneAlreadyLinked
            state.bindings.code = ""
            state.phase = .newPhone
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.screenChangePhoneAlreadyLinked,
                                                                  iconName: "xmark"))
        } catch IdentityServiceError.rateLimited {
            state.errorMessage = IdentityServiceError.rateLimited.errorDescription
            state.bindings.code = ""
            state.phase = .otp
        } catch {
            MXLog.error("Failed to change phone number: \(error)")
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown
            state.bindings.code = ""
            state.phase = .otp
        }
    }
}
