//
// Copyright 2022 New Vector Ltd
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

import ElementX
import XCTest

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
    
    func testChallengeMatches() {
        let app = Application.launch(.sessionVerification)
        app.assertScreenshot(.sessionVerification, step: Step.initialState)
        
        app.buttons["requestVerificationButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons["sasVerificationStartButton"].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.useEmojiComparisonPrompt)
        
        app.buttons["sasVerificationStartButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.waitingForEmojis)
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.compareEmojis)
        
        app.buttons["challengeAcceptButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.acceptingEmojis)
        
        XCTAssert(app.staticTexts[ElementL10n.verificationConclusionOkSelfNoticeTitle].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.verificationComplete)
        
        app.buttons["closeButton"].tap()
    }
    
    func testChallengeDoesNotMatch() {
        let app = Application.launch(.sessionVerification)
        app.assertScreenshot(.sessionVerification, step: Step.initialState)
        
        app.buttons["requestVerificationButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons["sasVerificationStartButton"].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.useEmojiComparisonPrompt)
        
        app.buttons["sasVerificationStartButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.waitingForEmojis)
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.compareEmojis)
        
        app.buttons["challengeDeclineButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.verificationCancelled)
        
        app.buttons["closeButton"].tap()
    }
    
    func testSessionVerificationCancelation() {
        let app = Application.launch(.sessionVerification)
        app.assertScreenshot(.sessionVerification, step: Step.initialState)
        
        app.buttons["requestVerificationButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.waitingForOtherDevice)
        
        XCTAssert(app.buttons["sasVerificationStartButton"].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.useEmojiComparisonPrompt)
        
        app.buttons["sasVerificationStartButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.waitingForEmojis)
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        app.assertScreenshot(.sessionVerification, step: Step.compareEmojis)
        
        app.buttons["closeButton"].tap()
        app.assertScreenshot(.sessionVerification, step: Step.verificationCancelled)
        
        app.buttons["closeButton"].tap()
    }
}
