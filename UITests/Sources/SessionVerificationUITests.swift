//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class SessionVerificationUITests: XCTestCase {
    enum Step {
        static let initialState = 0
        static let waitingForOtherDevice = 1
        static let useEmojiComparisonPrompt = 2
        static let waitingForEmojis = 3
        static let compareEmojis = 4
        static let acceptingEmojis = 5
        static let verificationComplete = 6
        
        static let verificationCancelled = 7
    }
    
    func testChallengeMatches() async throws {
        let app = Application.launch(.sessionVerification)
        try await app.assertScreenshot(.sessionVerification, step: Step.initialState)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.requestVerification].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.startSasVerification].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.useEmojiComparisonPrompt)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.startSasVerification].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.waitingForEmojis)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.compareEmojis)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.acceptingEmojis)
        
        XCTAssert(app.staticTexts[A11yIdentifiers.sessionVerificationScreen.verificationComplete].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.verificationComplete)
    }
    
    func testChallengeDoesNotMatch() async throws {
        let app = Application.launch(.sessionVerification)
        try await app.assertScreenshot(.sessionVerification, step: Step.initialState)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.requestVerification].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.startSasVerification].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.useEmojiComparisonPrompt)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.startSasVerification].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.waitingForEmojis)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.compareEmojis)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.declineChallenge].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.verificationCancelled)
    }
    
    func testSessionVerificationCancelation() async throws {
        let app = Application.launch(.sessionVerification)
        try await app.assertScreenshot(.sessionVerification, step: Step.initialState)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.requestVerification].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.startSasVerification].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.useEmojiComparisonPrompt)
        
        app.buttons[A11yIdentifiers.sessionVerificationScreen.startSasVerification].tap()
        try await app.assertScreenshot(.sessionVerification, step: Step.waitingForEmojis)
        
        XCTAssert(app.buttons[A11yIdentifiers.sessionVerificationScreen.acceptChallenge].waitForExistence(timeout: 10.0))
        try await app.assertScreenshot(.sessionVerification, step: Step.compareEmojis)
    }
}
