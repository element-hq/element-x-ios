//
//  LocalizationTests.swift
//  UnitTests
//
//  Created by Ismail on 19.04.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import XCTest
@testable import ElementX

class LocalizationTests: XCTestCase {

    /// Test ElementL10n considers app language changes
    func testAppLanguage() {
        //  set app language to English
        Bundle.elementLanguage = "en"

        XCTAssertEqual(ElementL10n.ok, "OK")
        XCTAssertEqual(ElementL10n.continue, "Continue")
        XCTAssertEqual(ElementL10n.loginSocialSignupWith("Github"), "Sign up with Github")

        //  set app language to Turkish
        Bundle.elementLanguage = "tr"

        XCTAssertEqual(ElementL10n.ok, "Tamam")
        XCTAssertEqual(ElementL10n.continue, "Devam et")
        XCTAssertEqual(ElementL10n.loginSocialSignupWith("Github"), "Github ile kayıt ol")
    }

    /// Test fallback language for a language not supported at all
    func testFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose 'Malay' language)
        Bundle.elementLanguage = "ms"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(ElementL10n.ok, "OK")
        XCTAssertEqual(ElementL10n.continue, "Continue")
        XCTAssertEqual(ElementL10n.Plurals.Entries.item1(5), "5 entries")
    }

    /// Test fallback language for a language supported but poorly translated
    func testFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but poorly translated (chose 'Sinhala' language)
        Bundle.elementLanguage = "si"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(ElementL10n.ok, "OK")
        XCTAssertEqual(ElementL10n.continue, "Continue")
        XCTAssertEqual(ElementL10n.Plurals.Entries.item1(5), "5 entries")
    }

}
