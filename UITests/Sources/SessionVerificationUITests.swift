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
    func testChallengeMatches() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.sessionVerification)
        
        XCTAssert(app.buttons["requestVerificationButton"].exists)
        XCTAssert(app.buttons["closeButton"].exists)
        XCTAssert(app.staticTexts["titleLabel"].exists)

        app.assertScreenshot(.sessionVerification)
        
        app.buttons["requestVerificationButton"].tap()
        
        XCTAssert(app.activityIndicators["requestingVerificationProgressView"].exists)
        
        XCTAssert(app.buttons["sasVerificationStartButton"].waitForExistence(timeout: 5.0))
        app.buttons["sasVerificationStartButton"].tap()
        
        XCTAssert(app.activityIndicators["startingSasVerification"].waitForExistence(timeout: 5.0))
        XCTAssert(app.activityIndicators["startedSasVerification"].waitForExistence(timeout: 5.0))
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        XCTAssert(app.buttons["challengeDeclineButton"].waitForExistence(timeout: 5.0))
        
        app.buttons["challengeAcceptButton"].tap()
                  
        XCTAssert(app.activityIndicators["acceptingChallengeProgressView"].exists)
        
        XCTAssert(app.images["sessionVerificationSucceededIcon"].waitForExistence(timeout: 5.0))
        
        XCTAssert(app.buttons["finishButton"].exists)
        XCTAssert(app.buttons["closeButton"].exists)
        app.buttons["closeButton"].tap()
    }
    
    func testChallengeDoesNotMatch() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.sessionVerification)
        
        XCTAssert(app.buttons["requestVerificationButton"].exists)
        XCTAssert(app.buttons["closeButton"].exists)
        XCTAssert(app.staticTexts["titleLabel"].exists)
        
        app.buttons["requestVerificationButton"].tap()
        
        XCTAssert(app.activityIndicators["requestingVerificationProgressView"].exists)
        
        XCTAssert(app.buttons["sasVerificationStartButton"].waitForExistence(timeout: 5.0))
        app.buttons["sasVerificationStartButton"].tap()
        
        XCTAssert(app.activityIndicators["startingSasVerification"].waitForExistence(timeout: 5.0))
        XCTAssert(app.activityIndicators["startedSasVerification"].waitForExistence(timeout: 5.0))
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        XCTAssert(app.buttons["challengeDeclineButton"].waitForExistence(timeout: 5.0))
        
        app.buttons["challengeDeclineButton"].tap()
                          
        XCTAssert(app.images["sessionVerificationFailedIcon"].exists)
        XCTAssert(app.buttons["restartButton"].exists)
        
        XCTAssert(app.buttons["closeButton"].exists)
        app.buttons["closeButton"].tap()
    }
    
    func testSessionVerificationCancelation() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.sessionVerification)
        
        XCTAssert(app.buttons["requestVerificationButton"].exists)
        XCTAssert(app.buttons["closeButton"].exists)
        XCTAssert(app.staticTexts["titleLabel"].exists)
        
        app.buttons["requestVerificationButton"].tap()
        
        XCTAssert(app.activityIndicators["requestingVerificationProgressView"].waitForExistence(timeout: 1))
        
        XCTAssert(app.buttons["sasVerificationStartButton"].waitForExistence(timeout: 5.0))
        app.buttons["sasVerificationStartButton"].tap()
        
        XCTAssert(app.activityIndicators["startingSasVerification"].waitForExistence(timeout: 5.0))
        XCTAssert(app.activityIndicators["startedSasVerification"].waitForExistence(timeout: 5.0))
        
        app.buttons["closeButton"].tap()
        
        XCTAssert(app.images["sessionVerificationFailedIcon"].waitForExistence(timeout: 1))
        XCTAssert(app.buttons["restartButton"].exists)
        
        XCTAssert(app.buttons["closeButton"].exists)
        app.buttons["closeButton"].tap()
    }
}
