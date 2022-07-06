//
//  LocalizationTests.swift
//  UnitTests
//
//  Created by Ismail on 19.04.2022.
//  Copyright © 2022 Element. All rights reserved.
//

@testable import ElementX
import XCTest

class LocalizationTests: XCTestCase {
    /// Test ElementL10n considers app language changes
    func testAppLanguage() {
        //  set app language to English
        Bundle.elementLanguage = "en"

        XCTAssertEqual(ElementL10n.ok, "OK")
        XCTAssertEqual(ElementL10n.continue, "Continue")
        XCTAssertEqual(ElementL10n.loginSocialSignupWith("Github"), "Sign up with Github")
        XCTAssertEqual(ElementL10n.roomSettingsMentionAndKeywordOnly, "Mentions & Keywords only")
        XCTAssertEqual(ElementL10n.analyticsOptInListItem1, "We <b>don\'t</b> record or profile any account data")

        //  set app language to Turkish
        Bundle.elementLanguage = "tr"

        XCTAssertEqual(ElementL10n.ok, "Tamam")
        XCTAssertEqual(ElementL10n.continue, "Devam et")
        XCTAssertEqual(ElementL10n.loginSocialSignupWith("Github"), "Github ile kayıt ol")
        XCTAssertEqual(ElementL10n.roomSettingsMentionAndKeywordOnly, "Yalnızca Söz ve Anahtar Kelimeler")
        XCTAssertEqual(ElementL10n.analyticsOptInListItem1, "Herhangi bir hesap verisini <b>kaydetmiyoruz</b>")
    }

    /// Test fallback language for a language not supported at all
    func testFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose 'Malay' language)
        Bundle.elementLanguage = "ms"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(ElementL10n.ok, "OK")
        XCTAssertEqual(ElementL10n.continue, "Continue")
        XCTAssertEqual(ElementL10n.entries(5), "5 entries")
    }

    /// Test fallback language for a language supported but poorly translated
    func testFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but poorly translated (chose 'Sinhala' language)
        Bundle.elementLanguage = "si"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(ElementL10n.ok, "OK")
        XCTAssertEqual(ElementL10n.continue, "Continue")
    }

    /// Test plurals that ElementL10n considers app language changes
    func testPlurals() {
        //  set app language to English
        Bundle.elementLanguage = "en"

        XCTAssertEqual(ElementL10n.membershipChanges(1), "1 membership change")
        XCTAssertEqual(ElementL10n.membershipChanges(2), "2 membership changes")

        //  set app language to Turkish
        Bundle.elementLanguage = "tr"

        XCTAssertEqual(ElementL10n.membershipChanges(1), "1 üyelik değişikliği")
        XCTAssertEqual(ElementL10n.membershipChanges(2), "2 adet üyelik değişikliği")

        //  set app language to Polish
        Bundle.elementLanguage = "pl"

        XCTAssertEqual(ElementL10n.seconds(1), "1 sekunda") //  one
        XCTAssertEqual(ElementL10n.seconds(2), "2 sekundy") //  few
        XCTAssertEqual(ElementL10n.seconds(5), "5 sekund") //  many, other
    }

    /// Test plurals fallback language for a language not supported at all
    func testPluralsFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose 'Malay' language)
        Bundle.elementLanguage = "ms"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(ElementL10n.membershipChanges(1), "1 membership change")
        XCTAssertEqual(ElementL10n.membershipChanges(2), "2 membership changes")
    }

    /// Test plurals fallback language for a language supported but poorly translated
    func testPluralsFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but poorly translated (chose 'Sinhala' language)
        Bundle.elementLanguage = "si"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(ElementL10n.entries(1), "1 entry")
        XCTAssertEqual(ElementL10n.entries(5), "5 entries")
    }

    /// Test untranslated strings
    func testUntranslated() {
        XCTAssertEqual(ElementL10n.untranslated, "Untranslated")
        XCTAssertEqual(ElementL10n.untranslatedPlural(1), "One untranslated item")
        XCTAssertEqual(ElementL10n.untranslatedPlural(5), "5 untranslated items")
    }
}
