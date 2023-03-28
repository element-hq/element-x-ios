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

import XCTest

@MainActor
class OnboardingUITests: XCTestCase {
    func testInitialStateComponents() {
        let app = Application.launch(.onboarding)
        app.assertScreenshot(.onboarding)
    }
    
    // This test has been disabled for now as there is only a single page.
    func disabled_testSwipingBetweenPages() {
        let app = Application.launch(.onboarding)
        
        // Given the splash screen in its initial state.
        let page1TitleText = app.staticTexts[L10n.screenOnboardingWelcomeTitle]
        let page2TitleText = app.staticTexts[L10n.screenOnboardingWelcomeTitle] // There isn't a second string to match any more.
        let hiddenPageTitleText = app.staticTexts[A11yIdentifiers.onboardingScreen.hidden].firstMatch
        
        XCTAssertTrue(page1TitleText.isHittable, "The title from the first page of the carousel should be onscreen.")
        XCTAssertFalse(page2TitleText.isHittable, "The title from the second page of the carousel should be offscreen.")
        XCTAssertFalse(hiddenPageTitleText.isHittable, "The hidden page of the carousel should be offscreen.")
        
        // When swiping to the next screen.
        page1TitleText.swipeLeft(velocity: .fast)
        
        // Then the second screen should be shown.
        XCTAssertFalse(page1TitleText.isHittable, "The title from the first page of the carousel should be offscreen.")
        XCTAssertTrue(page2TitleText.isHittable, "The title from the second page of the carousel should be onscreen.")
        
        // When swiping back to the previous screen.
        page2TitleText.swipeRight(velocity: .fast)
        
        // Then the first screen should be shown again.
        XCTAssertTrue(page1TitleText.isHittable, "The title from the first page of the carousel should be onscreen.")
        XCTAssertFalse(page2TitleText.isHittable, "The title from the second page of the carousel should be offscreen.")
        
        // When swiping back to the previous screen.
        page1TitleText.swipeRight(velocity: .fast)
        
        // Then the screen shouldn't change and the hidden screen should be ignored.
        XCTAssertTrue(page1TitleText.isHittable, "The title from the first page of the carousel should be still be onscreen.")
        XCTAssertFalse(page2TitleText.isHittable, "The title from the second page of the carousel should be offscreen.")
        XCTAssertFalse(hiddenPageTitleText.isHittable, "It shouldn't be possible to swipe to the hidden page of the carousel.")
    }
}
