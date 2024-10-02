//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

class LocalizationTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        Bundle.overrideLocalizations = nil
    }

    /// Test ElementL10n considers app language changes
    func testAppLanguage() {
        // set app language to English
        Bundle.overrideLocalizations = ["en"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "en")

        // set app language to Italian
        Bundle.overrideLocalizations = ["it"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "it")
    }

    /// Test fallback language for a language not supported at all
    func testFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose non existing identifier)
        Bundle.overrideLocalizations = ["xx"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "en")
    }

    /// Test fallback language for a language supported but poorly translated
    func testFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but use a key that is not translated (we have a key that should never be translated)
        Bundle.overrideLocalizations = ["it"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "it")
        XCTAssertEqual(L10n.testUntranslatedDefaultLanguageIdentifier, "en")
    }

    /// Test plurals that ElementL10n considers app language changes
    func testPlurals() {
        //  set app language to English
        Bundle.overrideLocalizations = ["en"]

        XCTAssertEqual(L10n.commonMemberCount(1), "1 member")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 members")

        //  set app language to Italian
        Bundle.overrideLocalizations = ["it"]

        XCTAssertEqual(L10n.commonMemberCount(1), "1 membro")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 membri")

//        //  set app language to Polish
//        Bundle.overrideLocalizations = ["pl"]
//
//        XCTAssertEqual(L10n.commonMemberCount(1), "1 sekunda") //  one
//        XCTAssertEqual(L10n.commonMemberCount(2), "2 sekundy") //  few
//        XCTAssertEqual(L10n.commonMemberCount(3), "5 sekund") //  many, other
    }

    /// Test plurals fallback language for a language not supported at all
    func testPluralsFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all ("invalid identifier")
        Bundle.overrideLocalizations = ["xx"]

        XCTAssertEqual(L10n.commonMemberCount(1), "1 member")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 members")
    }

    /// Test untranslated strings
    func testUntranslated() {
        XCTAssertEqual(UntranslatedL10n.untranslated, "Untranslated")
        XCTAssertEqual(UntranslatedL10n.untranslatedPlural(1), "One untranslated item")
        XCTAssertEqual(UntranslatedL10n.untranslatedPlural(5), "5 untranslated items")
    }
}
