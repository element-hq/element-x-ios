//
// Copyright 2021 New Vector Ltd
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

import XCTest
import ElementX

class SessionVerificationUITests: XCTestCase {
    
    func testChallengeMatches() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.sessionVerification)
        
        XCTAssert(app.navigationBars["Verify this session"].exists)
        
        XCTAssert(app.buttons["startButton"].exists)
        XCTAssert(app.buttons["dismissButton"].exists)
        XCTAssert(app.staticTexts["titleLabel"].exists)
        
        app.buttons["startButton"].tap()
        
        XCTAssert(app.activityIndicators["requestingVerificationProgressView"].exists)
        XCTAssert(app.buttons["cancelButton"].exists)
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        XCTAssert(app.buttons["challengeDeclineButton"].waitForExistence(timeout: 5.0))
        XCTAssert(app.buttons["cancelButton"].waitForExistence(timeout: 5.0))
        
        app.buttons["challengeAcceptButton"].tap()
                  
        XCTAssert(app.activityIndicators["acceptingChallengeProgressView"].exists)
        XCTAssert(app.buttons["cancelButton"].exists)
        
        XCTAssert(app.images["sessionVerificationSucceededIcon"].waitForExistence(timeout: 5.0))
        
        XCTAssert(app.buttons["dismissButton"].exists)
        app.buttons["dismissButton"].tap()
    }
    
    func testChallengeDoesNotMatch() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.sessionVerification)
        
        XCTAssert(app.navigationBars["Verify this session"].exists)
        
        XCTAssert(app.buttons["startButton"].exists)
        XCTAssert(app.buttons["dismissButton"].exists)
        XCTAssert(app.staticTexts["titleLabel"].exists)
        
        app.buttons["startButton"].tap()
        
        XCTAssert(app.activityIndicators["requestingVerificationProgressView"].exists)
        XCTAssert(app.buttons["cancelButton"].exists)
        
        XCTAssert(app.buttons["challengeAcceptButton"].waitForExistence(timeout: 5.0))
        XCTAssert(app.buttons["challengeDeclineButton"].waitForExistence(timeout: 5.0))
        XCTAssert(app.buttons["cancelButton"].waitForExistence(timeout: 5.0))
        
        app.buttons["challengeDeclineButton"].tap()
                          
        XCTAssert(app.images["sessionVerificationFailedIcon"].exists)
        XCTAssert(app.buttons["restartButton"].exists)
        
        XCTAssert(app.buttons["dismissButton"].exists)
        app.buttons["dismissButton"].tap()
    }
    
    func testSessionVerificationCancelation() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.sessionVerification)
        
        XCTAssert(app.navigationBars["Verify this session"].exists)
        
        XCTAssert(app.buttons["startButton"].exists)
        XCTAssert(app.buttons["dismissButton"].exists)
        XCTAssert(app.staticTexts["titleLabel"].exists)
        
        app.buttons["startButton"].tap()
        
        XCTAssert(app.activityIndicators["requestingVerificationProgressView"].exists)
        XCTAssert(app.buttons["cancelButton"].exists)
        
        app.buttons["cancelButton"].tap()
        
        XCTAssert(app.images["sessionVerificationFailedIcon"].exists)
        XCTAssert(app.buttons["restartButton"].exists)
        
        XCTAssert(app.buttons["dismissButton"].exists)
        app.buttons["dismissButton"].tap()
    }
}
