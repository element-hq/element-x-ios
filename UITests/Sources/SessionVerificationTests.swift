//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class SessionVerificationUITests: XCTestCase {
    enum Step {
        static let initialState = 0
        static let waitingForOtherDevice = 1
        static let compareEmojis = 2
        static let acceptingEmojis = 3
        static let verificationComplete = 4
        static let verificationCancelled = 5
    }
    
    func testChallengeMatches() async throws {
        let app = Application.launch(.sessionVerification)
        try await app.assertScreenshot(step: Step.initialState)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.requestVerification].tap()
        try await app.assertScreenshot(step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].waitForExistence(timeout: 20.0))
        try await app.assertScreenshot(step: Step.compareEmojis)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].tap()
        try await app.assertScreenshot(step: Step.acceptingEmojis)
        
        XCTAssert(app.staticTexts[A11yIdentifiers.sessionVerificationScreen.verificationComplete].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(step: Step.verificationComplete)
    }
    
    func testChallengeDoesNotMatch() async throws {
        let app = Application.launch(.sessionVerification)
        try await app.assertScreenshot(step: Step.initialState)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.requestVerification].tap()
        try await app.assertScreenshot(step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].waitForExistence(timeout: 20.0))
        try await app.assertScreenshot(step: Step.compareEmojis)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.declineChallenge].tap()
        try await app.assertScreenshot(step: Step.verificationCancelled)
    }
    
    func testSessionVerificationCancelation() async throws {
        let app = Application.launch(.sessionVerification)
        try await app.assertScreenshot(step: Step.initialState)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.requestVerification].tap()
        try await app.assertScreenshot(step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].waitForExistence(timeout: 20.0))
        try await app.assertScreenshot(step: Step.compareEmojis)
    }
}
