//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class PhoneEntryScreenViewModelTests: XCTestCase {
    var viewModel: PhoneEntryScreenViewModel!

    var context: PhoneEntryScreenViewModelType.Context {
        viewModel.context
    }

    override func setUpWithError() throws {
        viewModel = PhoneEntryScreenViewModel(isLegacyAuthEnabled: false)
    }

    func testInitialState() {
        XCTAssertTrue(context.viewState.bindings.localPhoneNumber.isEmpty)
        XCTAssertFalse(context.viewState.canContinue)
        XCTAssertFalse(context.viewState.isLegacyAuthEnabled)
        // Default country comes from device locale; fallback is US.
        XCTAssertFalse(context.viewState.selectedCountry.dialCode.isEmpty)
    }

    func testValidation() {
        XCTAssertFalse(PhoneEntryScreenViewState.isValid(localDigits: "", dialCode: "1"))
        XCTAssertFalse(PhoneEntryScreenViewState.isValid(localDigits: "123", dialCode: "1"))
        XCTAssertTrue(PhoneEntryScreenViewState.isValid(localDigits: "5551234567", dialCode: "1"))
        XCTAssertTrue(PhoneEntryScreenViewState.isValid(localDigits: "11987654321", dialCode: "55"))
        // 16-digit total length is rejected (E.164 max is 15).
        XCTAssertFalse(PhoneEntryScreenViewState.isValid(localDigits: "12345678901234", dialCode: "12"))
    }

    func testContinueEmitsE164PhoneNumber() async throws {
        viewModel = PhoneEntryScreenViewModel(isLegacyAuthEnabled: false, initialPhoneNumber: "+15551234567")
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            if case .continue(let number) = action, number == "+15551234567" { return true }
            return false
        }
        context.send(viewAction: .continueTapped)
        try await deferred.fulfill()
    }

    func testInitialPhoneNumberParsesCountry() {
        viewModel = PhoneEntryScreenViewModel(isLegacyAuthEnabled: false, initialPhoneNumber: "+5511987654321")
        XCTAssertEqual(context.viewState.selectedCountry.isoCode, "BR")
        XCTAssertEqual(context.viewState.bindings.localPhoneNumber, "(11) 98765-4321")
    }

    func testCountrySelectionUpdatesStateAndDismissesPicker() {
        context.isCountryPickerPresented = true
        let germany = Country.find(isoCode: "DE")!
        context.send(viewAction: .countrySelected(germany))
        XCTAssertEqual(context.viewState.selectedCountry, germany)
        XCTAssertFalse(context.viewState.bindings.isCountryPickerPresented)
    }
}
