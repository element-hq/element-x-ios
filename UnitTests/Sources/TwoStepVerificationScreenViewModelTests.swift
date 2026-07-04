//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class TwoStepVerificationScreenViewModelTests: XCTestCase {
    var viewModel: TwoStepVerificationScreenViewModel!

    var context: TwoStepVerificationScreenViewModelType.Context {
        viewModel.context
    }

    override func setUpWithError() throws {
        viewModel = TwoStepVerificationScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                                       identityServiceClient: TwoStepVerificationIdentityServiceStub(),
                                                       userIndicatorController: UserIndicatorControllerMock())
        // Put the screen into the phone-entry phase so phoneChanged actions are meaningful.
        context.send(viewAction: .startChange)
    }

    // MARK: - Phone autofill / paste country-code stripping

    private func enterPhone(_ value: String) {
        context.localPhoneNumber = value
        context.send(viewAction: .phoneChanged)
    }

    func testAutofillInternationalNumberStripsCountryCode() throws {
        try context.send(viewAction: .countrySelected(XCTUnwrap(Country.find(isoCode: "US"))))
        enterPhone("+15551234567")
        XCTAssertTrue(["US", "CA"].contains(context.viewState.selectedCountry.isoCode))
        XCTAssertEqual(context.viewState.localDigits, "5551234567")
        XCTAssertEqual(context.viewState.e164PhoneNumber, "+15551234567")
    }

    func testAutofillFormattedInternationalNumberStrips() throws {
        try context.send(viewAction: .countrySelected(XCTUnwrap(Country.find(isoCode: "US"))))
        enterPhone("+1 (555) 123-4567")
        XCTAssertEqual(context.viewState.localDigits, "5551234567")
        XCTAssertEqual(context.viewState.e164PhoneNumber, "+15551234567")
    }

    func testAutofillBrazilInternationalSwitchesCountry() throws {
        try context.send(viewAction: .countrySelected(XCTUnwrap(Country.find(isoCode: "US"))))
        enterPhone("+5511912345678")
        XCTAssertEqual(context.viewState.selectedCountry.isoCode, "BR")
        XCTAssertEqual(context.viewState.localDigits, "11912345678")
        XCTAssertEqual(context.viewState.e164PhoneNumber, "+5511912345678")
    }

    func testNormalLocalNumberIsNotStripped() throws {
        try context.send(viewAction: .countrySelected(XCTUnwrap(Country.find(isoCode: "US"))))
        enterPhone("5551234567")
        XCTAssertEqual(context.viewState.localDigits, "5551234567")
        XCTAssertEqual(context.viewState.e164PhoneNumber, "+15551234567")
    }
}

// MARK: - Stub

private final class TwoStepVerificationIdentityServiceStub: IdentityServiceClientProtocol {
    func lookupContacts(accessToken: String, phones: [String]) async throws -> [ContactMatch] {
        []
    }

    func startAccountReauth(accessToken: String, language: String?) async throws { }
    func verifyAccountReauth(accessToken: String, code: String) async throws -> String {
        ""
    }

    func deactivateAccount(accessToken: String, reauthToken: String, eraseData: Bool) async throws { }
    func resetIdentityCredentials(accessToken: String, reauthToken: String) async throws -> IdentityResetCredentials {
        IdentityResetCredentials(userId: "", password: "")
    }

    func pinStatus(accessToken: String) async throws -> PinStatus {
        PinStatus(hasPin: false, cooldownRemaining: 0)
    }

    func setInitialPin(accessToken: String, userId: String, newPin: String) async throws { }
    func startPinChange(accessToken: String, phone: String, currentPin: String) async throws -> String {
        ""
    }

    func completePinChange(accessToken: String, challengeId: String, otpCode: String, newPin: String) async throws { }
    func verifyPinReauth(accessToken: String, userId: String, pin: String) async throws -> String {
        ""
    }

    func requestPhoneChangeOTP(accessToken: String, userId: String, newPhone: String, reauthToken: String, language: String?) async throws { }
    func changePhoneNumber(accessToken: String, userId: String, newPhone: String, code: String, reauthToken: String) async throws { }
    func startPasskeyEnrollment(accessToken: String) async throws -> URL {
        URL(string: "https://example.com")!
    }
}
